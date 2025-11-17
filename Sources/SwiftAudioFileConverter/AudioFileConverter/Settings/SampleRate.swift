//
//  SampleRate.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

extension AudioFileConverter {
    public enum SampleRate {
        case kHz8
        case kHz16
        case kHz24
        case kHz44_1
        case kHz48
    }
}

extension AudioFileConverter.SampleRate: Equatable { }

extension AudioFileConverter.SampleRate: Hashable { }

extension AudioFileConverter.SampleRate: Sendable { }

extension AudioFileConverter.SampleRate: CaseIterable { }

extension AudioFileConverter.SampleRate: CustomStringConvertible {
    public var description: String {
        "\(hzInt)Hz"
    }
}

// MARK: - Properties

extension AudioFileConverter.SampleRate {
    public var hzInt: Int {
        switch self {
        case .kHz8: 8000
        case .kHz16: 16000
        case .kHz24: 24000
        case .kHz44_1: 44100
        case .kHz48: 48000
        }
    }
    
    public var hzDouble: Double {
        switch self {
        case .kHz8: 8000
        case .kHz16: 16000
        case .kHz24: 24000
        case .kHz44_1: 44100
        case .kHz48: 48000
        }
    }
    
    public var kHzDouble: Double {
        switch self {
        case .kHz8: 8.000
        case .kHz16: 16.000
        case .kHz24: 24.000
        case .kHz44_1: 44.100
        case .kHz48: 48.000
        }
    }
}
