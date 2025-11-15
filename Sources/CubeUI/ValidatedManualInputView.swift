#if canImport(SwiftUI)
//
//  ValidatedManualInputView.swift
//  CubeSolver
//
//  Enhanced manual input view with validation feedback
//

import SwiftUI
import CubeCore

/// View for manually inputting a cube configuration with validation
public struct ValidatedManualInputView: View {
    @ObservedObject var cubeViewModel: CubeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFace: CubeFaceType = .front
    @State private var selectedColor: FaceColor = .red
    @State private var validationError: String?
    @State private var showValidationAlert = false
    @State private var isValid = true
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching main view
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.15, blue: 0.3)
                    ]),
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
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("manualInputTitle")
                        
                        // Validation status
                        ValidationStatusCard(isValid: isValid, errorMessage: validationError)
                            .padding(.horizontal)
                        
                        // Instructions
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Instructions")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("1. Select a face to edit")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("2. Choose a color")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("3. Tap cells to set colors")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("4. Validate before solving")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
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
                                .foregroundColor(.white)
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
                        
                        // Color picker with eyedropper
                        VStack(spacing: 15) {
                            Text("Select Color")
                                .font(.headline)
                                .foregroundColor(.white)
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
                        .onChange(of: cubeViewModel.cube) { _, _ in
                            validateCube()
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("editableFaceView")
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                GlassmorphicButton(title: "Validate", icon: "checkmark.shield") {
                                    validateCube()
                                    showValidationAlert = true
                                }
                                .accessibilityIdentifier("validateButton")
                                .accessibilityHint("Validates the current cube configuration")
                                
                                GlassmorphicButton(title: "Reset Face", icon: "arrow.counterclockwise") {
                                    resetFace(selectedFace)
                                }
                                .accessibilityIdentifier("resetFaceButton")
                                .accessibilityHint("Resets the selected face to its original state")
                            }
                            
                            GlassmorphicButton(title: "Done", icon: "checkmark") {
                                if validateCube() {
                                    dismiss()
                                } else {
                                    showValidationAlert = true
                                }
                            }
                            .accessibilityIdentifier("doneButton")
                            .accessibilityHint("Validates and closes the manual input view")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .accessibilityIdentifier("closeButton")
                }
            }
            .alert("Validation Result", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(isValid ? "Cube configuration is valid!" : (validationError ?? "Unknown error"))
            }
        }
        .onAppear {
            validateCube()
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
        validateCube()
    }
    
    @discardableResult
    private func validateCube() -> Bool {
        // Convert current cube to CubeState
        let cubeState = CubeState(from: cubeViewModel.cube)
        
        do {
            // Validate the cube state
            try CubeValidator.validate(cubeState)
            isValid = true
            validationError = nil
            return true
        } catch let error as CubeValidationError {
            isValid = false
            validationError = error.errorDescription
            return false
        } catch {
            isValid = false
            validationError = "Unknown validation error"
            return false
        }
    }
}

/// Card displaying validation status
public struct ValidationStatusCard: View {
    let isValid: Bool
    let errorMessage: String?
    
    public var body: some View {
        if let error = errorMessage {
            GlassmorphicCard {
                HStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Invalid Configuration")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Validation error: \(error)")
        } else if isValid {
            GlassmorphicCard {
                HStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("Valid Configuration")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Cube configuration is valid")
        }
    }
}

#Preview {
    ValidatedManualInputView(cubeViewModel: CubeViewModel())
}
#endif
