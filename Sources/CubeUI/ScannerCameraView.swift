#if canImport(SwiftUI)
import SwiftUI

#if canImport(AVFoundation) && canImport(CubeScanner)
//
//  ScannerCameraView.swift
//  CubeSolver - Camera Scanner View
//
//  Created by GitHub Copilot
//

import AVFoundation
import CubeCore
import CubeScanner

/// Camera view for scanning Rubik's Cube faces
@MainActor
public struct ScannerCameraView: View {
    
    @StateObject private var scanner = CubeScanner()
    @State private var showManualCorrection = false
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Camera preview would go here
            Color.black
                .ignoresSafeArea()
            
            // 3x3 Grid Overlay
            GridOverlay()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 300, height: 300)
            
            VStack {
                Spacer()
                
                // Face selection and status
                VStack(spacing: 16) {
                    // Current face indicator
                    HStack(spacing: 12) {
                        ForEach([Face.front, Face.back, Face.left, Face.right, Face.up, Face.down], id: \.self) { face in
                            FaceIndicator(
                                face: face,
                                isActive: scanner.currentFace == face,
                                isScanned: scanner.scannedFaceCount > Face.allCases.firstIndex(of: face) ?? 6
                            )
                        }
                    }
                    
                    // Instructions
                    Text(instructionText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    
                    // Scan button
                    Button {
                        Task {
                            try? await scanner.startScanning(face: scanner.currentFace)
                        }
                    } label: {
                        HStack {
                            Image(systemName: scanner.scannerState == .scanning ? "stop.circle.fill" : "camera.fill")
                            Text(scanner.scannerState == .scanning ? "Stop" : "Scan")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(scanner.scannerState == .scanning ? Color.red : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(scanner.scannerState == .processing)
                    
                    // Accept/Retry buttons (shown after scan)
                    if scanner.scannerState == .completed || !scanner.getLowConfidenceStickers().isEmpty {
                        HStack(spacing: 12) {
                            Button {
                                showManualCorrection = true
                            } label: {
                                HStack {
                                    Image(systemName: "hand.point.up.fill")
                                    Text("Correct")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.orange)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                Task {
                                    await scanner.acceptScan()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Accept")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Progress indicator
                    ProgressView(value: Double(scanner.scannedFaceCount), total: 6)
                        .tint(.blue)
                    
                    Text("\(scanner.scannedFaceCount)/6 faces scanned")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding()
            }
        }
        .navigationTitle("Scan Cube")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        .sheet(isPresented: $showManualCorrection) {
            ManualCorrectionView(
                scanner: scanner,
                onComplete: {
                    showManualCorrection = false
                }
            )
        }
        .alert("Scan Complete", isPresented: .constant(scanner.scannedFaceCount == 6)) {
            Button("Solve") {
                // Navigate to solve view
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                scanner.reset()
            }
        } message: {
            Text("All faces scanned successfully!")
        }
    }
    
    private var instructionText: String {
        switch scanner.scannerState {
        case .idle:
            return "Position the \(scanner.currentFace.rawValue) face in the grid"
        case .scanning:
            return "Hold steady while scanning..."
        case .processing:
            return "Processing..."
        case .completed:
            return "Scan complete! Review or accept"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Supporting Views

struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Outer border
        path.addRect(rect)
        
        // Vertical lines
        let cellWidth = rect.width / 3
        path.move(to: CGPoint(x: cellWidth, y: 0))
        path.addLine(to: CGPoint(x: cellWidth, y: rect.height))
        path.move(to: CGPoint(x: cellWidth * 2, y: 0))
        path.addLine(to: CGPoint(x: cellWidth * 2, y: rect.height))
        
        // Horizontal lines
        let cellHeight = rect.height / 3
        path.move(to: CGPoint(x: 0, y: cellHeight))
        path.addLine(to: CGPoint(x: rect.width, y: cellHeight))
        path.move(to: CGPoint(x: 0, y: cellHeight * 2))
        path.addLine(to: CGPoint(x: rect.width, y: cellHeight * 2))
        
        return path
    }
}

struct FaceIndicator: View {
    let face: Face
    let isActive: Bool
    let isScanned: Bool
    
    public var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isScanned ? Color.green : (isActive ? Color.blue : Color.gray))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: isScanned ? "checkmark" : "cube")
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            Text(face.rawValue)
                .font(.caption2)
                .foregroundColor(isActive ? .white : .gray)
        }
    }
}

struct ManualCorrectionView: View {
    @ObservedObject var scanner: CubeScanner
    let onComplete: () -> Void
    
    @State private var corrections: [Int: CubeColor] = [:]
    
    public var body: some View {
        NavigationStack {
            VStack {
                Text("Low Confidence Stickers")
                    .font(.headline)
                    .padding()
                
                Text("Tap stickers below to correct their colors")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Grid showing low-confidence stickers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(scanner.getLowConfidenceStickers(), id: \.self) { index in
                        CorrectionCell(
                            index: index,
                            currentColor: corrections[index] ?? .white,
                            onSelect: { color in
                                corrections[index] = color
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
                
                Button("Apply Corrections") {
                    Task {
                        await scanner.acceptScan(with: corrections)
                        onComplete()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .cornerRadius(12)
                .padding()
            }
            .navigationTitle("Correct Colors")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete()
                    }
                }
            }
        }
    }
}

struct CorrectionCell: View {
    let index: Int
    let currentColor: CubeColor
    let onSelect: (CubeColor) -> Void
    
    @State private var showingPicker = false
    
    public var body: some View {
        Button {
            showingPicker = true
        } label: {
            VStack {
                Text("Sticker \(index + 1)")
                    .font(.caption2)
                
                Circle()
                    .fill(currentColor.swiftUIColor)
                    .frame(width: 40, height: 40)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .confirmationDialog("Select Color", isPresented: $showingPicker) {
            ForEach(CubeColor.allCases, id: \.self) { color in
                Button(color.rawValue) {
                    onSelect(color)
                }
            }
        }
    }
}

// MARK: - Color Extension

extension CubeColor {
    var swiftUIColor: Color {
        switch self {
        case .white: return .white
        case .yellow: return .yellow
        case .red: return .red
        case .orange: return .orange
        case .blue: return .blue
        case .green: return .green
        }
    }
}

#else

@MainActor
public struct ScannerCameraView: View {
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("Scanner Unavailable")
                .font(.headline)
            Text("The CubeScanner module isn't available in this build configuration.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
#endif

#endif
