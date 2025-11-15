#if canImport(SwiftUI)
//
//  HomeView.swift
//  CubeSolver - Home Screen
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore

/// Home view showing recent solves and main navigation
public struct HomeView: View {
    
    @StateObject private var historyManager = SolveHistoryManager()
    @StateObject private var cubeViewModel = CubeViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.linearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("CubeSolver")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Next-Gen Rubik's Cube Solver")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Main Actions
                    VStack(spacing: 16) {
                        NavigationLink(destination: ScannerCameraView()) {
                            ActionCard(
                                icon: "camera.fill",
                                title: "Scan Cube",
                                subtitle: "Use camera to detect cube",
                                color: .blue
                            )
                        }
                        
                        NavigationLink(destination: ManualInputView(cubeViewModel: cubeViewModel)) {
                            ActionCard(
                                icon: "hand.tap.fill",
                                title: "Manual Input",
                                subtitle: "Enter cube pattern manually",
                                color: .green
                            )
                        }
                        
                        NavigationLink(destination: SolveView()) {
                            ActionCard(
                                icon: "wand.and.stars",
                                title: "Quick Solve",
                                subtitle: "Solve a scrambled cube",
                                color: .purple
                            )
                        }
                        
                        NavigationLink(destination: PracticeView()) {
                            ActionCard(
                                icon: "figure.run",
                                title: "Practice",
                                subtitle: "Improve your solving skills",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Solves
                    if !historyManager.savedSolves.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Solves")
                                    .font(.headline)
                                Spacer()
                                NavigationLink("See All") {
                                    HistoryView(historyManager: historyManager)
                                }
                                .font(.subheadline)
                            }
                            .padding(.horizontal)
                            
                            ForEach(historyManager.getRecentSolves(count: 3)) { solve in
                                NavigationLink(destination: SolveDetailView(solve: solve)) {
                                    RecentSolveRow(solve: solve)
                                }
                            }
                        }
                    }
                    
                    // Statistics
                    let stats = historyManager.getStatistics()
                    if stats.totalSolves > 0 {
                        VStack(spacing: 16) {
                            Text("Statistics")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 20) {
                                StatCard(title: "Total Solves", value: "\(stats.totalSolves)")
                                StatCard(title: "Avg Moves", value: String(format: "%.1f", stats.averageMoves))
                                if let best = stats.bestSolve {
                                    StatCard(title: "Best", value: "\(best.moveCount)")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.15, blue: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.2))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct RecentSolveRow: View {
    let solve: SavedSolve
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(solve.moveCount) moves")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(solve.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    public var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Placeholder Views

// ScanView is replaced by ScannerCameraView

struct SolveView: View {
    public var body: some View {
        Text("Quick Solve")
            .font(.title)
            .navigationTitle("Solve")
    }
}

struct PracticeView: View {
    public var body: some View {
        Text("Practice Mode")
            .font(.title)
            .navigationTitle("Practice")
    }
}

struct HistoryView: View {
    @ObservedObject var historyManager: SolveHistoryManager
    
    public var body: some View {
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

struct SolveDetailView: View {
    let solve: SavedSolve
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Solution")
                    .font(.headline)
                
                Text("\(solve.moveCount) moves")
                    .font(.title2)
                
                Text(solve.date, style: .date)
                    .foregroundColor(.secondary)
                
                ForEach(Array(solve.solution.enumerated()), id: \.offset) { index, move in
                    Text("\(index + 1). \(move.notation)")
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Solve Details")
    }
}

struct SettingsView: View {
    @StateObject private var privacySettings = PrivacySettings()
    
    public var body: some View {
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
