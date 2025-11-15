// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CubeSolver",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CubeSolverCore",
            targets: ["CubeSolverCore"]),
    ],
    targets: [
        .target(
            name: "CubeSolverCore",
            path: "CubeSolver/Sources",
            exclude: [
                "CubeSolverApp.swift",
                "ContentView.swift",
                "CubeView.swift",
                "CubeViewModel.swift"
            ],
            sources: [
                "RubiksCube.swift",
                "CubeSolver.swift"
            ]
        ),
        .testTarget(
            name: "CubeSolverTests",
            dependencies: ["CubeSolverCore"],
            path: "CubeSolver/Tests"),
    ]
)
