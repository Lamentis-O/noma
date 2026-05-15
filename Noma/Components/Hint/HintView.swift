import SwiftUI

struct HintCTA {
    let title: LocalizedStringKey
    var color: Color = .primary
    let action: () -> Void
}

struct HintView: View {
    let systemImage: String?
    let title: LocalizedStringKey?
    let subtitle: LocalizedStringKey?
    let cta: HintCTA?

    init(
        systemImage: String? = nil,
        title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        cta: HintCTA? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.cta = cta
    }

    var body: some View {
        VStack(spacing: 0) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, systemImage == nil ? 0 : NomaSpacing.xl)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, title == nil ? 0 : NomaSpacing.lg)
            }

            if let cta {
                PrimaryButton(cta.title, color: cta.color, action: cta.action)
                    .padding(.top, hasContentBeforeCTA ? NomaSpacing.xl : 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var hasContentBeforeCTA: Bool {
        systemImage != nil || title != nil || subtitle != nil
    }
}
