//
//  SwiftAudioFileConverter+FLAC.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import AudioToolbox
import FLAC
import Foundation

extension SwiftAudioFileConverter {
    @concurrent nonisolated static func performFlacConversion(
        from inputURL: URL,
        to outputURL: URL,
        settings: AudioFileSettings
    ) async throws {
        // 1) Open the input file with ExtAudioFile
        var inputFile: ExtAudioFileRef?
        var result = ExtAudioFileOpenURL(inputURL as CFURL, &inputFile)
        try checkError(result)
        guard let inputFile = inputFile else {
            throw SwiftAudioFileConverterError.unableToOpenFile(inputURL)
        }
        defer { ExtAudioFileDispose(inputFile) }

        // 2) Decide on channels from settings
        let channels = (settings.channelFormat == .mono) ? UInt32(1) : UInt32(2)

        // 3) We want 16-bit interleaved PCM from ExtAudioFile
        //    because FLAC expects integer samples
        var clientFormat = AudioStreamBasicDescription(
            mSampleRate: settings.sampleRate.rawValue,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeEndian
                | kLinearPCMFormatFlagIsPacked
                | kLinearPCMFormatFlagIsSignedInteger,
            mBytesPerPacket: 2 * channels, // 2 bytes per sample * # of channels
            mFramesPerPacket: 1,
            mBytesPerFrame: 2 * channels,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 16,
            mReserved: 0
        )

        // Set this client format
        result = ExtAudioFileSetProperty(
            inputFile,
            kExtAudioFileProperty_ClientDataFormat,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
            &clientFormat
        )
        try checkError(result)

        // 4) Create and configure the FLAC encoder
        guard let flacEncoder = FLAC__stream_encoder_new() else {
            throw SwiftAudioFileConverterError.unsupportedConversion(.flac)
        }
        defer { FLAC__stream_encoder_delete(flacEncoder) }

        // Set basic FLAC encoder properties
        // Sample rate, channels, bits per sample
        FLAC__stream_encoder_set_channels(flacEncoder, channels)
        FLAC__stream_encoder_set_sample_rate(flacEncoder, UInt32(settings.sampleRate.rawValue))
        FLAC__stream_encoder_set_bits_per_sample(flacEncoder, 16)

        // Optionally set a compression level (0 = fastest, 8 = slowest/best)
        FLAC__stream_encoder_set_compression_level(flacEncoder, 5)

        // 5) Initialize the encoder to write directly to outputURL
        let initStatus = outputURL.withUnsafeFileSystemRepresentation { pathCstr in
            FLAC__stream_encoder_init_file(flacEncoder, pathCstr, nil, nil)
        }
        if initStatus != FLAC__STREAM_ENCODER_INIT_STATUS_OK {
            throw SwiftAudioFileConverterError.unsupportedConversion(.flac)
        }

        // 6) Read PCM in chunks, pass to FLAC
        let kFramesPerChunk: UInt32 = 4096
        let bytesPerFrame = clientFormat.mBytesPerFrame // 2 * channels
        let bufferByteSize = kFramesPerChunk * bytesPerFrame

        // We'll allocate a chunk of memory for reading 16-bit samples
        let pcmBuffer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(kFramesPerChunk * channels))
        defer { pcmBuffer.deallocate() }

        while true {
            // 6a) Prepare AudioBufferList
            var bufferList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: channels,
                    mDataByteSize: bufferByteSize,
                    mData: pcmBuffer
                )
            )
            var framesRead = kFramesPerChunk

            // 6b) Read from ExtAudioFile
            result = ExtAudioFileRead(inputFile, &framesRead, &bufferList)
            try checkError(result)

            if framesRead == 0 {
                // No more frames
                break
            }

            // 6c) Convert frames to FLAC. Because we used interleaved 16-bit PCM,
            //     we can directly pass the pointer to FLAC’s process_interleaved.

            let ok = withUnsafePointer(to: pcmBuffer) { ptr in
                // FLAC__stream_encoder_process_interleaved expects a pointer to Int32 buffers
                // but actually we can pass 16-bit if we cast. We'll do a little trick:
                // We'll cast our Int16 pointer to int[] in FLAC's perspective.

                // Actually, FLAC’s process_interleaved signature is:
                //   FLAC__bool FLAC__stream_encoder_process_interleaved(
                //       FLAC__StreamEncoder *encoder,
                //       const FLAC__int32 pcm[],
                //       size_t samples
                //   );
                //
                // So we must convert from Int16 to Int32 or pass upcasted data.
                // A quick approach: convert each frame to 32-bit on the fly.
                // We'll do that to avoid confusion:

                var int32Buffer = [Int32](repeating: 0, count: Int(framesRead * channels))
                for i in 0 ..< (Int(framesRead * channels)) {
                    int32Buffer[i] = Int32(pcmBuffer[i])
                }

                return int32Buffer.withUnsafeBufferPointer { bp -> FLAC__bool in
                    FLAC__stream_encoder_process_interleaved(
                        flacEncoder,
                        bp.baseAddress,  // pointer to the 32-bit array
                        FLAC__uint32(framesRead)
                    )
                }
            }

            if ok == 0  {
                throw SwiftAudioFileConverterError.flacConversionUnknownError
            }
        }

        // 7) Finish/flush the encoder
        let finishOK = FLAC__stream_encoder_finish(flacEncoder)
        if finishOK == 0 {
            throw SwiftAudioFileConverterError.flacConversionUnknownError
        }

        // 8) The output FLAC file now exists at outputURL
    }
}
