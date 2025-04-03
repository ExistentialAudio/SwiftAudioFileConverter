//
//  AudioFileSettings.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

struct AudioFileSettings {
    let sampleRate: SampleRate
    let bitDepth: BitDepth
    let fileFormat: FileFormat
    let channelFormat: ChannelFormat
    
    var isPCM: Bool {
        return fileFormat == .aiff || fileFormat == .wav
    }
    
    init(sampleRate: SampleRate, bitDepth: BitDepth, fileFormat: FileFormat, channelFormat: ChannelFormat) throws {
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.fileFormat = fileFormat
        self.channelFormat = channelFormat
        
        if !isPCM && bitDepth != .float32 {
            throw SwiftAudioFileConverterError.invalidAudioFileSettings(self)
        }
    }
}

enum SampleRate: Double {
    case kHz8 = 8000
    case kHz16 = 16000
    case kHz24 = 24000
    case kHz44 = 44100
    case kHz48 = 48000
}

enum BitDepth {
    case int16
    case int24
    case float32
}

enum FileFormat: String {
    case aac
    case mp3
    case wav
    case aiff
    case flac
    case alac = "m4a"
}

extension FileFormat: CaseIterable {}

enum ChannelFormat {
    case mono
    case stereo
}
