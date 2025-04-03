import Foundation
import AudioToolbox

public actor SwiftAudioFileConverter {
    static public func convert(from inputURL: URL,
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
            // ExtAudioFile supports these.
            try await performExtAudioFileConversion(from: inputURL, to: outputURL, settings: settings)
            
        case .mp3:
            // Use Lame for mp3
            try await performLameConversion(from: inputURL, to: outputURL, settings: settings)
            
        case .flac:
            try await performFlacConversion(from: inputURL, to: outputURL, settings: settings)
        }
    }
}
