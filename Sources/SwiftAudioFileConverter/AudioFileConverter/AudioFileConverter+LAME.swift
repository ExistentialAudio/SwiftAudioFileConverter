//
//  AudioFileConverter+LAME.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import AudioToolbox
import Foundation
import Darwin

private enum LameLoaderError: Error, LocalizedError {
    case failedToOpenLibrary(URL)
    case missingSymbol(String)

    var errorDescription: String? {
        switch self {
        case .failedToOpenLibrary(let url):
            if let error = dlerror() {
                return "Failed to open LAME library at \(url.path): \(String(cString: error))"
            } else {
                return "Failed to open LAME library at \(url.path)"
            }

        case .missingSymbol(let symbol):
            if let error = dlerror() {
                return "Missing LAME symbol \(symbol): \(String(cString: error))"
            } else {
                return "Missing LAME symbol \(symbol)"
            }
        }
    }
}

private final class LameLibrary {
    typealias lame_t = OpaquePointer

    typealias lame_init_t = @convention(c) () -> lame_t?
    typealias lame_close_t = @convention(c) (lame_t?) -> Int32
    typealias lame_set_num_channels_t = @convention(c) (lame_t?, Int32) -> Int32
    typealias lame_set_in_samplerate_t = @convention(c) (lame_t?, Int32) -> Int32
    typealias lame_set_brate_t = @convention(c) (lame_t?, Int32) -> Int32
    typealias lame_set_quality_t = @convention(c) (lame_t?, Int32) -> Int32
    typealias lame_init_params_t = @convention(c) (lame_t?) -> Int32
    typealias lame_encode_buffer_ieee_float_t = @convention(c) (
        lame_t?,
        UnsafePointer<Float>?,
        UnsafePointer<Float>?,
        Int32,
        UnsafeMutablePointer<UInt8>?,
        Int32
    ) -> Int32
    typealias lame_encode_flush_t = @convention(c) (
        lame_t?,
        UnsafeMutablePointer<UInt8>?,
        Int32
    ) -> Int32

    let handle: UnsafeMutableRawPointer

    let lame_init: lame_init_t
    let lame_close: lame_close_t
    let lame_set_num_channels: lame_set_num_channels_t
    let lame_set_in_samplerate: lame_set_in_samplerate_t
    let lame_set_brate: lame_set_brate_t
    let lame_set_quality: lame_set_quality_t
    let lame_init_params: lame_init_params_t
    let lame_encode_buffer_ieee_float: lame_encode_buffer_ieee_float_t
    let lame_encode_flush: lame_encode_flush_t

    init(url: URL) throws {
        guard url.isFileURL else {
            throw LameLoaderError.failedToOpenLibrary(url)
        }

        guard let handle = dlopen(url.path, RTLD_NOW | RTLD_LOCAL) else {
            throw LameLoaderError.failedToOpenLibrary(url)
        }

        self.handle = handle

        func loadSymbol<T>(_ name: String, as type: T.Type) throws -> T {
            dlerror()

            guard let symbol = dlsym(handle, name) else {
                throw LameLoaderError.missingSymbol(name)
            }

            return unsafeBitCast(symbol, to: T.self)
        }

        do {
            self.lame_init = try loadSymbol("lame_init", as: lame_init_t.self)
            self.lame_close = try loadSymbol("lame_close", as: lame_close_t.self)
            self.lame_set_num_channels = try loadSymbol("lame_set_num_channels", as: lame_set_num_channels_t.self)
            self.lame_set_in_samplerate = try loadSymbol("lame_set_in_samplerate", as: lame_set_in_samplerate_t.self)
            self.lame_set_brate = try loadSymbol("lame_set_brate", as: lame_set_brate_t.self)
            self.lame_set_quality = try loadSymbol("lame_set_quality", as: lame_set_quality_t.self)
            self.lame_init_params = try loadSymbol("lame_init_params", as: lame_init_params_t.self)
            self.lame_encode_buffer_ieee_float = try loadSymbol("lame_encode_buffer_ieee_float", as: lame_encode_buffer_ieee_float_t.self)
            self.lame_encode_flush = try loadSymbol("lame_encode_flush", as: lame_encode_flush_t.self)
        } catch {
            dlclose(handle)
            throw error
        }
    }

    deinit {
        dlclose(handle)
    }
}

