import SwiftUI

enum SectionHeaderLayout {
    static let bottomPadding = NomaSpacing.xl
}

enum SectionHeaderTextFormatting {
    static func titleCased(_ text: String) -> String {
        text.localizedCapitalized
    }
}

struct SectionHeader: View {
    private let text: String
    private let color: Color?

    init(_ text: String, color: Color? = nil) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(displayText)
            .font(.headline)
            .foregroundStyle(color ?? .textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, SectionHeaderLayout.bottomPadding)
    }

    private var displayText: String {
        let localizedText = String(localized: String.LocalizationValue(text))
        return SectionHeaderTextFormatting.titleCased(localizedText)
    }
}
