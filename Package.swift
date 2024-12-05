// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CircomWitnesscalc",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CircomWitnesscalc",
            targets: ["CircomWitnesscalc"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/iden3/ios-rapidsnark.git", .upToNextMajor(from: "0.0.1-alpha.5")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CircomWitnesscalc",
            dependencies: ["сircomWitnesscalcС"],
            path: "Sources/CircomWitnesscalc",
            sources: ["CircomWitnesscalc.swift"]
        ),
        .target(
            name: "сircomWitnesscalcС",
            dependencies: ["Libcircom_witnesscalc"],
            path: "Sources/сircomWitnesscalcС"),
        .binaryTarget(
            name: "Libcircom_witnesscalc",
            path: "Libs/libcircom_witnesscalc.xcframework"),
        .testTarget(
            name: "CircomWitnesscalcTests",
            dependencies: [
                "CircomWitnesscalc",
                "ZIPFoundation",
                .product(
                    name: "rapidsnark",
                    package: "ios-rapidsnark"
                )
            ])
    ]
)
