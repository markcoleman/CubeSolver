#if canImport(SwiftUI)
//
//  CubePersistence.swift
//  CubeSolver - Persistence Module
//
//  Created by GitHub Copilot
//

import Foundation
import SwiftUI
import CubeCore

/// Represents a saved solve session
public struct SavedSolve: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let initialState: CubeState
    public let solution: [Move]
    public let moveCount: Int
    public let timeToSolve: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        initialState: CubeState,
        solution: [Move],
        moveCount: Int,
        timeToSolve: TimeInterval? = nil
    ) {
        self.id = id
        self.date = date
        self.initialState = initialState
        self.solution = solution
        self.moveCount = moveCount
        self.timeToSolve = timeToSolve
    }
}

/// Manager for persisting and retrieving solve history
@MainActor
public class SolveHistoryManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of saved solves, most recent first
    @Published public private(set) var savedSolves: [SavedSolve] = []
    
    // MARK: - Storage
    
    private let userDefaultsKey = "com.cubesolver.savedSolves"
    private let maxSavedSolves = 100
    
    // MARK: - Initialization
    
    public init() {
        loadSolves()
    }
    
    // MARK: - Public Methods
    
    /// Save a new solve to history
    /// - Parameter solve: The solve to save
    public func saveSolve(_ solve: SavedSolve) {
        savedSolves.insert(solve, at: 0)
        
        // Limit the number of saved solves
        if savedSolves.count > maxSavedSolves {
            savedSolves.removeLast(savedSolves.count - maxSavedSolves)
        }
        
        persistSolves()
    }
    
    /// Delete a solve from history
    /// - Parameter id: The ID of the solve to delete
    public func deleteSolve(id: UUID) {
        savedSolves.removeAll { $0.id == id }
        persistSolves()
    }
    
    /// Clear all saved solves
    public func clearAll() {
        savedSolves.removeAll()
        persistSolves()
    }
    
    /// Get recent solves limited to a specific count
    /// - Parameter count: Maximum number of solves to return
    /// - Returns: Array of recent solves
    public func getRecentSolves(count: Int) -> [SavedSolve] {
        return Array(savedSolves.prefix(count))
    }
    
    /// Get statistics about solve history
    /// - Returns: Tuple with total solves, average moves, and best solve
    public func getStatistics() -> (totalSolves: Int, averageMoves: Double, bestSolve: SavedSolve?) {
        let total = savedSolves.count
        let avgMoves = savedSolves.isEmpty ? 0 : Double(savedSolves.map { $0.moveCount }.reduce(0, +)) / Double(total)
        let best = savedSolves.min { $0.moveCount < $1.moveCount }
        return (total, avgMoves, best)
    }
    
    // MARK: - Private Methods
    
    /// Load solves from UserDefaults
    private func loadSolves() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([SavedSolve].self, from: data) else {
            savedSolves = []
            return
        }
        savedSolves = decoded
    }
    
    /// Persist solves to UserDefaults
    private func persistSolves() {
        guard let encoded = try? JSONEncoder().encode(savedSolves) else {
            print("Failed to encode saved solves")
            return
        }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
}
#endif
