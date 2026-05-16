import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionStateManager.self) private var subscriptionState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            heroCopy
            Spacer()
            actions
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private var heroCopy: some View {
        VStack(spacing: NomaSpacing.lg) {
            Text("subscription.paywall.title")
                .font(.title.bold()).multilineTextAlignment(.center).foregroundStyle(.primary)

            Text("subscription.paywall.subtitle")
                .font(.body).multilineTextAlignment(.center).foregroundStyle(.secondary)
        }
        .padding(.horizontal, NomaSpacing.xl)
    }

    private var actions: some View {
        VStack(spacing: NomaSpacing.md) {
            productButton
            restoreButton
        }
        .padding(.horizontal, NomaSpacing.xl)
        .padding(.bottom, NomaSpacing.xl)
    }

    @ViewBuilder
    private var productButton: some View {
        if let product = subscriptionState.availableProducts.first {
            Button {
                Task { await subscriptionState.purchase(product) }
            } label: {
                paywallProductLabel(for: product)
            }
            .disabled(subscriptionState.isPurchasing)
            .tint(.primary)
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
        } else {
            Text("subscription.paywall.unavailable")
                .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.secondary)
        }
    }

    private func paywallProductLabel(for product: SubscriptionProduct) -> some View {
        HStack {
            if subscriptionState.isPurchasing {
                ProgressView().tint(.primaryBackground).transition(.blurReplace)
            } else {
                Label(product.displayPrice, systemImage: "sparkles")
                    .transition(.blurReplace)
            }
        }
        .font(.headline)
        .foregroundStyle(.primaryBackground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, NomaSpacing.authButtonVertical)
    }

    private var restoreButton: some View {
        Button {
            Task { await subscriptionState.restorePurchases() }
        } label: {
            Text("subscription.paywall.restore")
                .font(.headline).frame(maxWidth: .infinity)
                .padding(.vertical, NomaSpacing.authButtonVertical)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}
