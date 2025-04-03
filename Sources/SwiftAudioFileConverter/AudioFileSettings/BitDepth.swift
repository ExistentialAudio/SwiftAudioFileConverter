//
//  BitDepth.swift
//  SwiftAudioFileConverter
//
//  Created by Devin Roth on 2025-04-03.
//
import Foundation


public enum BitDepth {
    case int16
    case int24
    case float32
}
extension BitDepth: Sendable {}
extension BitDepth: CaseIterable {}
