// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Blastkit",
	platforms: [
		.iOS(.v13),
		.macOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6),
	],
	products: [
		.library(
			name: "Blastkit",
			targets: ["Blastkit"]
		),
		.library(
			name: "FetchKit",
			targets: ["FetchKit"]
		),
		.library(
			name: "TIPSKit",
			targets: ["TIPSKit"]
		),
		.library(
			name: "TIPSCalendarKit",
			targets: ["TIPSCalendarKit"]
		),
		.library(
			name: "SwiftEase",
			targets: ["SwiftEase"]
		),
		.executable(
			name: "PayoutCalculationDemo",
			targets: ["PayoutCalculationDemo"]
		),
		.executable(
			name: "TIPSCalendarGenerator",
			targets: ["TIPSCalendarGenerator"]
		),
		.executable(
			name: "HTMLGenerationDemo",
			targets: ["HTMLGenerationDemo"]
		),
	],
	dependencies: [],
	targets: [
		.target(
			name: "Blastkit",
			dependencies: [
				"FetchKit",
				"TIPSKit",
				"TIPSCalendarKit",
				"SwiftEase",
			],
			path: "Sources/Blastkit"
		),
		.target(
			name: "FetchKit",
			dependencies: [],
			path: "Sources/FetchKit"
		),
		.target(
			name: "TIPSKit",
			dependencies: ["FetchKit", "SwiftEase"],
			path: "Sources/TIPSKit"
		),
		.target(
			name: "TIPSCalendarKit",
			dependencies: ["TIPSKit"],
			path: "Sources/TIPSCalendarKit",
			resources: [
				.process("Resources")
			]
		),
		.target(
			name: "SwiftEase",
			dependencies: [],
			path: "Sources/SwiftEase"
		),
		.testTarget(
			name: "BlastkitTests",
			dependencies: ["Blastkit"],
			path: "Tests/BlastkitTests"
		),
		.testTarget(
			name: "FetchKitTests",
			dependencies: ["FetchKit"],
			path: "Tests/FetchKitTests"
		),
		.testTarget(
			name: "TIPSKitTests",
			dependencies: ["TIPSKit"],
			path: "Tests/TIPSKitTests"
		),
		.testTarget(
			name: "TIPSCalendarKitTests",
			dependencies: ["TIPSCalendarKit"],
			path: "Tests/TIPSCalendarKitTests"
		),
		.testTarget(
			name: "SwiftEaseTests",
			dependencies: ["SwiftEase"],
			path: "Tests/SwiftEaseTests"
		),
		.executableTarget(
			name: "PayoutCalculationDemo",
			dependencies: ["TIPSKit", "TIPSCalendarKit"],
			path: "Examples/PayoutCalculationDemo"
		),
		.executableTarget(
			name: "TIPSCalendarGenerator",
			dependencies: ["TIPSCalendarKit", "TIPSKit"],
			path: "Sources/TIPSCalendarGenerator"
		),
		.executableTarget(
			name: "HTMLGenerationDemo",
			dependencies: ["TIPSCalendarKit", "TIPSKit"],
			path: "Examples",
			sources: ["HTMLGenerationDemo.swift"]
		),
	]
)
