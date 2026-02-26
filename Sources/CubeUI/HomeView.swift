#if canImport(SwiftUI)
//
//  HomeView.swift
//  CubeSolver - Home Screen
//
//  Main navigation hub for the CubeSolver app. This view provides access to:
//  - Cube camera scanning (auto-scan)
//  - Photo capture for cube detection
//  - Manual cube input
//  - Solve history and statistics
//  - Settings
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore

/// Home view showing recent solves and main navigation
public struct HomeView: View {
    #if DEBUG
    private static let solveModeDebugFixture = SolveModeDebugFixture.stress()
    #endif

    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var historyManager = SolveHistoryManager()
    @StateObject private var cubeViewModel = CubeViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    mainActionsSection
                    recentSolvesSection
                    statisticsSection
                }
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: CubeSolverColors.backgroundGradient(for: colorScheme),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                    }
                }
            }
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "cube.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            Text("Cube Pilot")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
            
            Text("Guided Rubik's Cube Solver")
                .font(.subheadline)
                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
        }
        .padding(.top, 40)
    }
    
    private var mainActionsSection: some View {
        VStack(spacing: 16) {
            #if canImport(AVFoundation) && os(iOS)
            NavigationLink(destination: LiveScanWizardContainerView()) {
                ActionCard(
                    icon: "viewfinder.circle.fill",
                    title: "Scan Cube",
                    subtitle: "Capture all six faces with guidance",
                    color: .indigo
                )
            }
            #endif
            
            // Photo Capture - Manual single-shot mode with debug
            #if os(iOS)
            NavigationLink(destination: ManualPhotoCaptureView()) {
                ActionCard(
                    icon: "camera.viewfinder",
                    title: "Photo Capture",
                    subtitle: "Take a photo and see detected colors",
                    color: .teal
                )
            }
            #endif
            
            NavigationLink(destination: ManualInputView(cubeViewModel: cubeViewModel)) {
                ActionCard(
                    icon: "hand.tap.fill",
                    title: "Manual Input",
                    subtitle: "Enter cube pattern manually",
                    color: .green
                )
            }

            #if DEBUG
            NavigationLink(destination: solveModeDebugDestination) {
                ActionCard(
                    icon: "ladybug.fill",
                    title: "Solve Mode (Debug)",
                    subtitle: "Launch guided solve without solver",
                    color: .orange
                )
            }
            #endif
        }
        .padding(.horizontal)
    }

    #if DEBUG
    private var solveModeDebugDestination: some View {
        SolveModeView(
            state: Self.solveModeDebugFixture.initialState,
            solution: Self.solveModeDebugFixture.solution
        )
    }
    #endif
    
    @ViewBuilder
    private var recentSolvesSection: some View {
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
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
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
}

#endif
