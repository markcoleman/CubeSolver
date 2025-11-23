//
//  ScanErrorType.swift
//  CubeSolver - Scan Error Types
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI

/// Types of scan errors with specific recovery guidance
public enum ScanErrorType {
    case cubeNotDetected
    case poorLighting
    case tooMuchMotion
    case duplicateFace
    case invalidColors
    case backgroundClutter
    
    public var title: String {
        switch self {
        case .cubeNotDetected:
            return "Couldn't Lock on to Cube"
        case .poorLighting:
            return "Lighting Issue"
        case .tooMuchMotion:
            return "Too Much Movement"
        case .duplicateFace:
            return "Face Already Scanned"
        case .invalidColors:
            return "Colors Unclear"
        case .backgroundClutter:
            return "Busy Background"
        }
    }
    
    public var message: String {
        switch self {
        case .cubeNotDetected:
            return "The camera can't detect your cube clearly."
        case .poorLighting:
            return "The lighting is too dark or too bright."
        case .tooMuchMotion:
            return "The cube is moving too much to get a clear scan."
        case .duplicateFace:
            return "This face has already been captured."
        case .invalidColors:
            return "The cube colors are too similar or unclear."
        case .backgroundClutter:
            return "The background is making it hard to see the cube."
        }
    }
    
    public var suggestions: [String] {
        switch self {
        case .cubeNotDetected:
            return [
                "Make sure the cube fills most of the frame",
                "Hold the cube steady with one face visible",
                "Try moving to a well-lit area"
            ]
        case .poorLighting:
            return [
                "Move to a brighter area or add more light",
                "Avoid direct sunlight or harsh shadows",
                "Try indoor lighting for best results"
            ]
        case .tooMuchMotion:
            return [
                "Hold the cube as steady as possible",
                "Rest your hands on a stable surface",
                "Wait for the green outline before moving"
            ]
        case .duplicateFace:
            return [
                "Rotate the cube to show a different face",
                "Check the mini cube to see which faces are captured",
                "Tap a face on the mini cube to rescan it"
            ]
        case .invalidColors:
            return [
                "Clean the cube if stickers are dirty",
                "Move to better lighting",
                "Ensure stickers are not faded or peeling"
            ]
        case .backgroundClutter:
            return [
                "Use a plain, solid-colored background",
                "Move away from patterned surfaces",
                "Try a white or black background for best results"
            ]
        }
    }
    
    public var iconName: String {
        switch self {
        case .cubeNotDetected:
            return "viewfinder.circle"
        case .poorLighting:
            return "lightbulb.slash"
        case .tooMuchMotion:
            return "hand.raised.slash"
        case .duplicateFace:
            return "arrow.triangle.2.circlepath"
        case .invalidColors:
            return "paintpalette"
        case .backgroundClutter:
            return "rectangle.stack.badge.minus"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .cubeNotDetected, .poorLighting, .tooMuchMotion:
            return .orange
        case .duplicateFace:
            return .blue
        case .invalidColors, .backgroundClutter:
            return .red
        }
    }
}

#endif
