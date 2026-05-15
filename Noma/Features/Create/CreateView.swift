import SwiftUI
import UIKit

struct CreateView: View {
    private let collapsedEdgePadding = NomaSpacing.xl
    private let focusedEdgePadding = NomaSpacing.md
    private let focusedKeyboardSpacing = NomaSpacing.keyboardAccessoryOverlap
    private let initialFocusDelay = NomaTiming.initialFocusDelay

    @State private var message = ""
    @State private var isKeyboardPresented = false
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
            try? await Task.sleep(nanoseconds: initialFocusDelay)
            isInputFocused = true
        }
    }

    private var composerBar: some View {
        ReminderInputBar(text: $message, focus: $isInputFocused, placeholder: "create.input.placeholder", onSubmit: {})
    }

    private var barSpacing: CGFloat { isKeyboardPresented ? focusedKeyboardSpacing : 0 }

    private func barWidth(in proxy: GeometryProxy) -> CGFloat {
        proxy.size.width - (barEdgePadding * 2)
    }

    private func barBottomPadding(in proxy: GeometryProxy) -> CGFloat {
        isKeyboardPresented ? focusedEdgePadding : max(0, collapsedEdgePadding - proxy.safeAreaInsets.bottom)
    }

    private var barEdgePadding: CGFloat { isKeyboardPresented ? focusedEdgePadding : collapsedEdgePadding }
}

private struct NavigationKeyboardDismissObserver: UIViewControllerRepresentable {
    let isInputFocused: FocusState<Bool>.Binding

    func makeUIViewController(context: Context) -> Controller { Controller(isInputFocused: isInputFocused) }
    func updateUIViewController(_ controller: Controller, context: Context) { controller.isInputFocused = isInputFocused }

    final class Controller: UIViewController {
        var isInputFocused: FocusState<Bool>.Binding

        init(isInputFocused: FocusState<Bool>.Binding) { self.isInputFocused = isInputFocused; super.init(nibName: nil, bundle: nil) }
        @available(*, unavailable)
        required init?(coder: NSCoder) { nil }
        override func loadView() { view = UIView(); view.backgroundColor = .clear }
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            let restoreFocus = isInputFocused.wrappedValue; isInputFocused.wrappedValue = false; view.window?.endEditing(true)
            guard restoreFocus, let transitionCoordinator else { return }
            transitionCoordinator.notifyWhenInteractionChanges { [weak self] context in
                if context.isCancelled { self?.isInputFocused.wrappedValue = true }
            }
        }
    }
}
