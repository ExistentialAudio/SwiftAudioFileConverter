// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAudioFileConverter",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftAudioFileConverter",
            targets: ["SwiftAudioFileConverter"]),
    ],
    dependencies: [
    .package(url: "https://github.com/Phisto/swift-lame.git", .upToNextMajor(from: "3.100.0")),
    .package(url: "https://github.com/sbooth/CFLAC.git", from: "1.3.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftAudioFileConverter",
            dependencies: [
                .product(name: "lame", package: "swift-lame"),
                .product(name: "FLAC", package: "cflac"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "SwiftAudioFileConverterTests",
            dependencies: ["SwiftAudioFileConverter"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ]
)
