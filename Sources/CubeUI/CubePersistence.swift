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
struct SavedSolve: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let initialState: CubeState
    let solution: [Move]
    let moveCount: Int
    let timeToSolve: TimeInterval?
    
    // Codable surrogate used for persistence so we don't require Move to conform to Codable
    struct Persisted: Codable {
        let id: UUID
        let date: Date
        let initialState: CubeState
        let solutionStrings: [String]
        let moveCount: Int
        let timeToSolve: TimeInterval?
    }
    
    init(
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

    // MARK: - Persistence (manual Codable bridge)
    init(from data: Data) throws {
        let decoder = JSONDecoder()
        let persisted = try decoder.decode(Persisted.self, from: data)
        self.id = persisted.id
        self.date = persisted.date
        self.initialState = persisted.initialState
        self.moveCount = persisted.moveCount
        self.timeToSolve = persisted.timeToSolve
        // Map strings back to Move; skip any that fail to parse
        self.solution = persisted.solutionStrings.compactMap { SavedSolve.move(from: $0) }
    }

    func encoded() throws -> Data {
        let persisted = Persisted(
            id: id,
            date: date,
            initialState: initialState,
            solutionStrings: solution.map { SavedSolve.string(from: $0) },
            moveCount: moveCount,
            timeToSolve: timeToSolve
        )
        let encoder = JSONEncoder()
        return try encoder.encode(persisted)
    }

    // MARK: - Move <-> String helpers
    static func string(from move: Move) -> String {
        // Prefer rawValue if available via CustomStringConvertible or a known property; fallback to `"\(move)"`.
        return String(describing: move)
    }

    static func move(from string: String) -> Move? {
        // If CubeCore exposes an initializer from string, use it here.
        // TODO: Implement actual parsing from string to Move according to CubeCore API.
        return nil as Move?
    }
}

/// Manager for persisting and retrieving solve history
@MainActor
class SolveHistoryManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of saved solves, most recent first
    @Published private(set) var savedSolves: [SavedSolve] = []
    
    // MARK: - Storage
    
    private let userDefaultsKey = "com.cubesolver.savedSolves"
    private let maxSavedSolves = 100
    
    // MARK: - Initialization
    
    init() {
        loadSolves()
    }
    
    // MARK: - Public Methods
    
    /// Save a new solve to history
    /// - Parameter solve: The solve to save
    func saveSolve(_ solve: SavedSolve) {
        savedSolves.insert(solve, at: 0)
        
        // Limit the number of saved solves
        if savedSolves.count > maxSavedSolves {
            savedSolves.removeLast(savedSolves.count - maxSavedSolves)
        }
        
        persistSolves()
    }
    
    /// Delete a solve from history
    /// - Parameter id: The ID of the solve to delete
    func deleteSolve(id: UUID) {
        savedSolves.removeAll { $0.id == id }
        persistSolves()
    }
    
    /// Clear all saved solves
    func clearAll() {
        savedSolves.removeAll()
        persistSolves()
    }
    
    /// Get recent solves limited to a specific count
    /// - Parameter count: Maximum number of solves to return
    /// - Returns: Array of recent solves
    func getRecentSolves(count: Int) -> [SavedSolve] {
        return Array(savedSolves.prefix(count))
    }
    
    /// Get statistics about solve history
    /// - Returns: Tuple with total solves, average moves, and best solve
    func getStatistics() -> (totalSolves: Int, averageMoves: Double, bestSolve: SavedSolve?) {
        let total = savedSolves.count
        let avgMoves = savedSolves.isEmpty ? 0 : Double(savedSolves.map { $0.moveCount }.reduce(0, +)) / Double(total)
        let best = savedSolves.min { $0.moveCount < $1.moveCount }
        return (total, avgMoves, best)
    }
    
    // MARK: - Private Methods
    
    /// Load solves from UserDefaults
    private func loadSolves() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            savedSolves = []
            return
        }
        do {
            // Decode as an array of Persisted
            let persistedArray = try JSONDecoder().decode([SavedSolve.Persisted].self, from: data)
            self.savedSolves = persistedArray.map { (persisted: SavedSolve.Persisted) in
                let solutionMoves: [Move] = persisted.solutionStrings.compactMap { (s: String) -> Move? in
                    SavedSolve.move(from: s)
                }
                return SavedSolve(
                    id: persisted.id,
                    date: persisted.date,
                    initialState: persisted.initialState,
                    solution: solutionMoves,
                    moveCount: persisted.moveCount,
                    timeToSolve: persisted.timeToSolve
                )
            }
        } catch {
            print("Failed to decode saved solves: \(error)")
            savedSolves = []
        }
    }
    
    /// Persist solves to UserDefaults
    private func persistSolves() {
        let persistedArray: [SavedSolve.Persisted] = savedSolves.map { solve in
            SavedSolve.Persisted(
                id: solve.id,
                date: solve.date,
                initialState: solve.initialState,
                solutionStrings: solve.solution.map { SavedSolve.string(from: $0) },
                moveCount: solve.moveCount,
                timeToSolve: solve.timeToSolve
            )
        }
        guard let encoded = try? JSONEncoder().encode(persistedArray) else {
            print("Failed to encode saved solves")
            return
        }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
}
#endif

