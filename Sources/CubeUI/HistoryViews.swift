#if canImport(SwiftUI)
//
//  HistoryViews.swift
//  CubeSolver - History and Settings Views
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore

/// View displaying solve history list
struct HistoryView: View {
    @ObservedObject var historyManager: SolveHistoryManager
    
    init(historyManager: SolveHistoryManager) {
        self.historyManager = historyManager
    }
    
    var body: some View {
        List(historyManager.savedSolves) { solve in
            NavigationLink(destination: SolveDetailView(solve: solve)) {
                VStack(alignment: .leading) {
                    Text("\(solve.moveCount) moves")
                        .font(.headline)
                    Text(solve.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Solve History")
    }
}

/// Detail view for a single saved solve
struct SolveDetailView: View {
    let solve: SavedSolve
    
    init(solve: SavedSolve) {
        self.solve = solve
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Solution")
                    .font(.headline)
                
                Text("\(solve.moveCount) moves")
                    .font(.title2)
                
                Text(solve.date, style: .date)
                    .foregroundColor(.secondary)
                
                ForEach(Array(solve.solution.enumerated()), id: \.offset) { index, move in
                    Text("\(index + 1). \(String(describing: move))")
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Solve Details")
    }
}

/// Settings view for privacy and app configuration
struct SettingsView: View {
    @StateObject private var privacySettings = PrivacySettings()
    
    init() {}
    
    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("Analytics", isOn: $privacySettings.analyticsEnabled)
                Toggle("Save History", isOn: $privacySettings.saveSolveHistory)
                Toggle("Crash Reports", isOn: $privacySettings.crashReportingEnabled)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#endif
