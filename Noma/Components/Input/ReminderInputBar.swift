import SwiftUI

enum ReminderInputBarLayout {
    static let minimumHeight = NomaSize.sendButton + NomaSpacing.sm + NomaSpacing.sm
}

enum ReminderSendButtonTone: Equatable {
    case active
    case disabled
    case error
}

struct ReminderInputState: Equatable {
    let text: String
    var isSubmissionAvailable = true

    var isOverLimit: Bool {
        text.count > CreateReminderSubmission.characterLimit
    }

    var hasSubmitText: Bool {
        !CreateReminderSubmission.normalizedText(from: text).isEmpty
    }

    var canSubmit: Bool {
        hasSubmitText && !isOverLimit && isSubmissionAvailable
    }

    var sendButtonTone: ReminderSendButtonTone {
        if isOverLimit {
            return .error
        }

        return canSubmit ? .active : .disabled
    }
}

struct ReminderInputStaleTextGuard: Equatable {
    private var submittedTextToIgnore: String?

    mutating func prepareForSubmit(text: String) {
        submittedTextToIgnore = text.isEmpty ? nil : text
    }

    mutating func acceptsIncomingText(_ incomingText: String) -> Bool {
        guard let submittedTextToIgnore else { return true }
        if incomingText == submittedTextToIgnore { return false }
        self.submittedTextToIgnore = nil
        return true
    }
}

struct ReminderInputDraftState: Equatable {
    var staleTextGuard = ReminderInputStaleTextGuard()

    mutating func prepareForSubmit(text: String) {
        staleTextGuard.prepareForSubmit(text: text)
    }

    mutating func acceptsIncomingText(_ incomingText: String) -> Bool {
        staleTextGuard.acceptsIncomingText(incomingText)
    }
}

private struct ReminderSendButton: View {
    let state: ReminderInputState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primaryBackground)
                .frame(width: NomaSize.sendButton, height: NomaSize.sendButton)
                .background { Circle().fill(background) }
        }
        .buttonStyle(.plain)
        .disabled(!state.canSubmit)
        .accessibilityLabel(Text("create.send.accessibility-label"))
        .animation(.smooth(duration: NomaTiming.controlFeedback), value: state)
    }

    private var background: Color {
        switch state.sendButtonTone {
        case .active:
            .controlActive
        case .disabled:
            .textSecondary.opacity(NomaOpacity.disabledControlBackground)
        case .error:
            .controlError
        }
    }
}

private struct ReminderTrayButton: View {
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "tray.full").font(.headline).frame(width: height, height: height)
        }
        .buttonStyle(.plain)
        .frame(width: height, height: height)
        .contentShape(Circle())
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(Text("create.tray.accessibility-label"))
        .accessibilityIdentifier("create-reminder-tray-button")
    }
}

private struct ReminderTextInput: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    let focus: FocusState<Bool>.Binding
    let sendButtonSize: CGFloat

    var body: some View {
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
    }
}

struct ReminderInputBar: View {
    private let cornerRadius = NomaRadius.composer
    private let sendButtonSize = NomaSize.sendButton

    @Namespace private var glassNamespace
    @State private var inputHeight: CGFloat = 0
    @State private var draftState = ReminderInputDraftState()
    @Binding var text: String

    let focus: FocusState<Bool>.Binding
    let placeholder: LocalizedStringKey
    let isSubmissionAvailable: Bool
    let onTrayButtonTap: () -> Void
    let onSubmit: (String) -> Void

    init(
        text: Binding<String>,
        focus: FocusState<Bool>.Binding,
        placeholder: LocalizedStringKey,
        isSubmissionAvailable: Bool = true,
        onTrayButtonTap: @escaping () -> Void,
        onSubmit: @escaping (String) -> Void
    ) {
        self._text = text
        self.focus = focus
        self.placeholder = placeholder
        self.isSubmissionAvailable = isSubmissionAvailable
        self.onTrayButtonTap = onTrayButtonTap
        self.onSubmit = onSubmit
    }

    var body: some View {
        GlassEffectContainer(spacing: NomaSpacing.sm) {
            HStack(alignment: .bottom, spacing: NomaSpacing.sm) {
                ReminderTrayButton(height: trayButtonHeight, action: onTrayButtonTap)

                ZStack(alignment: .bottomTrailing) {
                    ReminderTextInput(
                        placeholder: placeholder,
                        text: inputText,
                        focus: focus,
                        sendButtonSize: sendButtonSize
                    )

                    ReminderSendButton(state: inputState, action: submitCurrentText)
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
}

private extension ReminderInputBar {
    private var minimumInputHeight: CGFloat { ReminderInputBarLayout.minimumHeight }
    private var trayButtonHeight: CGFloat { minimumInputHeight }
    private var inputState: ReminderInputState {
        ReminderInputState(text: text, isSubmissionAvailable: isSubmissionAvailable)
    }

    private var inputText: Binding<String> {
        Binding(
            get: { text },
            set: { incomingText in
                guard draftState.acceptsIncomingText(incomingText) else { return }
                text = incomingText
            }
        )
    }

    private func submitCurrentText() {
        guard inputState.canSubmit else { return }
        let submittedText = text
        draftState.prepareForSubmit(text: submittedText)
        text = ""
        onSubmit(submittedText)
    }
}
