//
//  ChannelFormat.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//


enum ChannelFormat {
    case mono
    case stereo
}
extension ChannelFormat: Sendable {}
extension ChannelFormat: CaseIterable {}
