//
//  FaceScanState.swift
//  CubeSolver - Enhanced Face Scan State Management
//
//  Created by GitHub Copilot
//

#if canImport(CoreVideo)

import Foundation
import CubeCore

/// State of an individual face during scanning
public enum FaceScanState: Equatable {
    /// Face has not been scanned yet
    case notScanned
    
    /// Face is currently being scanned (camera is detecting it)
    case scanning(progress: Float)
    
    /// Face has been successfully captured
    case captured
    
    /// Face scan failed with an error
    case error(String)
    
    public static func == (lhs: FaceScanState, rhs: FaceScanState) -> Bool {
        switch (lhs, rhs) {
        case (.notScanned, .notScanned),
             (.captured, .captured):
            return true
        case let (.scanning(p1), .scanning(p2)):
            return abs(p1 - p2) < 0.01
        case let (.error(m1), .error(m2)):
            return m1 == m2
        default:
            return false
        }
    }
}

/// Guided instruction for a specific scan step
public struct ScanStepGuidance: Equatable {
    /// Current step number (1-6)
    public let stepNumber: Int
    
    /// Total number of steps (always 6 for a cube)
    public let totalSteps: Int
    
    /// The face to scan in this step
    public let targetFace: Face
    
    /// Primary instruction text
    public let instruction: String
    
    /// Secondary helpful hint (optional)
    public let hint: String?
    
    /// Icon name for this step (SF Symbol)
    public let iconName: String
    
    public init(
        stepNumber: Int,
        totalSteps: Int = 6,
        targetFace: Face,
        instruction: String,
        hint: String? = nil,
        iconName: String = "viewfinder"
    ) {
        self.stepNumber = stepNumber
        self.totalSteps = totalSteps
        self.targetFace = targetFace
        self.instruction = instruction
        self.hint = hint
        self.iconName = iconName
    }
    
    /// Get the display name for a face
    public static func faceDisplayName(_ face: Face) -> String {
        switch face {
        case .up: return "Top"
        case .down: return "Bottom"
        case .left: return "Left"
        case .right: return "Right"
        case .front: return "Front"
        case .back: return "Back"
        }
    }
    
    /// Create guidance for scanning a specific face
    public static func guidance(for face: Face, stepNumber: Int) -> ScanStepGuidance {
        let faceName = faceDisplayName(face)
        
        let instruction: String
        let hint: String?
        let iconName: String
        
        switch stepNumber {
        case 1:
            instruction = "Position any face in the frame (suggested: \(faceName))"
            hint = "Hold steady when the outline turns green"
            iconName = "1.circle.fill"
        case 2...5:
            instruction = "Show any unscanned face (suggested: \(faceName))"
            hint = "Captured: \(capturedFacesList(upTo: stepNumber - 1))"
            iconName = "\(stepNumber).circle.fill"
        case 6:
            instruction = "Final face! Scan the last unscanned side"
            hint = "Suggested final side: \(faceName)"
            iconName = "6.circle.fill"
        default:
            instruction = "Scan the \(faceName) face"
            hint = nil
            iconName = "viewfinder"
        }
        
        return ScanStepGuidance(
            stepNumber: stepNumber,
            targetFace: face,
            instruction: instruction,
            hint: hint,
            iconName: iconName
        )
    }
    
    private static func capturedFacesList(upTo step: Int) -> String {
        // This would ideally take the actual captured faces
        // For now, just indicate the count
        return "\(step) captured"
    }
}

/// Result of a face scan attempt
public struct ScanResult: Equatable {
    /// Whether the scan was successful
    public let success: Bool
    
    /// The face that was scanned
    public let face: Face
    
    /// Message to show the user
    public let message: String
    
    /// Type of feedback to provide
    public let feedbackType: FeedbackType
    
    public enum FeedbackType: Equatable {
        case success
        case warning
        case error
        
        public var hapticStyle: HapticFeedbackStyle {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            }
        }
    }
    
    public init(success: Bool, face: Face, message: String, feedbackType: FeedbackType) {
        self.success = success
        self.face = face
        self.message = message
        self.feedbackType = feedbackType
    }
    
    /// Create a success result
    public static func success(face: Face) -> ScanResult {
        ScanResult(
            success: true,
            face: face,
            message: "\(ScanStepGuidance.faceDisplayName(face)) face captured!",
            feedbackType: .success
        )
    }
    
    /// Create a duplicate face error
    public static func duplicateFace(_ face: Face) -> ScanResult {
        ScanResult(
            success: false,
            face: face,
            message: "This face was already scanned. Please scan a different face.",
            feedbackType: .warning
        )
    }
    
    /// Create a generic error result
    public static func error(face: Face, message: String) -> ScanResult {
        ScanResult(
            success: false,
            face: face,
            message: message,
            feedbackType: .error
        )
    }
}

/// Haptic feedback style for scan events
public enum HapticFeedbackStyle {
    case success
    case warning
    case error
}

#endif
