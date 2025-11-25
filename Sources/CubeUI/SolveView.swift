#if canImport(SwiftUI)
//
//  SolveView.swift
//  CubeSolver - Quick Solve View
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore

/// Quick solve view that generates random scrambles and demonstrates automatic solving
///
/// Provides functionality to:
/// - Generate random 20-move scrambles
/// - Solve the scrambled cube asynchronously
/// - Navigate to solution playback
public struct SolveView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var cubeViewModel: CubeViewModel
    @State private var showingSolution = false
    
    public init(cubeViewModel: CubeViewModel) {
        self.cubeViewModel = cubeViewModel
    }
    
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
                initialState: CubeState(from: cubeViewModel.cube)
            )
        }
    }
}

#endif
