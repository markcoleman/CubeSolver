//
//  CubeSolverApp.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeUI

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
