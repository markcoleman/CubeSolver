#if canImport(SwiftUI)
//
//  PrivacySettings.swift
//  CubeSolver - Privacy Module
//
//  Created by GitHub Copilot
//

import Foundation
import SwiftUI

/// Privacy and analytics settings manager
@MainActor
public class PrivacySettings: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether anonymous analytics are enabled (default: false for privacy)
    @Published public var analyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: "com.cubesolver.analyticsEnabled")
        }
    }
    
    /// Whether to save solve history locally
    @Published public var saveSolveHistory: Bool {
        didSet {
            UserDefaults.standard.set(saveSolveHistory, forKey: "com.cubesolver.saveSolveHistory")
        }
    }
    
    /// Whether crash reporting is enabled
    @Published public var crashReportingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(crashReportingEnabled, forKey: "com.cubesolver.crashReportingEnabled")
        }
    }
    
    // MARK: - Initialization
    
    public init() {
        // Load settings from UserDefaults (default to false for privacy)
        self.analyticsEnabled = UserDefaults.standard.bool(forKey: "com.cubesolver.analyticsEnabled")
        self.saveSolveHistory = UserDefaults.standard.object(forKey: "com.cubesolver.saveSolveHistory") as? Bool ?? true
        self.crashReportingEnabled = UserDefaults.standard.bool(forKey: "com.cubesolver.crashReportingEnabled")
    }
    
    // MARK: - Public Methods
    
    /// Reset all privacy settings to defaults
    public func resetToDefaults() {
        analyticsEnabled = false
        saveSolveHistory = true
        crashReportingEnabled = false
    }
    
    /// Export privacy settings as a dictionary for display
    /// - Returns: Dictionary of setting names to values
    public func exportSettings() -> [String: Any] {
        return [
            "Analytics Enabled": analyticsEnabled,
            "Save Solve History": saveSolveHistory,
            "Crash Reporting": crashReportingEnabled
        ]
    }
}

/// Anonymous analytics event tracker (opt-in only)
@MainActor
public class AnalyticsTracker: ObservableObject {
    
    private let privacySettings: PrivacySettings
    
    // MARK: - Initialization
    
    public init(privacySettings: PrivacySettings) {
        self.privacySettings = privacySettings
    }
    
    // MARK: - Event Tracking
    
    /// Track a solve event
    /// - Parameters:
    ///   - moveCount: Number of moves in the solution
    ///   - solveTime: Time taken to solve
    public func trackSolve(moveCount: Int, solveTime: TimeInterval) {
        guard privacySettings.analyticsEnabled else { return }
        
        // In a real app, this would send anonymous data to analytics service
        print("Analytics: Solve tracked - \(moveCount) moves in \(solveTime)s")
    }
    
    /// Track a scan event
    /// - Parameters:
    ///   - success: Whether the scan was successful
    ///   - scanTime: Time taken to scan
    public func trackScan(success: Bool, scanTime: TimeInterval) {
        guard privacySettings.analyticsEnabled else { return }
        
        print("Analytics: Scan tracked - success: \(success), time: \(scanTime)s")
    }
    
    /// Track AR mode usage
    /// - Parameter duration: Time spent in AR mode
    public func trackARUsage(duration: TimeInterval) {
        guard privacySettings.analyticsEnabled else { return }
        
        print("Analytics: AR usage tracked - \(duration)s")
    }
    
    /// Track app launch
    public func trackAppLaunch() {
        guard privacySettings.analyticsEnabled else { return }
        
        print("Analytics: App launch tracked")
    }
}
#endif
