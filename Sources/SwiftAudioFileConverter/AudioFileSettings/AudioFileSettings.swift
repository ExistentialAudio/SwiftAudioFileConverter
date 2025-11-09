//
//  AudioFileSettings.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

public struct AudioFileSettings {
    public let sampleRate: SampleRate
    public let bitDepth: BitDepth
    public let fileFormat: FileFormat
    public let channelFormat: ChannelFormat
    
    public init(sampleRate: SampleRate, bitDepth: BitDepth, fileFormat: FileFormat, channelFormat: ChannelFormat) throws {
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.fileFormat = fileFormat
        self.channelFormat = channelFormat
        
        if !isPCM, bitDepth != .float32 {
            throw SwiftAudioFileConverterError.invalidAudioFileSettings(self)
        }
    }
}

extension AudioFileSettings: Equatable { }

extension AudioFileSettings: Hashable { }

extension AudioFileSettings: Sendable { }

// MARK: - Properties

extension AudioFileSettings {
    public var isPCM: Bool {
        fileFormat == .aiff || fileFormat == .wav
    }
}
