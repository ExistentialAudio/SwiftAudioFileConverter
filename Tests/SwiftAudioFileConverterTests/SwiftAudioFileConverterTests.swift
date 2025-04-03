import Foundation
import Testing
@testable import SwiftAudioFileConverter

@Test func example() async throws {
    
    let settings = try AudioFileSettings(
        sampleRate: .kHz48,
        bitDepth: .float32,
        fileFormat: .aiff,
        channelFormat: .stereo)
    
    let inputURL = URL.desktopDirectory.appending(path: "dipper.wav")
    let outputURL = URL.desktopDirectory.appending(path: "dipper.aiff")
    
    try await SwiftAudioFileConverter.convert(
        from: inputURL,
        to: outputURL,
        with: settings
    )
}
