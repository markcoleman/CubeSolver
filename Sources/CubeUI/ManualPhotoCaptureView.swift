//
//  ManualPhotoCaptureView.swift
//  CubeSolver - Manual Photo Capture with Debug Menu
//
//  Created by GitHub Copilot
//

#if os(iOS)

import SwiftUI
import AVFoundation
import CubeCore
import CubeScanner

// MARK: - ManualPhotoCaptureView

/// A view for manually capturing a photo of a cube face and extracting sticker colors
public struct ManualPhotoCaptureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ManualPhotoCaptureViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: CubeSolverColors.backgroundGradient(for: colorScheme),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.capturedImage != nil {
                // Debug/Review mode - show captured photo with color overlay
                DebugReviewView(viewModel: viewModel)
            } else {
                // Capture mode - show camera preview
                CaptureView(viewModel: viewModel)
            }
        }
        .navigationTitle("Photo Capture")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    viewModel.stop()
                    dismiss()
                }
                .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
            }
        }
        .task {
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .alert("Camera Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Capture View (Camera Preview)

private struct CaptureView: View {
    @ObservedObject var viewModel: ManualPhotoCaptureViewModel
    
    var body: some View {
        ZStack {
            // Camera preview
            ManualCameraPreviewView(session: viewModel.cameraSession)
                .ignoresSafeArea()
            
            // 3x3 grid overlay for alignment
            AlignmentGridOverlay()
            
            // Bottom controls
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Instructions
                    Text("Align the cube face within the grid")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    
                    // Capture button
                    Button(action: {
                        Task {
                            await viewModel.capturePhoto()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .disabled(!viewModel.isReady)
                    .opacity(viewModel.isReady ? 1.0 : 0.5)
                    .accessibilityLabel("Capture photo")
                    .accessibilityHint("Takes a photo of the cube face")
                }
                .padding(.bottom, 40)
            }
            
            // Processing indicator
            if viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Processing...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }
}

// MARK: - Debug Review View

private struct DebugReviewView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: ManualPhotoCaptureViewModel
    @State private var isDebugExpanded = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Detected Colors")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                    .padding(.top, 20)
                
                // Captured image with color overlay
                if let image = viewModel.capturedImage {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                        
                        // Color grid overlay
                        ColorGridOverlay(colors: viewModel.detectedColors)
                            .opacity(0.7)
                    }
                    .frame(maxWidth: 350, maxHeight: 350)
                    .padding(.horizontal)
                }
                
                // Debug panel
                GlassmorphicCard {
                    VStack(alignment: .leading, spacing: 12) {
                        // Toggle header
                        Button(action: { withAnimation { isDebugExpanded.toggle() } }) {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                    .foregroundColor(.green)
                                
                                Text("Debug Info")
                                    .font(.headline)
                                    .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                                
                                Spacer()
                                
                                Image(systemName: isDebugExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if isDebugExpanded {
                            Divider()
                            
                            // Detected colors grid
                            Text("Detected Colors (tap to correct):")
                                .font(.subheadline)
                                .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                            
                            EditableColorGrid(
                                colors: $viewModel.detectedColors,
                                selectedCorrectionColor: viewModel.selectedCorrectionColor
                            ) { index in
                                viewModel.correctColor(at: index, to: viewModel.selectedCorrectionColor)
                            }
                            
                            // Color labels
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(0..<3, id: \.self) { row in
                                    HStack {
                                        ForEach(0..<3, id: \.self) { col in
                                            let index = row * 3 + col
                                            let color = viewModel.detectedColors[index]
                                            
                                            Text(color.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .frame(width: 30, height: 20)
                                                .background(color.swiftUIColor)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Color selection for correction
                GlassmorphicCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Color to Correct")
                            .font(.headline)
                            .foregroundColor(CubeSolverColors.primaryText(for: colorScheme))
                        
                        HStack(spacing: 12) {
                            ForEach(CubeColor.allCases, id: \.self) { color in
                                ColorCorrectionButton(
                                    color: color,
                                    isSelected: viewModel.selectedCorrectionColor == color
                                ) {
                                    viewModel.selectedCorrectionColor = color
                                }
                            }
                        }
                        
                        Text("Tap a cell above to apply selected color")
                            .font(.caption)
                            .foregroundColor(CubeSolverColors.secondaryText(for: colorScheme))
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 16) {
                    GlassmorphicButton(title: "Retake", icon: "camera.fill") {
                        viewModel.retakePhoto()
                    }
                    
                    GlassmorphicButton(title: "Use Colors", icon: "checkmark") {
                        viewModel.confirmColors()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Alignment Grid Overlay

private struct AlignmentGridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) * ManualPhotoCaptureViewModel.gridSizeFraction
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let startX = centerX - size / 2
            let startY = centerY - size / 2
            
            ZStack {
                // Outer frame
                Rectangle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 3)
                    .frame(width: size, height: size)
                    .position(x: centerX, y: centerY)
                
                // 3x3 grid lines
                ForEach(1..<3, id: \.self) { i in
                    // Vertical lines
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2, height: size)
                        .position(x: startX + size * CGFloat(i) / 3, y: centerY)
                    
                    // Horizontal lines
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: size, height: 2)
                        .position(x: centerX, y: startY + size * CGFloat(i) / 3)
                }
                
                // Corner markers
                ForEach(0..<4, id: \.self) { corner in
                    let x = startX + (corner % 2 == 0 ? 0 : size)
                    let y = startY + (corner < 2 ? 0 : size)
                    
                    SimpleCornerMarker()
                        .rotationEffect(.degrees(Double(corner) * 90))
                        .position(x: x, y: y)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SimpleCornerMarker: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.green, lineWidth: 3)
    }
}

// MARK: - Color Grid Overlay

private struct ColorGridOverlay: View {
    let colors: [CubeColor]
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(geometry.size.width, geometry.size.height) / 3
            
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            
                            Rectangle()
                                .fill(colors[index].swiftUIColor)
                                .frame(width: cellSize, height: cellSize)
                                .border(Color.black.opacity(0.3), width: 1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Editable Color Grid

private struct EditableColorGrid: View {
    @Binding var colors: [CubeColor]
    var selectedCorrectionColor: CubeColor = .white
    var onColorTap: ((Int) -> Void)?
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col
                        
                        Button(action: {
                            onColorTap?(index)
                        }) {
                            Rectangle()
                                .fill(colors[index].swiftUIColor)
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Cell row \(row + 1), column \(col + 1)")
                        .accessibilityValue("\(colors[index].rawValue) color")
                        .accessibilityHint("Tap to change to \(selectedCorrectionColor.rawValue)")
                    }
                }
            }
        }
    }
}

// MARK: - Color Correction Button

private struct ColorCorrectionButton: View {
    let color: CubeColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.swiftUIColor)
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
    }
}

// MARK: - Camera Preview UIView

private struct ManualCameraPreviewView: UIViewRepresentable {
    let session: CameraSession
    
    func makeUIView(context: Context) -> ManualCameraPreviewUIView {
        return ManualCameraPreviewUIView()
    }
    
    func updateUIView(_ uiView: ManualCameraPreviewUIView, context: Context) {
        uiView.previewLayer = session.getPreviewLayer()
    }
}

private class ManualCameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            if let old = oldValue {
                old.removeFromSuperlayer()
            }
            
            if let layer = previewLayer {
                layer.frame = bounds
                self.layer.addSublayer(layer)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

// MARK: - ViewModel

@MainActor
final class ManualPhotoCaptureViewModel: ObservableObject {
    // MARK: - Constants
    
    /// The size of the alignment grid as a fraction of the screen (0-1 range).
    /// The grid will be `gridSizeFraction * 100`% of the minimum screen dimension.
    static let gridSizeFraction: CGFloat = 0.7
    
    /// The normalized region where we assume the cube face is located.
    /// This is calculated from gridSizeFraction to ensure the visual grid matches
    /// the actual detection area.
    private static let defaultFaceDetectionRegion: CGRect = {
        let margin = (1.0 - gridSizeFraction) / 2.0
        return CGRect(x: margin, y: margin, width: gridSizeFraction, height: gridSizeFraction)
    }()
    
    // MARK: - Published Properties
    
    @Published var isReady = false
    @Published var isProcessing = false
    @Published var capturedImage: UIImage?
    @Published var detectedColors: [CubeColor] = Array(repeating: .white, count: 9)
    @Published var selectedCorrectionColor: CubeColor = .white
    @Published var showError = false
    @Published var errorMessage = ""
    
    // MARK: - Internal Properties
    
    let cameraSession = CameraSession()
    private let colorClassifier = ModernColorClassifier()
    private var capturedPixelBuffer: CVPixelBuffer?
    private var lastQualityScore: Float?
    
    // MARK: - Lifecycle
    
    func start() async {
        let authorized = await cameraSession.requestPermission()
        
        guard authorized else {
            errorMessage = "Camera access is required to capture cube faces."
            showError = true
            return
        }
        
        do {
            try await cameraSession.start()
            isReady = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func stop() {
        cameraSession.stop()
        isReady = false
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() async {
        guard let pixelBuffer = cameraSession.lastVideoFrame else {
            errorMessage = "No video frame available"
            showError = true
            return
        }
        
        isProcessing = true
        capturedPixelBuffer = pixelBuffer
        
        // Convert pixel buffer to UIImage on a background thread
        let image = await Task.detached { () -> UIImage? in
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                return UIImage(cgImage: cgImage)
            }
            return nil
        }.value
        
        capturedImage = image
        
        // Classify colors using the modern Vision + Core Image classifier
        // ModernColorClassifier uses CalculateImageAestheticsScoresRequest and CIFilter
        let result: ModernColorClassifier.ClassificationResult = await colorClassifier.classifyStickers(
            buffer: pixelBuffer,
            faceRect: Self.defaultFaceDetectionRegion
        )
        
        detectedColors = result.colors
        lastQualityScore = result.imageQualityScore
        
        #if DEBUG
        if let score = result.imageQualityScore {
            print("Image quality score: \(score), isUtility: \(result.isUtilityImage)")
        }
        #endif
        
        isProcessing = false
    }
    
    func retakePhoto() {
        capturedImage = nil
        capturedPixelBuffer = nil
        detectedColors = Array(repeating: .white, count: 9)
    }
    
    /// Confirms the detected (and possibly manually corrected) colors.
    ///
    /// This method is called when the user is satisfied with the detected colors
    /// and wants to use them. Currently it logs the colors for debugging purposes.
    /// Future implementations could:
    /// - Pass colors to a parent view via a callback or binding
    /// - Store colors in a shared session state
    /// - Navigate to the next face capture or solution view
    func confirmColors() {
        #if DEBUG
        let colorStrings = detectedColors.map { $0.rawValue }
        print("Confirmed colors: \(colorStrings)")
        #endif
    }
    
    func correctColor(at index: Int, to color: CubeColor) {
        guard index >= 0 && index < 9 else { return }
        detectedColors[index] = color
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ManualPhotoCaptureView()
    }
}

#endif
