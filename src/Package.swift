// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThesisCLI",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        // Add your dependencies here
        // .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/jkrukowski/swift-embeddings", from: "0.0.16")
    ],
    targets: [
        .executableTarget(
            name: "ThesisCLI",
            dependencies: [
                // Add your target dependencies here
                // .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Embeddings", package: "swift-embeddings")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ThesisCLITests",
            dependencies: ["ThesisCLI"],
            path: "Tests"
        ),
    ]
)
