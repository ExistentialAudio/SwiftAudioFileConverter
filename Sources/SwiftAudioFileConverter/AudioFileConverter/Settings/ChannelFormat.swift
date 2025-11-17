//
//  ChannelFormat.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

extension AudioFileConverter {
    public enum ChannelFormat {
        case mono
        case stereo
    }
}

extension AudioFileConverter.ChannelFormat: Equatable { }

extension AudioFileConverter.ChannelFormat: Hashable { }

extension AudioFileConverter.ChannelFormat: CaseIterable { }

extension AudioFileConverter.ChannelFormat: Sendable { }

extension AudioFileConverter.ChannelFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .mono:
            "Mono"
        case .stereo:
            "Stereo"
        }
    }
}
