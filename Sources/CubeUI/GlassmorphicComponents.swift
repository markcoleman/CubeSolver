#if canImport(SwiftUI)
//
//  GlassmorphicComponents.swift
//  CubeSolver - Reusable UI Components
//
//  Created by GitHub Copilot
//

import SwiftUI

// MARK: - Glassmorphic Button

/// A glassmorphic button with icon and title
public struct GlassmorphicButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    let icon: String
    let action: () -> Void
    
    public init(title: String, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(CubeSolverColors.cardBackground(for: colorScheme))
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(CubeSolverColors.glassBorder(for: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: CubeSolverColors.shadow(for: colorScheme), radius: 10, x: 0, y: 5)
            )
            .backdrop(cornerRadius: 15)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glassmorphic Card

/// A glassmorphic card container for content
public struct GlassmorphicCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(CubeSolverColors.cardBackground(for: colorScheme))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(CubeSolverColors.glassBorder(for: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: CubeSolverColors.shadow(for: colorScheme), radius: 15, x: 0, y: 10)
            )
            .backdrop(cornerRadius: 20)
    }
}

// MARK: - View Extension

/// Backdrop modifier for glassmorphism effect
extension View {
    func backdrop(cornerRadius: CGFloat) -> some View {
        #if os(macOS)
        return self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        #else
        return self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        #endif
    }
}

#endif
