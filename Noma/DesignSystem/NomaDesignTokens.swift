import SwiftUI

enum NomaMetric {
    typealias Value = CGFloat
}

enum NomaSpacing {
    static let xsm: NomaMetric.Value = 4
    static let sm: NomaMetric.Value = 8
    static let md: NomaMetric.Value = 12
    static let lg: NomaMetric.Value = 16
    static let xl: NomaMetric.Value = 32
    static let keyboardAccessoryOverlap: NomaMetric.Value = -20
}

enum NomaSize {
    static let scrollDismissSentinel: NomaMetric.Value = 1
    static let sendButton: NomaMetric.Value = 34
}

enum NomaRadius {
    static let composer: NomaMetric.Value = 25
}

enum NomaTiming {
    static let initialFocusDelay: UInt64 = 20_000_000
    static let controlFeedback = 0.2
}

enum NomaOpacity {
    static let disabledControlBackground = 0.18
}

enum NomaScale {
    static let pressedControl: CGFloat = 0.96
}

extension ShapeStyle where Self == Color {
    static var primaryBackground: Color { Color(.systemBackground) }
}
