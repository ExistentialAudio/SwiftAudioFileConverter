//
//  BitDepth.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

public enum BitDepth {
    case int16
    case int24
    case float32
}

extension BitDepth: Equatable { }

extension BitDepth: Hashable { }

extension BitDepth: Sendable { }

extension BitDepth: CaseIterable { }

extension BitDepth: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int16:
            "16-bit Int"
        case .int24:
            "24-bit Int"
        case .float32:
            "32-bit Float"
        }
    }
}
