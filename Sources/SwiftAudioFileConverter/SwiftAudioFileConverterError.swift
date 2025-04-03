//
//  SwiftAudioFileConverterError.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//
import Foundation
import AudioToolbox

enum SwiftAudioFileConverterError: Error {
    case invalidAudioFileSettings(AudioFileSettings)
    case unsupportedAudioFileExtension(URL)
    case audioFileExtensionSettingsMismatch(URL, AudioFileSettings)
    case fileDoesNotExist(URL)
    case fileIsNotReadable(URL)
    case unableToOpenFile(URL)
    case fileIsNotWritable(URL)
    case unsupportedConversion(FileFormat)
    case coreAudioError(CoreAudioError)
}

enum CoreAudioError {
    case formatNotSupported
    case unspecified
    case unsupportedProperty
    case badPropertySize
    case badSpecifierSize
    case unknownFormat
    case unknownError(OSStatus)
    
    init(status: OSStatus) {
        
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
