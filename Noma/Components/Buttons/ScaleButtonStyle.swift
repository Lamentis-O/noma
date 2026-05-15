import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    var pressedScale = NomaScale.pressedControl
    var animation = Animation.smooth(duration: NomaTiming.controlFeedback)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(animation, value: configuration.isPressed)
    }
}
