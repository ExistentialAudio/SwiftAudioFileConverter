// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftAudioFileConverter",
    platforms: [.macOS(.v13), .iOS(.v14)],
    products: [
        .library(
            name: "SwiftAudioFileConverter",
            targets: ["SwiftAudioFileConverter"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sbooth/CFLAC.git", from: "1.3.2")
    ],
    targets: [
        .target(
            name: "SwiftAudioFileConverter",
            dependencies: [
                .product(name: "FLAC", package: "cflac"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "SwiftAudioFileConverterTests",
            dependencies: ["SwiftAudioFileConverter"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ]
)
