//
//  SwiftAudioFileConverterError.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

public enum SwiftAudioFileConverterError: LocalizedError {
    case invalidAudioFileSettings(AudioFileSettings)
    case unsupportedAudioFileExtension(URL)
    case audioFileExtensionSettingsMismatch(URL, AudioFileSettings)
    case fileDoesNotExist(URL)
    case fileIsNotReadable(URL)
    case unableToOpenFile(URL)
    case fileIsNotWritable(URL)
    case unsupportedConversion(FileFormat)
    case coreAudioError(CoreAudioError)
    case flacConversionUnknownError
}

extension SwiftAudioFileConverterError: Equatable { }

extension SwiftAudioFileConverterError: Hashable { }

extension SwiftAudioFileConverterError: Sendable { }

extension SwiftAudioFileConverterError {
    public var errorDescription: String? {
        switch self {
        case let .invalidAudioFileSettings(audioFileSettings):
            "Invalid audio file settings. \(audioFileSettings)"
        case let .unsupportedAudioFileExtension(url):
            "Unsupported audio file extension (\(url.path))"
        case let .audioFileExtensionSettingsMismatch(url, audioFileSettings):
            "Audio file extension settings mismatch. (\(url.path)) \(audioFileSettings)"
        case let .fileDoesNotExist(url):
            "File does not exist. (\(url.path))"
        case let .fileIsNotReadable(url):
            "File is not readable. (\(url.path))"
        case let .unableToOpenFile(url):
            "Unable to open file. (\(url.path))"
        case let .fileIsNotWritable(url):
            "File is not writable. (\(url.path))"
        case let .unsupportedConversion(fileFormat):
            "Unsupported conversion: \(fileFormat)"
        case let .coreAudioError(coreAudioError):
            "Core Audio error: \(coreAudioError)"
        case .flacConversionUnknownError:
            "Unknown FLAC conversion error."
        }
    }
}
