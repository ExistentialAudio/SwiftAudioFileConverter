//
//  AudioFileSettings.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

public struct AudioFileSettings {
    let sampleRate: SampleRate
    let bitDepth: BitDepth
    let fileFormat: FileFormat
    let channelFormat: ChannelFormat
    
    var isPCM: Bool {
        return fileFormat == .aiff || fileFormat == .wav
    }
    
    public init(sampleRate: SampleRate, bitDepth: BitDepth, fileFormat: FileFormat, channelFormat: ChannelFormat) throws {
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.fileFormat = fileFormat
        self.channelFormat = channelFormat
        
        if !isPCM && bitDepth != .float32 {
            throw SwiftAudioFileConverterError.invalidAudioFileSettings(self)
        }
    }
}

extension AudioFileSettings: Sendable {}
