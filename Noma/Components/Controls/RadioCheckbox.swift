import SwiftUI

struct RadioCheckboxState: Equatable {
    let isOn: Bool

    var showsInnerCircle: Bool { isOn }
}

enum RadioCheckboxLayout {
    static let outerDiameter = NomaSize.radioCheckboxOuter
    static let innerDiameter = NomaSize.radioCheckboxInner
    static let borderWidth = NomaSize.radioCheckboxBorder
    static let firstLineCenterOffset = NomaSize.radioCheckboxFirstLineOffset
}

struct RadioCheckbox: View {
    let state: RadioCheckboxState
    let borderColor: Color
    let fillColor: Color

    init(
        isOn: Bool,
        borderColor: Color = .primary,
        fillColor: Color = .primary
    ) {
        self.state = RadioCheckboxState(isOn: isOn)
        self.borderColor = borderColor
        self.fillColor = fillColor
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(borderColor, lineWidth: RadioCheckboxLayout.borderWidth)
                .frame(
                    width: RadioCheckboxLayout.outerDiameter,
                    height: RadioCheckboxLayout.outerDiameter
                )

            if state.showsInnerCircle {
                Circle()
                    .fill(fillColor)
                    .frame(
                        width: RadioCheckboxLayout.innerDiameter,
                        height: RadioCheckboxLayout.innerDiameter
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(
            width: RadioCheckboxLayout.outerDiameter,
            height: RadioCheckboxLayout.outerDiameter
        )
    }
}