extension AudioFileConverter {
    @concurrent nonisolated static func performLameConversion(
        from inputURL: URL,
        to outputURL: URL,
        settings: Settings,
        lameLibraryURL: URL?
    ) async throws {
        
        guard let lameLibraryURL else { throw ConverterError.invalidLamePath }
        
        let lameLibrary = try LameLibrary(url: lameLibraryURL)

        var inputFile: ExtAudioFileRef?
        var result = ExtAudioFileOpenURL(inputURL as CFURL, &inputFile)
        try checkError(result)
        guard let inputFile else {
            throw ConverterError.unableToOpenFile(inputURL)
        }
        defer {
            ExtAudioFileDispose(inputFile)
        }

        let channels = UInt32(settings.channelFormat.channelCount)

        var clientFormat = AudioStreamBasicDescription(
            mSampleRate: settings.sampleRate.hzDouble,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsFloat
                | kAudioFormatFlagsNativeEndian
                | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 4 * channels,
            mFramesPerPacket: 1,
            mBytesPerFrame: 4 * channels,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 32,
            mReserved: 0
        )

        result = ExtAudioFileSetProperty(
            inputFile,
            kExtAudioFileProperty_ClientDataFormat,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
            &clientFormat
        )
        try checkError(result)

        guard let lame = lameLibrary.lame_init() else {
            throw ConverterError.unsupportedConversion(.mp3)
        }
        defer {
            _ = lameLibrary.lame_close(lame)
        }

        _ = lameLibrary.lame_set_num_channels(lame, Int32(channels))
        _ = lameLibrary.lame_set_in_samplerate(lame, Int32(settings.sampleRate.hzInt))
        _ = lameLibrary.lame_set_brate(lame, 128)
        _ = lameLibrary.lame_set_quality(lame, 2)

        if lameLibrary.lame_init_params(lame) < 0 {
            throw ConverterError.unsupportedConversion(.mp3)
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        guard fileManager.createFile(atPath: outputURL.path, contents: nil) else {
            throw ConverterError.fileIsNotWritable(outputURL)
        }
        guard let fileHandle = FileHandle(forWritingAtPath: outputURL.path) else {
            throw ConverterError.fileIsNotWritable(outputURL)
        }
        defer {
            try? fileHandle.close()
        }

        let kFramesPerChunk: UInt32 = 4096
        let bytesPerFrame = clientFormat.mBytesPerFrame
        let bufferByteSize = kFramesPerChunk * bytesPerFrame

        let floatBuffer = UnsafeMutablePointer<Float>.allocate(capacity: Int(kFramesPerChunk * channels))
        defer {
            floatBuffer.deallocate()
        }

        let maxMP3Bytes = Int(Double(bufferByteSize) * 1.25) + 7200
        let mp3Buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxMP3Bytes)
        defer {
            mp3Buffer.deallocate()
        }

        var leftBuffer = [Float](repeating: 0, count: Int(kFramesPerChunk))
        var rightBuffer = [Float](repeating: 0, count: Int(kFramesPerChunk))

        while true {
            var bufferList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: channels,
                    mDataByteSize: bufferByteSize,
                    mData: floatBuffer
                )
            )

            var framesRead = kFramesPerChunk

            result = ExtAudioFileRead(inputFile, &framesRead, &bufferList)
            try checkError(result)

            if framesRead == 0 {
                break
            }

            let samplesPerChannel = Int(framesRead)
            let encodedBytes: Int32

            if channels == 2 {
                for i in 0 ..< samplesPerChannel {
                    leftBuffer[i] = floatBuffer[2 * i]
                    rightBuffer[i] = floatBuffer[2 * i + 1]
                }

                encodedBytes = leftBuffer.withUnsafeBufferPointer { leftPointer in
                    rightBuffer.withUnsafeBufferPointer { rightPointer in
                        lameLibrary.lame_encode_buffer_ieee_float(
                            lame,
                            leftPointer.baseAddress,
                            rightPointer.baseAddress,
                            Int32(samplesPerChannel),
                            mp3Buffer,
                            Int32(maxMP3Bytes)
                        )
                    }
                }
            } else {
                encodedBytes = lameLibrary.lame_encode_buffer_ieee_float(
                    lame,
                    UnsafePointer(floatBuffer),
                    nil,
                    Int32(samplesPerChannel),
                    mp3Buffer,
                    Int32(maxMP3Bytes)
                )
            }

            if encodedBytes < 0 {
                throw ConverterError.unsupportedConversion(.mp3)
            }

            let data = Data(bytes: mp3Buffer, count: Int(encodedBytes))
            try fileHandle.write(contentsOf: data)
        }

        let flushBytes = lameLibrary.lame_encode_flush(lame, mp3Buffer, Int32(maxMP3Bytes))
        if flushBytes < 0 {
            throw ConverterError.unsupportedConversion(.mp3)
        }

        if flushBytes > 0 {
            let data = Data(bytes: mp3Buffer, count: Int(flushBytes))
            try fileHandle.write(contentsOf: data)
        }
    }
}
