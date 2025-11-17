//
//  FileFormat.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

extension AudioFileConverter {
    public enum FileFormat: String {
        case aac
        case mp3
        case wav
        case aiff
        case flac
        case alac = "m4a"
    }
}

extension AudioFileConverter.FileFormat: Equatable { }

extension AudioFileConverter.FileFormat: Hashable { }

extension AudioFileConverter.FileFormat: Sendable { }

extension AudioFileConverter.FileFormat: CaseIterable { }

extension AudioFileConverter.FileFormat: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
