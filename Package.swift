// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlastKit",
    platforms: [
        .iOS(.v14), .macOS(.v13)
    ],
    products: [
        .library(name: "FetchKit", targets: ["FetchKit"]),
        .library(name: "SwiftEase", targets: ["SwiftEase"]),
        .library(name: "TIPSKit", targets: ["TIPSKit"]),
        .library(name: "TIPSCalendarKit", targets: ["TIPSCalendarKit"]),
        .library(name: "BlastKit", targets: ["FetchKit", "SwiftEase", "TIPSKit", "TIPSCalendarKit"])
    ],
    dependencies: [
        // Add external dependencies here
    ],
    targets: [
        .target(name: "FetchKit", dependencies: []),
        .target(name: "SwiftEase", dependencies: []),
        .target(name: "TIPSKit", dependencies: ["FetchKit"]),
        .target(name: "TIPSCalendarKit", dependencies: ["TIPSKit", "SwiftEase"]),
        .testTarget(
            name: "FetchKitTests",
            dependencies: ["FetchKit"]
        ),
        .testTarget(
            name: "SwiftEaseTests",
            dependencies: ["SwiftEase"]
        ),
        .testTarget(
            name: "TIPSKitTests",
            dependencies: ["TIPSKit"]
        ),
        .testTarget(
            name: "TIPSCalendarKitTests",
            dependencies: ["TIPSCalendarKit"]
        )
    ]
)
