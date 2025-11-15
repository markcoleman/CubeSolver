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

// MARK: - Glassmorphic Card

/// A glassmorphic card container for content
public struct GlassmorphicCard<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
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
    
    /// Cross-platform navigation bar title display mode
    /// Only applies on iOS where it's available
    func crossPlatformNavigationBarTitleDisplayMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View {
        #if os(iOS)
        return self.navigationBarTitleDisplayMode(mode)
        #else
        return self
        #endif
    }
}

#endif
