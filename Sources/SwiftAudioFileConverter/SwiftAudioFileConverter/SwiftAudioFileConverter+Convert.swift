//
//  SwiftAudioFileConverter+Convert.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

extension SwiftAudioFileConverter {
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
            // AudioToolbox typically supports these.
            try await performAudioToolboxConversion(from: inputURL, to: outputURL, settings: settings)
            
        case .mp3, .flac:
            // AudioToolbox does not reliably support encoding these on all platforms.
            // You may need a custom or third-party solution (e.g., LAME for MP3, etc.)
            throw SwiftAudioFileConverterError.unsupportedConversion(settings.fileFormat)
        }
    }
    
}
