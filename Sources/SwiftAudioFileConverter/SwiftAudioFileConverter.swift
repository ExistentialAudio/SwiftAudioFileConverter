import Foundation
import AudioToolbox

actor SwiftAudioFileConverter {
    
    static func convert(from inputURL: URL,
                        to outputURL: URL,
                        with settings: AudioFileSettings) async throws {
        
        // 1. Check if the input file extension is a known audio format
        guard FileFormat.allCases.map(\.rawValue).contains(inputURL.pathExtension.lowercased()) else {
            throw SwiftAudioFileConverterError.unsupportedAudioFileExtension(inputURL)
        }
        
        // 2. If the file exists
        guard FileManager.default.fileExists(atPath: inputURL.path()) else {
            throw SwiftAudioFileConverterError.fileDoesNotExist(inputURL)
        }
        
        // 3. Check read permissions on the input file
        guard FileManager.default.isReadableFile(atPath: inputURL.path) else {
            throw SwiftAudioFileConverterError.fileIsNotReadable(inputURL)
        }
        
        // 4. Check write permissions on the output (directory must be writable)
        //    NOTE: For a brand new file, isWritableFile(atPath:) can be misleading.
        //    Often, you'll want to check if the directory is writable instead.
        let outputDirectory = outputURL.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: outputDirectory.path) else {
            throw SwiftAudioFileConverterError.fileIsNotWritable(outputURL)
        }
        
        // 5. Check if output extension matches settings.fileFormat
        guard outputURL.pathExtension.lowercased() == settings.fileFormat.rawValue else {
            throw SwiftAudioFileConverterError.audioFileExtensionSettingsMismatch(outputURL, settings)
        }
        
        // 6. Dispatch the conversion based on the requested format
        switch settings.fileFormat {
            
        case .wav, .aiff, .aac, .alac:
            // AudioToolbox typically supports these.
            try await performAudioToolboxConversion(from: inputURL, to: outputURL, settings: settings)
            
        case .mp3, .flac:
            // AudioToolbox does not reliably support encoding these on all platforms.
            // You may need a custom or third-party solution (e.g., LAME for MP3, etc.)
            throw SwiftAudioFileConverterError.unsupportedConversion(settings.fileFormat)
        }
    }
    
    // MARK: - Core conversion using AudioToolbox
    
    private static func performAudioToolboxConversion(from inputURL: URL,
                                                      to outputURL: URL,
                                                      settings: AudioFileSettings) async throws {
        
        // 1. Open the input file
        var inputFile: ExtAudioFileRef?
        var result = ExtAudioFileOpenURL(inputURL as CFURL, &inputFile)
        try checkError(result)
        guard let inputFile = inputFile else {
            throw SwiftAudioFileConverterError.unableToOpenFile(inputURL)
        }
        
        // 2. Prepare an AudioStreamBasicDescription for the *destination* format
        var (destinationFormat, destinationFileType) = try audioFormat(for: settings)
        
        // 3. Create the output file
        var outputFile: ExtAudioFileRef?
        result = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            destinationFileType,
            &destinationFormat,
            /* AudioChannelLayout? */ nil,
            AudioFileFlags.eraseFile.rawValue,
            &outputFile
        )
        print(destinationFormat)
        print(destinationFileType)
        
        try checkError(result)
        guard let outputFile = outputFile else {
            throw SwiftAudioFileConverterError.unableToOpenFile(outputURL)
        }
        
        // 4. We’ll set a “client format” to read and write in a consistent format (e.g., float32 PCM).
        //    Even for compressed output like AAC, we often use a PCM client format for reading/writing.
        let channels = (settings.channelFormat == .mono) ? UInt32(1) : UInt32(2)
        
        var clientFormat = AudioStreamBasicDescription(
            mSampleRate: settings.sampleRate.rawValue,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsFloat
                         | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 4 * channels,
            mFramesPerPacket: 1,
            mBytesPerFrame: 4 * channels,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 32,
            mReserved: 0
        )
        
        // Apply to input and output ExtAudioFile
        result = ExtAudioFileSetProperty(inputFile,
                                         kExtAudioFileProperty_ClientDataFormat,
                                         UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                                         &clientFormat)
        try checkError(result)
        
        result = ExtAudioFileSetProperty(outputFile,
                                         kExtAudioFileProperty_ClientDataFormat,
                                         UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                                         &clientFormat)
        try checkError(result)
        
        // 5. Perform the read/write loop
        let bufferByteSize: UInt32 = 32_768
        let frameCount = bufferByteSize / clientFormat.mBytesPerFrame
        
        // Allocate a buffer to hold our audio data
        let buffer = UnsafeMutablePointer<Float>.allocate(capacity: Int(frameCount * channels))
        defer { buffer.deallocate() }
        
        var ioFrames = frameCount
        
        while ioFrames > 0 {
            var bufferList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: channels,
                    mDataByteSize: 0,
                    mData: buffer
                )
            )
            // Tell ExtAudioFile how many frames we have space for
            ioFrames = frameCount
            bufferList.mBuffers.mDataByteSize = ioFrames * clientFormat.mBytesPerFrame
            
            // Read from the input file
            result = ExtAudioFileRead(inputFile, &ioFrames, &bufferList)
            try checkError(result)
            
            // If no frames were read, we are done
            if ioFrames == 0 { break }
            
            // Write the frames to the output file
            result = ExtAudioFileWrite(outputFile, ioFrames, &bufferList)
            try checkError(result)
        }
        
        // 6. Close both files
        ExtAudioFileDispose(inputFile)
        ExtAudioFileDispose(outputFile)
    }
    
    // MARK: - Helpers
    
    /// Returns a tuple of (destination AudioStreamBasicDescription, destination AudioFileTypeID)
    /// based on the user’s desired FileFormat in `AudioFileSettings`.
    private static func audioFormat(for settings: AudioFileSettings) throws
    -> (AudioStreamBasicDescription, AudioFileTypeID) {
        
        let channels = (settings.channelFormat == .mono) ? UInt32(1) : UInt32(2)
        
        // Base description; we’ll adjust for each format
        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = settings.sampleRate.rawValue
        asbd.mChannelsPerFrame = channels
        
        switch settings.fileFormat {
        case .wav:
            // WAV -> Linear PCM
            asbd.mFormatID = kAudioFormatLinearPCM
            asbd.mFormatFlags = linearPCMFlags(for: settings.bitDepth)
            asbd.mFramesPerPacket = 1
            asbd.mBitsPerChannel = bitDepthBits(settings.bitDepth)
            asbd.mChannelsPerFrame = channels
            asbd.mBytesPerFrame = (asbd.mBitsPerChannel / 8) * channels
            asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket
            return (asbd, kAudioFileWAVEType)
            
        case .aiff:
            // AIFF -> Linear PCM
            asbd.mFormatID = kAudioFormatLinearPCM
            asbd.mFormatFlags = linearPCMFlags(for: settings.bitDepth) | kAudioFormatFlagIsBigEndian
            asbd.mFramesPerPacket = 1
            asbd.mBitsPerChannel = bitDepthBits(settings.bitDepth)
            asbd.mChannelsPerFrame = channels
            asbd.mBytesPerFrame = (asbd.mBitsPerChannel / 8) * channels
            asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket
            return (asbd, kAudioFileAIFCType)
            
        case .aac:
            // AAC in an M4A container
            asbd.mFormatID = kAudioFormatMPEG4AAC
            // The rest of the fields will be set by the encoder internally
            return (asbd, kAudioFileM4AType)
            
        case .alac:
            // Apple Lossless
            asbd.mFormatID = kAudioFormatAppleLossless
            // The rest of the fields will be set by the encoder internally
            return (asbd, kAudioFileM4AType)
            
        case .mp3, .flac:
            // We should never get here, because we throw for unsupported
            throw SwiftAudioFileConverterError.unsupportedConversion(settings.fileFormat)
        }
    }
    
    /// Sets the correct flags for linear PCM based on requested bit depth.
    private static func linearPCMFlags(for bitDepth: BitDepth) -> UInt32 {
        // Common flags for linear PCM
        var flags: UInt32 = kLinearPCMFormatFlagIsPacked
        switch bitDepth {
        case .int16, .int24:
            flags |= kLinearPCMFormatFlagIsSignedInteger
        case .float32:
            flags |= kLinearPCMFormatFlagIsFloat
        }
        return flags
    }
    
    /// Returns the bit depth in bits (e.g. 16, 24, 32) for the enum
    private static func bitDepthBits(_ bitDepth: BitDepth) -> UInt32 {
        switch bitDepth {
        case .int16:
            return 16
        case .int24:
            // 24-bit is often stored in a 32-bit container, but here we use 24 directly
            return 24
        case .float32:
            return 32
        }
    }
    
    /// Throws a Swift error if the OSStatus indicates failure.
    private static func checkError(_ status: OSStatus) throws {
        guard status == noErr else {
            throw SwiftAudioFileConverterError.coreAudioError(CoreAudioError(status: status))
        }
    }
}
