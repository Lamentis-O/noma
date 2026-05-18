import SwiftUI

struct HomeTopBar: View {
    @Environment(SubscriptionTierManager.self) private var subscriptionTier

    var body: some View {
        HStack(spacing: NomaSpacing.sm) {
            Text("Noma")
                .font(Font.title)
                .fontWeight(.medium)

            subscriptionTierText
        }
        .padding(.top, NomaSpacing.sm)
    }

    @ViewBuilder
    private var subscriptionTierText: some View {
        let text = Text(LocalizedStringKey(subscriptionTier.tier.titleKey))
            .font(Font.title)
            .fontWeight(.medium)

        if subscriptionTier.tier.usesProminentTextGradient {
            text.foregroundStyle(NomaGradient.proTierText)
        } else {
            text.foregroundStyle(.secondary)
        }
    }
}

struct HomeSettingsMenu: View {
    @Environment(AuthStateManager.self) private var authState
    @Environment(SubscriptionTierManager.self) private var subscriptionTier

    var body: some View {
        Menu {
            #if DEBUG
            Toggle(isOn: debugProBinding) {
                Label(
                    "subscription.debug.pro.title",
                    systemImage: "sparkles"
                )
            }
            #endif

            Button(role: .destructive) {
                authState.signOut()
            } label: {
                Label(
                    "auth.logout.title",
                    systemImage: "rectangle.portrait.and.arrow.right"
                )
            }
        } label: {
            Image(systemName: "gearshape")
        }
    }

    #if DEBUG
    private var debugProBinding: Binding<Bool> {
        Binding {
            subscriptionTier.isPro
        } set: { isPro in
            subscriptionTier.updateTier(isPro ? .pro : .free)
        }
    }
    #endif
}
