//
//  SampleRate.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

public enum SampleRate: Double {
    case kHz8 = 8000
    case kHz16 = 16000
    case kHz24 = 24000
    case kHz44 = 44100
    case kHz48 = 48000
}

extension SampleRate: Equatable { }

extension SampleRate: Hashable { }

extension SampleRate: Sendable { }

extension SampleRate: CaseIterable { }
