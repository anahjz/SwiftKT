// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftKT",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "SwiftKT",
            targets: ["SwiftKT"]
        )
    ],
    targets: [
        .target(
            name: "SwiftKT",
            path: "Sources/SwiftKT",
            exclude: []
        ),
        .testTarget(
            name: "SwiftKTTests",
            dependencies: ["SwiftKT"],
            path: "Tests/SwiftKTTests"
        )
    ]
)
