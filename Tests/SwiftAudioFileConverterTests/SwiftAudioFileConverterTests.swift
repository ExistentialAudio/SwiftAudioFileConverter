import Foundation
import Testing
@testable import SwiftAudioFileConverter

@available(macOS 13.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@Test func example() async throws {
    let settings = try AudioFileSettings(
        sampleRate: .kHz48,
        bitDepth: .float32,
        fileFormat: .flac,
        channelFormat: .stereo)
    
    let inputURL = URL.desktopDirectory.appending(path: "dipper.wav")
    let outputURL = URL.desktopDirectory.appending(path: "dipper.flac")
    
    try await SwiftAudioFileConverter.convert(
        from: inputURL,
        to: outputURL,
        with: settings
    )
}
