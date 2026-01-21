// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NetworkingKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .macCatalyst(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "NetworkingKit",
            targets: ["NetworkingKit"]
        ),
    ],
    targets: [
        .target(
            name: "NetworkingKit"
        ),

    ]
)
