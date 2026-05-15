import SwiftUI
import UIKit

struct NavigationKeyboardDismissObserver: UIViewControllerRepresentable {
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
