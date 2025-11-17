//
//  AudioFileConverter Settings.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

extension AudioFileConverter {
    public struct Settings {
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
                throw ConverterError.invalidAudioFileSettings(self)
            }
        }
    }
}

extension AudioFileConverter.Settings: Equatable { }

extension AudioFileConverter.Settings: Hashable { }

extension AudioFileConverter.Settings: Sendable { }

extension AudioFileConverter.Settings: CustomStringConvertible {
    public var description: String {
        "\(fileFormat) \(channelFormat) @ \(sampleRate)/\(bitDepth)"
    }
}

// MARK: - Properties

extension AudioFileConverter.Settings {
    public var isPCM: Bool {
        fileFormat == .aiff || fileFormat == .wav
    }
}
