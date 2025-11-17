import Foundation
import Testing
@testable import SwiftAudioFileConverter

/// Not a unit test. A simple test harness to perform a local file conversion.
@available(macOS 13.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@Test func manualConversion() async throws {
    let settings = try AudioFileConverter.Settings(
        sampleRate: .kHz48,
        bitDepth: .float32,
        fileFormat: .flac,
        channelFormat: .stereo)
    
    let inputURL = URL.desktopDirectory.appending(path: "test.wav")
    let outputURL = URL.desktopDirectory.appending(path: "test.flac")
    
    try await AudioFileConverter.convert(
        from: inputURL,
        to: outputURL,
        with: settings
    )
}
