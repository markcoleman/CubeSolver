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
#if canImport(OSLog)
import OSLog
#endif

/// Represents a saved solve session
struct SavedSolve: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let initialState: CubeState
    let solution: [Move]
    let moveCount: Int
    let timeToSolve: TimeInterval?
    
    // Codable surrogate that stores moves as notation strings for stable persistence.
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
        move.notation
    }

    static func move(from string: String) -> Move? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let move = Move(notation: trimmed) {
            return move
        }

        if let move = Move(notation: trimmed.uppercased()) {
            return move
        }

        // Backward compatibility for older persisted values that used `String(describing:)`.
        return parseLegacyMoveDescription(trimmed)
    }

    private static func parseLegacyMoveDescription(_ string: String) -> Move? {
        let normalized = string.replacingOccurrences(of: " ", with: "").lowercased()
        guard normalized.contains("move(") else { return nil }

        let turn = Turn.allCases.first { turn in
            let value = turn.rawValue.lowercased()
            return normalized.contains("turn:\(value)") ||
                normalized.contains("turn:turn.\(value)") ||
                normalized.contains("turn:cubecore.turn.\(value)") ||
                normalized.contains("turn=\(value)") ||
                normalized.contains("turn=turn.\(value)") ||
                normalized.contains("turn=cubecore.turn.\(value)")
        }
        guard let turn else { return nil }

        let amount: Amount
        if normalized.contains("amount:clockwise") ||
            normalized.contains("amount:amount.clockwise") ||
            normalized.contains("amount:cubecore.amount.clockwise") ||
            normalized.contains("amount=clockwise") ||
            normalized.contains("amount=amount.clockwise") ||
            normalized.contains("amount=cubecore.amount.clockwise") {
            amount = .clockwise
        } else if normalized.contains("amount:counter") ||
                    normalized.contains("amount:amount.counter") ||
                    normalized.contains("amount:cubecore.amount.counter") ||
                    normalized.contains("amount=counter") ||
                    normalized.contains("amount=amount.counter") ||
                    normalized.contains("amount=cubecore.amount.counter") {
            amount = .counter
        } else if normalized.contains("amount:double") ||
                    normalized.contains("amount:amount.double") ||
                    normalized.contains("amount:cubecore.amount.double") ||
                    normalized.contains("amount=double") ||
                    normalized.contains("amount=amount.double") ||
                    normalized.contains("amount=cubecore.amount.double") {
            amount = .double
        } else {
            return nil
        }

        return Move(turn: turn, amount: amount)
    }
}

/// Manager for persisting and retrieving solve history
@MainActor
final class SolveHistoryManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of saved solves, most recent first
    @Published private(set) var savedSolves: [SavedSolve] = []
    
    // MARK: - Storage
    
    private let userDefaultsKey = "com.cubesolver.savedSolves"
    private let maxSavedSolves = 100
    #if canImport(OSLog)
    private let logger = Logger(subsystem: "com.cubesolver.ui", category: "SolveHistory")
    #endif
    
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
            var droppedMoveCount = 0

            self.savedSolves = persistedArray.map { (persisted: SavedSolve.Persisted) in
                var solutionMoves: [Move] = []
                solutionMoves.reserveCapacity(persisted.solutionStrings.count)

                for serializedMove in persisted.solutionStrings {
                    if let move = SavedSolve.move(from: serializedMove) {
                        solutionMoves.append(move)
                    } else {
                        droppedMoveCount += 1
                    }
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

            if droppedMoveCount > 0 {
                logWarning("Dropped \(droppedMoveCount) invalid persisted moves during decode")
            }
        } catch {
            logError("Failed to decode saved solves: \(error.localizedDescription)")
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
            logError("Failed to encode saved solves")
            return
        }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }

    private func logWarning(_ message: String) {
        #if canImport(OSLog)
        logger.warning("\(message, privacy: .public)")
        #else
        print("WARNING: \(message)")
        #endif
    }

    private func logError(_ message: String) {
        #if canImport(OSLog)
        logger.error("\(message, privacy: .public)")
        #else
        print("ERROR: \(message)")
        #endif
    }
}
#endif
