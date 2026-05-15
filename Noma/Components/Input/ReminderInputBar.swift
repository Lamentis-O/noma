import SwiftUI

struct ReminderInputBar: View {
    private let cornerRadius = NomaRadius.composer
    private let sendButtonSize = NomaSize.sendButton

    @Namespace private var glassNamespace
    @Binding var text: String

    let focus: FocusState<Bool>.Binding
    let placeholder: LocalizedStringKey
    let onSubmit: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 0) {
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
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onTapGesture {
                focus.wrappedValue = true
            }
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            .glassEffectID("reminder-input-bar", in: glassNamespace)
            .glassEffectTransition(.matchedGeometry)
        }
        .frame(maxWidth: .infinity)
    }

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
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
