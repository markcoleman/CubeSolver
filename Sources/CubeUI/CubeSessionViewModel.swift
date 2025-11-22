//
//  CubeSessionViewModel.swift
//  CubeSolver - Shared Session State
//
//  Created by GitHub Copilot
//

#if canImport(SwiftUI)

import Foundation
import SwiftUI
import CubeCore

/// Shared view model that holds the current cube state across the app
/// This allows different features (scanner, manual input, AR coach) to share state
@MainActor
public final class CubeSessionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current cube state (nil if no cube has been scanned or entered)
    @Published public var currentCubeState: CubeState?
    
    /// Whether a valid cube state is available
    public var hasCubeState: Bool {
        return currentCubeState != nil
    }
    
    /// Last scan/input timestamp
    @Published public var lastUpdateTime: Date?
    
    /// Source of the cube state
    @Published public var stateSource: CubeStateSource = .none
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Set cube state from scanner
    public func setCubeStateFromScan(_ state: CubeState) {
        currentCubeState = state
        lastUpdateTime = Date()
        stateSource = .scanner
    }
    
    /// Set cube state from manual input
    public func setCubeStateFromManual(_ state: CubeState) {
        currentCubeState = state
        lastUpdateTime = Date()
        stateSource = .manualInput
    }
    
    /// Set cube state from existing RubiksCube
    public func setCubeState(from cube: RubiksCube) {
        currentCubeState = CubeState(from: cube)
        lastUpdateTime = Date()
        stateSource = .other
    }
    
    /// Clear the current cube state
    public func clearCubeState() {
        currentCubeState = nil
        lastUpdateTime = nil
        stateSource = .none
    }
}

// MARK: - Cube State Source

/// Indicates where the cube state came from
public enum CubeStateSource: String {
    case none = "None"
    case scanner = "Scanner"
    case manualInput = "Manual Input"
    case other = "Other"
}

#endif

