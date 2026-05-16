import SwiftUI

enum ReminderInputBarLayout {
    static let minimumHeight = NomaSize.sendButton + NomaSpacing.sm + NomaSpacing.sm
}

struct ReminderInputBar: View {
    private let cornerRadius = NomaRadius.composer
    private let sendButtonSize = NomaSize.sendButton

    @Namespace private var glassNamespace
    @State private var inputHeight: CGFloat = 0
    @Binding var text: String

    let focus: FocusState<Bool>.Binding
    let placeholder: LocalizedStringKey
    let onTrayButtonTap: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: NomaSpacing.sm) {
            HStack(alignment: .bottom, spacing: NomaSpacing.sm) {
                Button(action: onTrayButtonTap) {
                    Image(systemName: "tray.full")
                        .font(.headline)
                        .frame(width: trayButtonHeight, height: trayButtonHeight)
                }
                .buttonStyle(.plain)
                .frame(width: trayButtonHeight, height: trayButtonHeight)
                .contentShape(Circle())
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel(Text("create.tray.accessibility-label"))
                .accessibilityIdentifier("create-reminder-tray-button")

                ZStack(alignment: .bottomTrailing) {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .focused(focus)
                        .font(.body)
                        .lineLimit(1...5)
                        .textFieldStyle(.plain)
                        .submitLabel(.return)
                        .frame(minHeight: sendButtonSize, alignment: .center)
                        .padding(.leading, NomaSpacing.lg)
                        .padding(.vertical, NomaSpacing.sm)
                        .padding(.trailing, sendButtonSize + NomaSpacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(Text(placeholder))
                        .accessibilityIdentifier("create-reminder-input")

                    ReminderSendButton(isActive: hasText, action: onSubmit)
                        .padding(.trailing, NomaSpacing.sm)
                        .padding(.bottom, NomaSpacing.sm)
                }
                .frame(maxWidth: .infinity)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { inputHeight = $0 }
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .onTapGesture {
                    focus.wrappedValue = true
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
                .glassEffectID("reminder-input-bar", in: glassNamespace)
                .glassEffectTransition(.matchedGeometry)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var minimumInputHeight: CGFloat { ReminderInputBarLayout.minimumHeight }
    private var trayButtonHeight: CGFloat { minimumInputHeight }
    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

private struct ReminderSendButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: NomaSize.sendButton, height: NomaSize.sendButton)
                .background { Circle().fill(background) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("create.send.accessibility-label"))
        .animation(.smooth(duration: NomaTiming.controlFeedback), value: isActive)
    }

    private var background: Color {
        isActive ? Color(.label) : .secondary.opacity(NomaOpacity.disabledControlBackground)
    }
}
