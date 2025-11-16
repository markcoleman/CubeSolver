// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CubeSolver",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        // Core cube logic - model, validation, solver
        .library(
            name: "CubeCore",
            targets: ["CubeCore"]),
        
        // UI components library
        .library(
            name: "CubeUI",
            targets: ["CubeUI"]),
        
        // Scanner module (Vision + CoreML)
        .library(
            name: "CubeScanner",
            targets: ["CubeScanner"]),
        
        // AR module (ARKit + RealityKit)
        .library(
            name: "CubeAR",
            targets: ["CubeAR"]),
    ],
    dependencies: [],
    targets: [
        // MARK: - Core Module
        .target(
            name: "CubeCore",
            dependencies: [],
            path: "Sources/CubeCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        
        // MARK: - UI Module
        .target(
            name: "CubeUI",
            dependencies: ["CubeCore"],
            path: "Sources/CubeUI"
        ),
        
        // MARK: - Scanner Module
        .target(
            name: "CubeScanner",
            dependencies: ["CubeCore"],
            path: "Sources/CubeScanner"
        ),
        
        // MARK: - AR Module
        .target(
            name: "CubeAR",
            dependencies: ["CubeCore"],
            path: "Sources/CubeAR"
        ),
        
        // MARK: - Tests
        .testTarget(
            name: "CubeCoreTests",
            dependencies: ["CubeCore"],
            path: "Tests/CubeCoreTests"
        ),
        .testTarget(
            name: "CubeScannerTests",
            dependencies: ["CubeScanner", "CubeCore"],
            path: "Tests/CubeScannerTests"
        ),
        .testTarget(
            name: "CubeARTests",
            dependencies: ["CubeAR", "CubeCore"],
            path: "Tests/CubeARTests"
        ),
    ]
)
