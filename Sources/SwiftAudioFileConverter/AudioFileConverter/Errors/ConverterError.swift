//
//  ConverterError.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

extension AudioFileConverter {
    public enum ConverterError: Error {
        case invalidAudioFileSettings(Settings)
        case unsupportedAudioFileExtension(URL)
        case audioFileExtensionSettingsMismatch(URL, Settings)
        case fileDoesNotExist(URL)
        case fileIsNotReadable(URL)
        case unableToOpenFile(URL)
        case fileIsNotWritable(URL)
        case unsupportedConversion(FileFormat)
        case coreAudioError(CoreAudioError)
        case flacConversionUnknownError
    }
}

extension AudioFileConverter.ConverterError: Equatable { }

extension AudioFileConverter.ConverterError: Hashable { }

extension AudioFileConverter.ConverterError: Sendable { }

extension AudioFileConverter.ConverterError: LocalizedError {
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
