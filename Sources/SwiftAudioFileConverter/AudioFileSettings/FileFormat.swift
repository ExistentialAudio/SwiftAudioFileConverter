//
//  FileFormat.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

public enum FileFormat: String {
    case aac
    case mp3
    case wav
    case aiff
    case flac
    case alac = "m4a"
}

extension FileFormat: Equatable { }

extension FileFormat: Hashable { }

extension FileFormat: Sendable { }

extension FileFormat: CaseIterable { }
