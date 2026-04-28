// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Nyap",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "Nyap",
            resources: [
                .process("Assets.xcassets"),
            ]
        ),
    ]
)
