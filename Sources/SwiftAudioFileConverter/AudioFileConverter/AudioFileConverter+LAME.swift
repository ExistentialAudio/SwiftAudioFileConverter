//
//  AudioFileConverter+LAME.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import AudioToolbox
import Foundation
import lame

extension AudioFileConverter {
    @concurrent nonisolated static func performLameConversion(
        from inputURL: URL,
        to outputURL: URL,
        settings: AudioFileSettings
    ) async throws {
        // 1) Open the input file using ExtAudioFile
        var inputFile: ExtAudioFileRef?
        var result = ExtAudioFileOpenURL(inputURL as CFURL, &inputFile)
        try checkError(result)
        guard let inputFile = inputFile else {
            throw SwiftAudioFileConverterError.unableToOpenFile(inputURL)
        }
        defer {
            ExtAudioFileDispose(inputFile)
        }

        // 2) Determine the number of channels from AudioFileSettings
        let channels = (settings.channelFormat == .mono) ? UInt32(1) : UInt32(2)

        // 3) We want 32-bit float interleaved PCM for reading from ExtAudioFile
        //    Build a client format describing float PCM.
        var clientFormat = AudioStreamBasicDescription(
            mSampleRate: settings.sampleRate.rawValue,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsFloat
                | kAudioFormatFlagsNativeEndian
                | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 4 * channels, // 4 bytes per sample * N channels
            mFramesPerPacket: 1,
            mBytesPerFrame: 4 * channels,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 32,
            mReserved: 0
        )

        // Apply that client format to the ExtAudioFile
        result = ExtAudioFileSetProperty(
            inputFile,
            kExtAudioFileProperty_ClientDataFormat,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
            &clientFormat
        )
        try checkError(result)

        // 4) Prepare LAME for float input
        guard let lame = lame_init() else {
            throw SwiftAudioFileConverterError.unsupportedConversion(.mp3)
        }
        lame_set_num_channels(lame, Int32(channels))
        lame_set_in_samplerate(lame, Int32(settings.sampleRate.rawValue))

        // Example settings:
        lame_set_brate(lame, 128) // 128 kbps
        lame_set_quality(lame, 2) // quality scale: 0=best, 9=worst

        if lame_init_params(lame) < 0 {
            lame_close(lame)
            throw SwiftAudioFileConverterError.unsupportedConversion(.mp3)
        }
        defer { lame_close(lame) }

        // 5) Create a file for the output .mp3
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        guard fileManager.createFile(atPath: outputURL.path, contents: nil) else {
            throw SwiftAudioFileConverterError.fileIsNotWritable(outputURL)
        }
        guard let fileHandle = FileHandle(forWritingAtPath: outputURL.path) else {
            throw SwiftAudioFileConverterError.fileIsNotWritable(outputURL)
        }
        defer { try? fileHandle.close() }

        // 6) Set up a loop to read Float32 PCM and encode to MP3 in chunks
        let kFramesPerChunk: UInt32 = 4096
        let bytesPerFrame = clientFormat.mBytesPerFrame
        let bufferByteSize = kFramesPerChunk * bytesPerFrame

        // Allocate a buffer for reading Float32 interleaved
        let floatBuffer = UnsafeMutablePointer<Float>.allocate(capacity: Int(kFramesPerChunk * channels))
        defer { floatBuffer.deallocate() }

        // Prepare an MP3 output buffer (worst-case 1.25x + 7200)
        let maxMP3Bytes = Int(Double(bufferByteSize) * 1.25) + 7200
        let mp3Buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxMP3Bytes)
        defer { mp3Buffer.deallocate() }

        // If stereo, we need separate left & right arrays for LAME’s float API
        // If mono, we’ll just pass floatBuffer as left + nil as right.
        var leftBuffer  = [Float](repeating: 0, count: Int(kFramesPerChunk))
        var rightBuffer = [Float](repeating: 0, count: Int(kFramesPerChunk))

        while true {
            // 6a) Prepare an AudioBufferList to read from ExtAudioFile
            var bufferList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: channels,
                    mDataByteSize: bufferByteSize,
                    mData: floatBuffer
                )
            )
            var framesRead = kFramesPerChunk

            // 6b) Read audio from input file into floatBuffer
            result = ExtAudioFileRead(inputFile, &framesRead, &bufferList)
            try checkError(result)

            if framesRead == 0 {
                // End of file
                break
            }

            // 6c) Encode these float PCM samples to MP3 using LAME’s float API
            let samplesPerChannel = Int(framesRead)

            let encodedBytes: Int32

            if channels == 2 {
                // De-interleave floatBuffer into leftBuffer and rightBuffer
                for i in 0 ..< samplesPerChannel {
                    leftBuffer[i]  = floatBuffer[2 * i]     // left sample
                    rightBuffer[i] = floatBuffer[2 * i + 1] // right sample
                }
                encodedBytes = lame_encode_buffer_ieee_float(
                    lame,
                    &leftBuffer,
                    &rightBuffer,
                    Int32(samplesPerChannel),
                    mp3Buffer,
                    Int32(maxMP3Bytes)
                )
            } else {
                // Mono: pass buffer as left, nil as right
                encodedBytes = lame_encode_buffer_ieee_float(
                    lame,
                    floatBuffer,
                    nil,
                    Int32(samplesPerChannel),
                    mp3Buffer,
                    Int32(maxMP3Bytes)
                )
            }

            if encodedBytes < 0 {
                throw SwiftAudioFileConverterError.unsupportedConversion(.mp3)
            }

            // 6d) Write the MP3 bytes to the output file
            let data = Data(bytes: mp3Buffer, count: Int(encodedBytes))
            try fileHandle.write(contentsOf: data)
        }

        // 7) Flush any remaining MP3 frames
        let flushBytes = lame_encode_flush(lame, mp3Buffer, Int32(maxMP3Bytes))
        if flushBytes > 0 {
            let data = Data(bytes: mp3Buffer, count: Int(flushBytes))
            try fileHandle.write(contentsOf: data)
        }

        // 8) Done! The output file at `outputURL` should be a valid MP3
    }
}
