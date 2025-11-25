#if canImport(SwiftUI)
//
//  HomeViewComponents.swift
//  CubeSolver - Home Screen UI Components
//
//  Created by GitHub Copilot
//

import SwiftUI

/// Action card component for the home screen navigation options
public struct ActionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    public init(icon: String, title: String, subtitle: String, color: Color) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
    }
    
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

/// Row component for displaying a recent solve in the history list
public struct RecentSolveRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let solve: SavedSolve
    
    public init(solve: SavedSolve) {
        self.solve = solve
    }
    
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

/// Statistics card for displaying solve metrics
public struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    let value: String
    
    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }
    
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

#endif
