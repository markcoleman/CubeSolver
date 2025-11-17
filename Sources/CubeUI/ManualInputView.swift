#if canImport(SwiftUI)
//
//  ManualInputView.swift
//  CubeSolver
//
//  Created by GitHub Copilot
//

import SwiftUI
import CubeCore

/// View for manually inputting a cube configuration from a real-life cube
public struct ManualInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var cubeViewModel: CubeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFace: CubeFaceType = .front
    @State private var selectedColor: FaceColor = .red
    @State private var showingSolutionPlayback = false
    @State private var validationError: String?
    @State private var isSolving = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching main view
                LinearGradient(
                    gradient: Gradient(colors: CubeSolverColors.backgroundGradient(for: colorScheme)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)
                
                ScrollView {
                    VStack(spacing: 30) {
                        Text("Input Your Cube")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("manualInputTitle")
                        
                        // Instructions
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Instructions")
                                    .font(.headline)
                                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                
                                Text("1. Select a face to edit")
                                    .font(.body)
                                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                
                                Text("2. Choose a color")
                                    .font(.body)
                                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                
                                Text("3. Tap cells to set colors")
                                    .font(.body)
                                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Instructions for inputting cube configuration")
                        
                        // Face selector
                        VStack(spacing: 15) {
                            Text("Select Face")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                .accessibilityAddTraits(.isHeader)
                            
                            HStack(spacing: 10) {
                                ForEach(CubeFaceType.allCases, id: \.self) { faceType in
                                    FaceSelectorButton(
                                        faceType: faceType,
                                        isSelected: selectedFace == faceType
                                    ) {
                                        selectedFace = faceType
                                    }
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("faceSelector")
                        
                        // Color picker
                        VStack(spacing: 15) {
                            Text("Select Color")
                                .font(.headline)
                                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                .accessibilityAddTraits(.isHeader)
                            
                            HStack(spacing: 10) {
                                ForEach(FaceColor.allCases, id: \.self) { color in
                                    ColorSelectorButton(
                                        color: color,
                                        isSelected: selectedColor == color
                                    ) {
                                        selectedColor = color
                                    }
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("colorSelector")
                        
                        // Editable face
                        EditableCubeFaceView(
                            face: binding(for: selectedFace),
                            selectedColor: $selectedColor
                        )
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("editableFaceView")
                        
                        // Validation error message
                        if let error = validationError {
                            GlassmorphicCard {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                GlassmorphicButton(title: "Reset Face", icon: "arrow.counterclockwise") {
                                    resetFace(selectedFace)
                                }
                                .accessibilityIdentifier("resetFaceButton")
                                .accessibilityHint("Resets the selected face to its original state")
                                
                                GlassmorphicButton(title: "Done", icon: "checkmark") {
                                    dismiss()
                                }
                                .accessibilityIdentifier("doneButton")
                                .accessibilityHint("Closes the manual input view")
                            }
                            
                            // Solve button
                            GlassmorphicButton(
                                title: isSolving ? "Solving..." : "Solve Cube",
                                icon: "wand.and.stars"
                            ) {
                                Task {
                                    await solveCube()
                                }
                            }
                            .disabled(isSolving)
                            .accessibilityIdentifier("solveCubeButton")
                            .accessibilityHint("Validates and solves the current cube configuration")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                    .accessibilityIdentifier("closeButton")
                }
            }
            .sheet(isPresented: $showingSolutionPlayback) {
                SolutionPlaybackView(
                    cubeViewModel: cubeViewModel,
                    initialState: CubeState(from: cubeViewModel.cube)
                )
            }
        }
    }
    
    private func solveCube() async {
        isSolving = true
        validationError = nil
        
        // Validate the cube first
        let cubeState = CubeState(from: cubeViewModel.cube)
        
        do {
            // Basic validation
            try CubeValidator.validate(cubeState)
            
            // Try to solve
            await cubeViewModel.solveAsync()
            
            // If we got here, solving succeeded
            await MainActor.run {
                isSolving = false
                showingSolutionPlayback = true
            }
        } catch {
            await MainActor.run {
                validationError = error.localizedDescription
                isSolving = false
            }
        }
    }
    
    private func binding(for faceType: CubeFaceType) -> Binding<CubeFace> {
        switch faceType {
        case .front:
            return $cubeViewModel.cube.front
        case .back:
            return $cubeViewModel.cube.back
        case .left:
            return $cubeViewModel.cube.left
        case .right:
            return $cubeViewModel.cube.right
        case .top:
            return $cubeViewModel.cube.top
        case .bottom:
            return $cubeViewModel.cube.bottom
        }
    }
    
    private func resetFace(_ faceType: CubeFaceType) {
        switch faceType {
        case .front:
            cubeViewModel.cube.front = CubeFace(color: .red)
        case .back:
            cubeViewModel.cube.back = CubeFace(color: .orange)
        case .left:
            cubeViewModel.cube.left = CubeFace(color: .green)
        case .right:
            cubeViewModel.cube.right = CubeFace(color: .blue)
        case .top:
            cubeViewModel.cube.top = CubeFace(color: .white)
        case .bottom:
            cubeViewModel.cube.bottom = CubeFace(color: .yellow)
        }
    }
}

/// Enumeration for cube face types
public enum CubeFaceType: String, CaseIterable {
    case front = "Front"
    case back = "Back"
    case left = "Left"
    case right = "Right"
    case top = "Top"
    case bottom = "Bottom"
    
    var icon: String {
        switch self {
        case .front: return "f.square"
        case .back: return "b.square"
        case .left: return "l.square"
        case .right: return "r.square"
        case .top: return "u.square"
        case .bottom: return "d.square"
        }
    }
}

/// Button for selecting a cube face
public struct FaceSelectorButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let faceType: CubeFaceType
    let isSelected: Bool
    let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: faceType.icon)
                    .font(.title2)
                Text(faceType.rawValue)
                    .font(.caption)
            }
            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? CubeSolverColors.cardBackground(for: colorScheme).opacity(1.5) : CubeSolverColors.cardBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? CubeSolverColors.glassBorder(for: colorScheme).opacity(2) : CubeSolverColors.glassBorder(for: colorScheme), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .backdrop(cornerRadius: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(faceType.rawValue) face")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Button for selecting a color
public struct ColorSelectorButton: View {
    let color: FaceColor
    let isSelected: Bool
    let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            Circle()
                .fill(colorForFaceColor(color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.rawValue) color")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("\(color.rawValue)ColorButton")
    }
    
    private func colorForFaceColor(_ faceColor: FaceColor) -> Color {
        switch faceColor {
        case .white: return Color.white
        case .yellow: return Color.yellow
        case .red: return Color.red
        case .orange: return Color.orange
        case .blue: return Color.blue
        case .green: return Color.green
        }
    }
}

/// Editable cube face view
public struct EditableCubeFaceView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var face: CubeFace
    @Binding var selectedColor: FaceColor
    
    public var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { col in
                        Button(action: {
                            face.colors[row][col] = selectedColor
                        }) {
                            Rectangle()
                                .fill(colorForFaceColor(face.colors[row][col]))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(color: CubeSolverColors.shadow(for: colorScheme), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Cell row \(row + 1), column \(col + 1)")
                        .accessibilityValue("\(face.colors[row][col].rawValue) color")
                        .accessibilityHint("Tap to set to selected color")
                        .accessibilityIdentifier("cell_\(row)_\(col)")
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.3))
        )
    }
    
    private func colorForFaceColor(_ faceColor: FaceColor) -> Color {
        switch faceColor {
        case .white: return Color.white
        case .yellow: return Color.yellow
        case .red: return Color.red
        case .orange: return Color.orange
        case .blue: return Color.blue
        case .green: return Color.green
        }
    }
}

#Preview {
    ManualInputView(cubeViewModel: CubeViewModel())
}
#endif

