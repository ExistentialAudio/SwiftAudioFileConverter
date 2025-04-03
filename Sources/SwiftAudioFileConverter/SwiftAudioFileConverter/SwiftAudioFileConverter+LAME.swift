//
//  SwiftAudioFileConverter+LAME.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation
import lame

extension SwiftAudioFileConverter {
    
    static func performLameConversion(
        from inputURL: URL,
        to outputURL: URL,
        settings: AudioFileSettings
    ) async throws {
        throw SwiftAudioFileConverterError.unsupportedConversion(settings.fileFormat)
    }
}
