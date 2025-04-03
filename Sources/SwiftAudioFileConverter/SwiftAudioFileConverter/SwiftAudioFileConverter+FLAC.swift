//
//  SwiftAudioFileConverter+FLAC.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//
import Foundation

extension SwiftAudioFileConverter {
    
    static func performFlacConversion(
        from inputURL: URL,
        to outputURL: URL,
        settings: AudioFileSettings
    ) async throws {
        throw SwiftAudioFileConverterError.unsupportedConversion(settings.fileFormat)
    }
}
