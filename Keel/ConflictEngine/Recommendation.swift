import Foundation

/// The engine's output for a colliding pair. `.tooClose` is a first-class
/// outcome (DESIGN.md §6.4) — never force a decided winner when signals don't
/// actually differentiate the two events.
enum Recommendation: Equatable {
    case decided(keep: UUID, move: UUID, reasoning: [String])
    case tooClose(reasoning: [String])

    var reasoning: [String] {
        switch self {
        case .decided(_, _, let reasoning): return reasoning
        case .tooClose(let reasoning): return reasoning
        }
    }

    var isDecided: Bool {
        if case .decided = self { return true }
        return false
    }
}

/// Whether two events collide, and how severely.
enum ConflictKind: Equatable {
    /// Literal time overlap.
    case hard
    /// Back-to-back with less than the buffer, but not literally overlapping.
    case soft
}
