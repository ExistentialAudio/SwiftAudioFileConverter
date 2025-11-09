//
//  ChannelFormat.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//

import Foundation

public enum ChannelFormat {
    case mono
    case stereo
}

extension ChannelFormat: Equatable { }

extension ChannelFormat: Hashable { }

extension ChannelFormat: CaseIterable { }

extension ChannelFormat: Sendable { }

extension ChannelFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .mono:
            "Mono"
        case .stereo:
            "Stereo"
        }
    }
}
