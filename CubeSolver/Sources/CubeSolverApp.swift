//
//  CubeSolverApp.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import SwiftUI

@main
struct CubeSolverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
