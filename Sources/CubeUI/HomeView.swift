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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
    @StateObject private var cubeViewModel = CubeViewModel()
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.15, blue: 0.3)
                ]),
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
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Description
                    Text("Generate a random scramble and watch the cube solve itself")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Cube visualization
                    CubeView(cube: cubeViewModel.cube)
                        .frame(maxWidth: 350, maxHeight: 350)
                        .padding()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            cubeViewModel.scramble()
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                Text("Scramble Cube")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.opacity(0.8))
                            .cornerRadius(12)
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
                                }
                                Text(cubeViewModel.isSolving ? "Solving..." : "Solve Cube")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .disabled(cubeViewModel.isSolving)
                        
                        Button(action: {
                            cubeViewModel.reset()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.gray.opacity(0.6))
                            .cornerRadius(12)
                        }
                        .disabled(cubeViewModel.isSolving)
                    }
                    .padding(.horizontal)
                    
                    // Solution info
                    if !cubeViewModel.solution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Solution Found!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(cubeViewModel.solution.count) moves")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            NavigationLink {
                                SolutionPlaybackView(
                                    cubeViewModel: cubeViewModel,
                                    initialState: CubeState(from: cubeViewModel.cube)
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("View Solution")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.opacity(0.8))
                                .cornerRadius(12)
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
    }
}

struct PracticeView: View {
    @StateObject private var cubeViewModel = CubeViewModel()
    @State private var scrambleMoves: [Move] = []
    @State private var scrambleNotation: String = ""
    @State private var timeElapsed: TimeInterval = 0
    @State private var timerActive = false
    @State private var timer: Timer?
    @State private var showHint = false
    @State private var showSolution = false
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.15, blue: 0.3)
                ]),
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
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Description
                    Text("Practice solving with random scrambles")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Timer
                    VStack(spacing: 8) {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(timeString(from: timeElapsed))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                            .foregroundColor(.white)
                            .accessibilityLabel("Time elapsed")
                            .accessibilityValue(timeString(from: timeElapsed))
                            .accessibilityLiveRegion(.polite)
                    
                    // Cube visualization
                    CubeView(cube: cubeViewModel.cube)
                        .frame(maxWidth: 350, maxHeight: 350)
                        .padding()
                    
                    // Scramble display
                    if !scrambleNotation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scramble")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(scrambleNotation)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .padding()
                                .background(Color.black.opacity(0.2))
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
                                Text("New Scramble")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange.opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                toggleTimer()
                            }) {
                                HStack {
                                    Image(systemName: timerActive ? "pause.fill" : "play.fill")
                                    Text(timerActive ? "Pause" : "Start")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.opacity(0.8))
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                resetPractice()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reset")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray.opacity(0.6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Help buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                showHint.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                    Text("Hint")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue.opacity(0.8))
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                Task {
                                    await cubeViewModel.solveAsync()
                                    showSolution = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                    Text("Solution")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.purple.opacity(0.8))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Hint display
                    if showHint && !cubeViewModel.solution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Move Hint")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(cubeViewModel.solution.first?.notation ?? "No hint available")
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
                                .foregroundColor(.white)
                            
                            Text("\(cubeViewModel.solution.count) moves")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            NavigationLink(
                                destination: SolutionPlaybackView(
                                    cubeViewModel: cubeViewModel,
                                    initialState: CubeState(from: cubeViewModel.cube)
                                )
                            ) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("View Playback")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.opacity(0.8))
                                .cornerRadius(12)
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
        .onDisappear {
            stopTimer()
        }
    }
    
    private func generateNewScramble() {
        stopTimer()
        cubeViewModel.reset()
        scrambleMoves = EnhancedCubeSolver.generateScramble(moveCount: 20)
        scrambleNotation = scrambleMoves.map { $0.notation }.joined(separator: " ")
        
        // Apply scramble to cube
        var state = CubeState(from: cubeViewModel.cube)
        EnhancedCubeSolver.applyMoves(to: &state, moves: scrambleMoves)
        cubeViewModel.cube = state.toRubiksCube()
        
        timeElapsed = 0
        showHint = false
        EnhancedCubeSolver.applyMoves(to: &state, moves: scrambleMoves)
    }
    
    private func toggleTimer() {
        if timerActive {
        showSolution = false
        cubeViewModel.solution = []  // Clear stale solution
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        timerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeElapsed += 0.1
        }
    }
    
        let newTimer = Timer(timeInterval: 0.1, repeats: true) { _ in
            timeElapsed += 0.1
        }
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
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
