import SwiftUI

struct CreateView: View {
    private let collapsedEdgePadding = NomaSpacing.xl
    private let focusedEdgePadding = NomaSpacing.md
    private let focusedKeyboardSpacing = NomaSpacing.keyboardAccessoryOverlap
    private let initialFocusDelay = NomaTiming.initialFocusDelay

    @State private var message = ""
    @State private var isKeyboardPresented = false
    @State private var isProjectSheetPresented = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                Color.clear
                    .frame(minHeight: proxy.size.height + NomaSize.scrollDismissSentinel)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background { Color(.systemBackground).ignoresSafeArea(.container) }
            .safeAreaBar(edge: .bottom, spacing: barSpacing) {
                composerBar
                    .frame(width: barWidth(in: proxy))
                    .padding(.bottom, barBottomPadding(in: proxy))
            }
        }
        .background {
            NavigationKeyboardDismissObserver(isInputFocused: $isInputFocused)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardPresented = false
        }
        .task {
            guard await Self.shouldApplyInitialFocus({
                try await Task.sleep(nanoseconds: initialFocusDelay)
            }) else { return }
            isInputFocused = true
        }
        .sheet(isPresented: $isProjectSheetPresented) {
            CreateSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var composerBar: some View {
        ReminderInputBar(
            text: $message,
            focus: $isInputFocused,
            placeholder: "create.input.placeholder",
            onTrayButtonTap: { isProjectSheetPresented = true },
            onSubmit: {}
        )
    }

    private var barSpacing: CGFloat { max(0, isKeyboardPresented ? focusedKeyboardSpacing : 0) }

    private func barWidth(in proxy: GeometryProxy) -> CGFloat {
        // Ensure we never return a negative or non-finite width
        let raw = proxy.size.width - (barEdgePadding * 2)
        let clamped = max(0, raw)
        if clamped.isFinite { return clamped }
        return 0
    }

    private func barBottomPadding(in proxy: GeometryProxy) -> CGFloat {
        let value = isKeyboardPresented ? focusedEdgePadding : max(0, collapsedEdgePadding - proxy.safeAreaInsets.bottom)
        let clamped = max(0, value)
        if clamped.isFinite { return clamped }
        return 0
    }

    private var barEdgePadding: CGFloat { isKeyboardPresented ? focusedEdgePadding : collapsedEdgePadding }
}
