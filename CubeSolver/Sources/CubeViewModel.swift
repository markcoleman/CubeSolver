//
//  CubeViewModel.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import Foundation
import SwiftUI

class CubeViewModel: ObservableObject {
    @Published var cube: RubiksCube
    @Published var solutionSteps: [String] = []
    
    init() {
        self.cube = RubiksCube()
    }
    
    func scramble() {
        let scrambleSequence = CubeSolver.scramble(moves: 20)
        CubeSolver.applyScramble(cube: &cube, scramble: scrambleSequence)
        solutionSteps = []
        objectWillChange.send()
    }
    
    func solve() {
        solutionSteps = CubeSolver.solve(cube: &cube)
        objectWillChange.send()
    }
    
    func reset() {
        cube = RubiksCube()
        solutionSteps = []
        objectWillChange.send()
    }
}
