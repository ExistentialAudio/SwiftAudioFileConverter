//
//  SwiftAudioFileConverterError.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//
import Foundation

public enum SwiftAudioFileConverterError: Error {
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
