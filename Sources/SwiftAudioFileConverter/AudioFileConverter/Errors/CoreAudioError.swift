//
//  CoreAudioError.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation
import AudioToolbox

extension AudioFileConverter {
    public enum CoreAudioError: Error {
        case formatNotSupported
        case unspecified
        case unsupportedProperty
        case badPropertySize
        case badSpecifierSize
        case unknownFormat
        case unknownError(OSStatus)
        
        public init(status: OSStatus) {
            switch status {
            case kAudioFormatUnsupportedDataFormatError:
                self = .formatNotSupported
            case kAudioFormatUnspecifiedError:
                self = .unspecified
            case kAudioFormatUnsupportedPropertyError:
                self = .unsupportedProperty
            case kAudioFormatBadPropertySizeError:
                self = .badPropertySize
            case kAudioFormatBadSpecifierSizeError:
                self = .badSpecifierSize
            case kAudioFormatUnknownFormatError:
                self = .unknownFormat
            default:
                self = .unknownError(status)
            }
        }
    }
}

extension AudioFileConverter.CoreAudioError: Equatable { }

extension AudioFileConverter.CoreAudioError: Hashable { }

extension AudioFileConverter.CoreAudioError: Sendable { }

extension AudioFileConverter.CoreAudioError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .formatNotSupported:
            "Format not supported."
        case .unspecified:
            "Unspecified error."
        case .unsupportedProperty:
            "Unsupported property."
        case .badPropertySize:
            "Bad property size."
        case .badSpecifierSize:
            "Bad specifier size."
        case .unknownFormat:
            "Unknown format."
        case let .unknownError(osStatus):
            "Unknown error (OSStatus \(osStatus))"
        }
    }
}
