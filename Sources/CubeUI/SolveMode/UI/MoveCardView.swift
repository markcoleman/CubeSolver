#if canImport(SwiftUI)

import SwiftUI

public struct MoveCardView: View {
    let instruction: MoveInstruction?
    let isSolved: Bool

    public init(instruction: MoveInstruction?, isSolved: Bool) {
        self.instruction = instruction
        self.isSolved = isSolved
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isSolved {
                Label("Solved!", systemImage: "checkmark.seal.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.green)
                Text("All moves applied. Nice work.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let instruction {
                Text(instruction.title)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .monospacedDigit()

                Text(instruction.spokenInstruction)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let hint = instruction.hint {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Already solved")
                    .font(.title2.weight(.bold))
                Text("No moves are required for this cube state.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

#endif
