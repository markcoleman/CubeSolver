#if canImport(SwiftUI)
//
//  ColorScheme.swift
//  CubeSolver - Adaptive Color Scheme
//
//  Created by GitHub Copilot
//

import SwiftUI

/// Adaptive color scheme that works in both light and dark modes
public struct CubeSolverColors {
    
    // MARK: - Background Colors
    
    /// Primary background gradient colors
    public static func backgroundGradient(for colorScheme: ColorScheme) -> [Color] {
        switch colorScheme {
        case .light:
            return [
                Color(red: 0.95, green: 0.96, blue: 0.98),
                Color(red: 0.88, green: 0.90, blue: 0.95)
            ]
        case .dark:
            return [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.15, blue: 0.3)
            ]
        @unknown default:
            return [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.15, blue: 0.3)
            ]
        }
    }
    
    /// Secondary background for cards and overlays
    public static func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color.white.opacity(0.7)
        case .dark:
            return Color.white.opacity(0.1)
        @unknown default:
            return Color.white.opacity(0.1)
        }
    }
    
    // MARK: - Text Colors
    
    /// Primary text color
    public static func primaryText(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.1, green: 0.1, blue: 0.15)
        case .dark:
            return Color.white
        @unknown default:
            return Color.white
        }
    }
    
    /// Secondary text color
    public static func secondaryText(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.4, green: 0.4, blue: 0.5)
        case .dark:
            return Color.white.opacity(0.7)
        @unknown default:
            return Color.white.opacity(0.7)
        }
    }
    
    // MARK: - Accent Colors
    
    /// Glassmorphic border color
    public static func glassBorder(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color.white.opacity(0.5)
        case .dark:
            return Color.white.opacity(0.2)
        @unknown default:
            return Color.white.opacity(0.2)
        }
    }
    
    /// Shadow color
    public static func shadow(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color.black.opacity(0.15)
        case .dark:
            return Color.black.opacity(0.3)
        @unknown default:
            return Color.black.opacity(0.3)
        }
    }
}

// MARK: - View Extension for Environment

extension View {
    /// Apply adaptive background gradient
    public func adaptiveBackground() -> some View {
        modifier(AdaptiveBackgroundModifier())
    }
}

struct AdaptiveBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: CubeSolverColors.backgroundGradient(for: colorScheme),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

// MARK: - Adaptive Text Color

extension View {
    /// Apply adaptive primary text color
    public func adaptiveTextColor() -> some View {
        modifier(AdaptiveTextColorModifier())
    }
    
    /// Apply adaptive secondary text color
    public func adaptiveSecondaryTextColor() -> some View {
        modifier(AdaptiveSecondaryTextColorModifier())
    }
}

struct AdaptiveTextColorModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
    }
}

struct AdaptiveSecondaryTextColorModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
    }
}

#endif
