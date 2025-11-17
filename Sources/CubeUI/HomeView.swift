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
    @Environment(\.colorScheme) private var colorScheme
    
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
}

// MARK: - Supporting Views

struct ActionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
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
                .background(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct RecentSolveRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let solve: SavedSolve
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(solve.moveCount) moves")
                    .font(.headline)
                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                
                Text(solve.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    let value: String
    
    public var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
            
            Text(title)
                .font(.caption)
                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Placeholder Views

// ScanView is replaced by ScannerCameraView

/// Quick solve view that generates random scrambles and demonstrates automatic solving
///
/// Provides functionality to:
/// - Generate random 20-move scrambles
/// - Solve the scrambled cube asynchronously
/// - Navigate to solution playback
struct SolveView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var cubeViewModel: CubeViewModel
    @State private var showingSolution = false
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: CubeSolverColors.backgroundGradient(for: colorScheme)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Quick Solve")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                        .padding(.top, 20)
                    
                    // Description
                    Text("Generate a random scramble and watch the cube solve itself")
                        .font(.subheadline)
                        .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Cube visualization - Use 3D view for better UX
                    #if canImport(SceneKit)
                    Cube3DView(
                        cube: cubeViewModel.cube,
                        autoRotate: true,
                        allowInteraction: true
                    )
                    .frame(height: 400)
                    .padding(.horizontal)
                    #else
                    // Fallback to 2D view
                    CubeView(cube: cubeViewModel.cube)
                        .frame(maxWidth: 400, maxHeight: 400)
                        .padding()
                    #endif
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            cubeViewModel.scramble()
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                    .font(.title3)
                                Text("Scramble Cube")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(cubeViewModel.isSolving)
                        
                        Button(action: {
                            Task {
                                await cubeViewModel.solveAsync()
                            }
                        }) {
                            HStack {
                                if cubeViewModel.isSolving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .font(.title3)
                                }
                                Text(cubeViewModel.isSolving ? "Solving..." : "Solve Cube")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(cubeViewModel.isSolving)
                        
                        Button(action: {
                            cubeViewModel.reset()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                Text("Reset")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                        .disabled(cubeViewModel.isSolving)
                    }
                    .padding(.horizontal)
                    
                    // Solution info
                    if !cubeViewModel.solution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Solution Found!")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            
                            Text("\(cubeViewModel.solution.count) moves")
                                .font(.subheadline)
                                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                            
                            Button(action: {
                                showingSolution = true
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                    Text("View Solution")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if let error = cubeViewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Quick Solve")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(isPresented: $showingSolution) {
            SolutionPlaybackView(
                cubeViewModel: cubeViewModel,
                initialState: CubeState(from: cubeViewModel.cube)
            )
        }
    }
}

/// Practice mode view with timer and scramble generation
///
/// Provides functionality to:
/// - Generate random scrambles for practice
/// - Track solving time with a precision timer
/// - Show hints for next move
/// - Display full solution with playback
struct PracticeView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var cubeViewModel: CubeViewModel
    @State private var scrambleMoves: [CubeCore.Move] = []
    @State private var scrambleNotation: String = ""
    @State private var timeElapsed: TimeInterval = 0
    @State private var timerActive = false
    @State private var timer: Timer?
    @State private var timerStartTime: Date?
    @State private var showHint = false
    @State private var showSolution = false
    @State private var showingSolutionPlayback = false
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: CubeSolverColors.backgroundGradient(for: colorScheme)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Practice Mode")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                        .padding(.top, 20)
                    
                    // Description
                    Text("Practice solving with random scrambles")
                        .font(.subheadline)
                        .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Timer
                    VStack(spacing: 8) {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                        
                        Text(timeString(from: timeElapsed))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            .accessibilityLabel("Time elapsed")
                            .accessibilityValue(timeString(from: timeElapsed))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    
                    // Cube visualization - Use 3D view for better UX
                    #if canImport(SceneKit)
                    Cube3DView(
                        cube: cubeViewModel.cube,
                        autoRotate: false,
                        allowInteraction: true
                    )
                    .frame(height: 400)
                    .padding(.horizontal)
                    #else
                    // Fallback to 2D view
                    CubeView(cube: cubeViewModel.cube)
                        .frame(maxWidth: 400, maxHeight: 400)
                        .padding()
                    #endif
                    
                    // Scramble display
                    if !scrambleNotation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scramble")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            
                            Text(scrambleNotation)
                                .font(.body)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                .padding()
                                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            generateNewScramble()
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                    .font(.title3)
                                Text("New Scramble")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                toggleTimer()
                            }) {
                                HStack {
                                    Image(systemName: timerActive ? "pause.fill" : "play.fill")
                                        .font(.title3)
                                    Text(timerActive ? "Pause" : "Start")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                resetPractice()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title3)
                                    Text("Reset")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                        }
                        
                        // Help buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                showHint.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title3)
                                    Text("Hint")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                Task {
                                    await cubeViewModel.solveAsync()
                                    if !cubeViewModel.solution.isEmpty {
                                        showSolution = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.title3)
                                    Text(cubeViewModel.solution.isEmpty ? "Get Solution" : "Show Solution")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Hint display
                    if showHint && !cubeViewModel.solution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Move Hint")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            
                            Text(cubeViewModel.solution.first.map { String(describing: $0) } ?? "No hint available")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Solution display
                    if showSolution && !cubeViewModel.solution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Full Solution")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            
                            Text("\(cubeViewModel.solution.count) moves")
                                .font(.subheadline)
                                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                            
                            Button(action: {
                                showingSolutionPlayback = true
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                    Text("View Playback")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Practice")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(isPresented: $showingSolutionPlayback) {
            SolutionPlaybackView(
                cubeViewModel: cubeViewModel,
                initialState: CubeState(from: cubeViewModel.cube)
            )
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func generateNewScramble() {
        stopTimer()
        cubeViewModel.reset()
        scrambleMoves = EnhancedCubeSolver.generateScramble(moveCount: 20)
        scrambleNotation = scrambleMoves.map { String(describing: $0) }.joined(separator: " ")
        
        // Apply scramble to cube
        var state = CubeState(from: cubeViewModel.cube)
        EnhancedCubeSolver.applyMoves(to: &state, moves: scrambleMoves)
        cubeViewModel.cube = state.toRubiksCube()
        
        timeElapsed = 0
        showHint = false
        showSolution = false
        cubeViewModel.solution = []  // Clear stale solution
    }
    
    private func toggleTimer() {
        if timerActive {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        timerActive = true
        timerStartTime = Date()
        let newTimer = Timer(timeInterval: 0.1, repeats: true) { [self] _ in
            if let startTime = timerStartTime {
                timeElapsed = Date().timeIntervalSince(startTime)
            }
        }
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    private func stopTimer() {
        timerActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetPractice() {
        stopTimer()
        timeElapsed = 0
        showHint = false
        showSolution = false
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
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
                    Text("\(index + 1). \(String(describing: move))")
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

