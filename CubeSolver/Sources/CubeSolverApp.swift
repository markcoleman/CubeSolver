//
//  CubeSolverApp.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeUI

@main
struct CubePilotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
