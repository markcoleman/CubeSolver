#if canImport(SwiftUI)
//
//  HomeView.swift
//  CubeSolver - Home Screen
//
//  Main navigation hub for the CubeSolver app. This view provides access to:
//  - Cube scanning (camera-based)
//  - Manual cube input
//  - Quick solve functionality
//  - Practice mode
//  - Solve history and statistics
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore
#if canImport(CubeAR)
import CubeAR
#endif

/// Home view showing recent solves and main navigation
public struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var historyManager = SolveHistoryManager()
    @StateObject private var cubeViewModel = CubeViewModel()
    @StateObject private var sessionViewModel = CubeSessionViewModel()
    @State private var showARCoachMode = false
    @State private var showNoCubeAlert = false
    
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
        #if canImport(CubeAR) && os(iOS)
        .sheet(isPresented: $showARCoachMode) {
            if let cubeState = sessionViewModel.currentCubeState {
                ARCoachView(initialState: cubeState)
            }
        }
        .alert("No Cube State", isPresented: $showNoCubeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please scan a cube or enter a cube pattern manually before using AR Coach Mode.")
        }
        #endif
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
            
            Text("CubeSolver")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
            
            Text("Next-Gen Rubik's Cube Solver")
                .font(.subheadline)
                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
        }
        .padding(.top, 40)
    }
    
    private var mainActionsSection: some View {
        VStack(spacing: 16) {
            // Cube Cam - Auto-scan with video
            #if canImport(AVFoundation) && os(iOS)
            NavigationLink(destination: CubeCamView { cubeState in
                // Handle completed cube state
                sessionViewModel.setCubeStateFromScan(cubeState)
                cubeViewModel.cube = cubeState.toRubiksCube()
            }) {
                ActionCard(
                    icon: "video.fill",
                    title: "Cube Cam",
                    subtitle: "Auto-scan with guided capture",
                    color: .cyan
                )
            }
            #endif
            
            NavigationLink(destination: ScannerCameraView()) {
                ActionCard(
                    icon: "camera.fill",
                    title: "Scan Cube",
                    subtitle: "Use camera to detect cube",
                    color: .blue
                )
            }
            
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
            
            // AR Coach Mode entry point
            #if canImport(CubeAR) && os(iOS)
            Button(action: {
                if sessionViewModel.hasCubeState {
                    showARCoachMode = true
                } else {
                    // Try to use current cube from cubeViewModel
                    if !cubeViewModel.cube.isSolved {
                        sessionViewModel.setCubeState(from: cubeViewModel.cube)
                        showARCoachMode = true
                    } else {
                        showNoCubeAlert = true
                    }
                }
            }) {
                ActionCard(
                    icon: "arkit",
                    title: "AR Coach Mode",
                    subtitle: "Step-by-step AR guidance",
                    color: .cyan
                )
            }
            #endif
            
            NavigationLink(destination: SolveView(cubeViewModel: cubeViewModel)) {
                ActionCard(
                    icon: "wand.and.stars",
                    title: "Quick Solve",
                    subtitle: "Solve a scrambled cube",
                    color: .purple
                )
            }
            
            NavigationLink(destination: PracticeView(cubeViewModel: cubeViewModel)) {
                ActionCard(
                    icon: "figure.run",
                    title: "Practice",
                    subtitle: "Improve your solving skills",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }
    
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
