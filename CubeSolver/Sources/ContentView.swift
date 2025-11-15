//
//  ContentView.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import SwiftUI

struct ContentView: View {
    @StateObject private var cubeViewModel = CubeViewModel()
    
    var body: some View {
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
            
            VStack(spacing: 30) {
                Text("Rubik's Cube Solver")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                // Cube visualization
                CubeView(cube: cubeViewModel.cube)
                    .frame(maxWidth: 400, maxHeight: 400)
                
                // Control buttons with glassmorphism
                VStack(spacing: 20) {
                    HStack(spacing: 15) {
                        GlassmorphicButton(title: "Scramble", icon: "shuffle") {
                            cubeViewModel.scramble()
                        }
                        
                        GlassmorphicButton(title: "Solve", icon: "checkmark.circle") {
                            cubeViewModel.solve()
                        }
                        
                        GlassmorphicButton(title: "Reset", icon: "arrow.counterclockwise") {
                            cubeViewModel.reset()
                        }
                    }
                    
                    // Solution steps
                    if !cubeViewModel.solutionSteps.isEmpty {
                        ScrollView {
                            GlassmorphicCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Solution Steps")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    ForEach(Array(cubeViewModel.solutionSteps.enumerated()), id: \.offset) { index, step in
                                        HStack {
                                            Text("\(index + 1).")
                                                .foregroundColor(.white.opacity(0.7))
                                            Text(step)
                                                .foregroundColor(.white)
                                        }
                                        .font(.body)
                                    }
                                }
                                .padding()
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

// Glassmorphic Button Component
struct GlassmorphicButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.15))
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .backdrop(cornerRadius: 15)
        }
        .buttonStyle(.plain)
    }
}

// Glassmorphic Card Component
struct GlassmorphicCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
            )
            .backdrop(cornerRadius: 20)
    }
}

// Backdrop modifier for glassmorphism effect
extension View {
    func backdrop(cornerRadius: CGFloat) -> some View {
        #if os(macOS)
        return self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        #else
        return self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        #endif
    }
}

#Preview {
    ContentView()
}
