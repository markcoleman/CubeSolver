#if canImport(SwiftUI)

import SwiftUI
import CubeCore

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public struct SolveStepsView: View {
    @ObservedObject private var viewModel: CubeScanSolveFlowViewModel

    public init(viewModel: CubeScanSolveFlowViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 16) {
            if let instruction = viewModel.currentInstruction {
                VStack(spacing: 8) {
                    Text(instruction.headline)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                    Text(instruction.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(instruction.progressText)
                        .font(.caption.monospacedDigit())
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            HStack(spacing: 12) {
                Button("Back", systemImage: "chevron.left") {
                    viewModel.previousMove()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.currentMoveIndex <= 1)

                Button("Next", systemImage: "chevron.right") {
                    viewModel.nextMove()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.currentMoveIndex >= viewModel.solvedMoves.count)
            }

            List {
                ForEach(Array(viewModel.solvedMoves.enumerated()), id: \.offset) { item in
                    let rowIndex = item.offset + 1
                    HStack {
                        Text("\(rowIndex).")
                            .font(.caption.monospacedDigit())
                            .frame(width: 34, alignment: .trailing)
                            .foregroundStyle(.secondary)

                        Text(item.element.notation)
                            .font(.body.monospaced())

                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.jumpToMove(rowIndex)
                    }
                    .listRowBackground(
                        rowIndex == viewModel.currentMoveIndex ? Color.accentColor.opacity(0.16) : Color.clear
                    )
                }
            }
            .listStyle(.plain)

            HStack(spacing: 12) {
                Button("Copy Solution", systemImage: "doc.on.doc") {
                    copyToClipboard(viewModel.solutionText)
                }
                .buttonStyle(.bordered)

                Button("Restart", systemImage: "arrow.counterclockwise") {
                    viewModel.restart()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Solve Steps")
    }

    private func copyToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
}

#endif
