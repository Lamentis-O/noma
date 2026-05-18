import SwiftUI

enum ProjectIconPickerSheetCopy {
    static let titleKey = "create.project.icon-picker.title"
    static let doneAccessibilityLabelKey = "create.project.icon-picker.done"
    static let colorAccessibilityLabelKey = "create.project.icon-picker.color.accessibility-label"
    static let selectedAccessibilityValueKey = "create.project.icon-picker.color.selected"

    static func colorAccessibilityLabel(for index: Int) -> String {
        let format = String(localized: String.LocalizationValue(colorAccessibilityLabelKey))
        return String.localizedStringWithFormat(format, index + 1)
    }
}

enum ProjectIconPickerSheetLayout {
    static let usesLargeDetent = true
    static let colorPickerUsesSafeAreaPadding = true
    static let iconGridUsesTopSafeAreaPadding = true
    static let colorOptionSize = NomaSize.projectColorOption
    static let selectedColorBorderWidth = NomaSize.projectColorSelectionBorder
    static let doneSystemImage = "checkmark"
}

enum ProjectIconPickerOption {
    static let defaultColorIndex = 0
    static let defaultSymbol = "folder"

    static let colors: [Color] = [
        .primary,
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple
    ]

    static let symbols = [
        "folder",
        "dollarsign.circle",
        "book.closed",
        "graduationcap",
        "pencil",
        "pencil.tip",
        "curlybraces",
        "terminal",
        "music.note",
        "popcorn",
        "paintbrush",
        "paintpalette",
        "stethoscope",
        "asterisk",
        "leaf",
        "briefcase",
        "chart.bar",
        "dumbbell",
        "calendar",
        "scalemass",
        "globe.europe.africa",
        "airplane",
        "globe",
        "wrench",
        "pawprint",
        "flask",
        "brain",
        "heart",
        "gift"
    ]

    static func normalizedColorIndex(_ index: Int) -> Int {
        colors.indices.contains(index) ? index : defaultColorIndex
    }

    static func color(for index: Int) -> Color {
        colors[normalizedColorIndex(index)]
    }
}

struct ProjectIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColorIndex: Int
    @Binding var selectedSymbol: String

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: NomaSpacing.xxl),
        count: 5
    )

    private var selectedColor: Color {
        ProjectIconPickerOption.color(for: selectedColorIndex)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: NomaSpacing.xl) {
                ProjectIconPreview(symbol: selectedSymbol, color: selectedColor)

                ProjectColorPicker(selectedColorIndex: $selectedColorIndex)

                Divider()

                ProjectIconGrid(
                    columns: columns,
                    selectedSymbol: $selectedSymbol,
                    selectedColor: selectedColor
                )
            }
            .padding(.top, NomaSpacing.xl)
            .navigationTitle(LocalizedStringKey(ProjectIconPickerSheetCopy.titleKey))
            .toolbarTitleDisplayMode(.inline)
            .toolbar { doneButton }
        }
    }

    private var doneButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: ProjectIconPickerSheetLayout.doneSystemImage)
            }
            .tint(.primary)
            .foregroundStyle(.primaryBackground)
            .buttonStyle(.glassProminent)
            .accessibilityLabel(Text(LocalizedStringKey(ProjectIconPickerSheetCopy.doneAccessibilityLabelKey)))
        }
    }
}
