import SwiftUI

struct HomeTopBar: View {
    @Environment(AuthStateManager.self) private var authState
    @Environment(SubscriptionTierManager.self) private var subscriptionTier

    var body: some View {
        HStack(spacing: NomaSpacing.sm) {
            Text("Noma")
                .font(Font.title2)
                .fontWeight(.medium)

            subscriptionTierText

            Spacer(minLength: 0)

            settingsMenu
        }
        .padding(.horizontal, NomaSpacing.lg)
        .padding(.leading, NomaSpacing.sm)
    }

    @ViewBuilder
    private var subscriptionTierText: some View {
        let text = Text(LocalizedStringKey(subscriptionTier.tier.titleKey))
            .font(Font.title2)
            .fontWeight(.medium)

        if subscriptionTier.tier.usesProminentTextGradient {
            text.foregroundStyle(NomaGradient.proTierText)
        } else {
            text.foregroundStyle(.secondary)
        }
    }

    private var settingsMenu: some View {
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
                .font(.title2)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
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
