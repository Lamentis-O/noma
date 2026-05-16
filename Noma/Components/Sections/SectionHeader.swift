import SwiftUI

enum SectionHeaderLayout {
    static let bottomPadding = NomaSpacing.buttonHorizontal
}

enum SectionHeaderTextFormatting {
    static func titleCased(_ text: String) -> String {
        text.localizedCapitalized
    }
}

enum SectionHeaderTextStyle: Equatable {
    case headline
}

enum SectionHeaderColorSource: Equatable {
    case primary
    case custom
}

enum SectionHeaderAlignment: Equatable {
    case leading
}

struct SectionHeaderConfiguration: Equatable {
    let text: String
    let textStyle: SectionHeaderTextStyle = .headline
    let colorSource: SectionHeaderColorSource
    let alignment: SectionHeaderAlignment = .leading

    init(
        text: String,
        colorSource: SectionHeaderColorSource = .primary
    ) {
        self.text = text
        self.colorSource = colorSource
    }
}

struct SectionHeader: View {
    private let configuration: SectionHeaderConfiguration
    private let color: Color

    init(_ text: String, color: Color? = nil) {
        self.configuration = SectionHeaderConfiguration(
            text: text,
            colorSource: color == nil ? .primary : .custom
        )
        self.color = color ?? Color.primary
    }

    var body: some View {
        Text(displayText)
            .font(.headline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, SectionHeaderLayout.bottomPadding)
    }

    private var displayText: String {
        let localizedText = String(localized: String.LocalizationValue(configuration.text))
        return SectionHeaderTextFormatting.titleCased(localizedText)
    }
}
