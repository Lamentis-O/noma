import SwiftUI

struct HintCTA {
    let title: LocalizedStringKey
    var color: Color = .primary
    let action: () -> Void
}

enum HintViewLayout {
    static let horizontalPadding = NomaSpacing.xl
}

struct HintView: View {
    let systemImage: String?
    let title: LocalizedStringKey?
    let subtitle: LocalizedStringKey?
    let cta: HintCTA?
    let mirrorsSystemImageForRightToLeftLayoutDirection: Bool

    init(
        systemImage: String? = nil,
        title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        cta: HintCTA? = nil,
        mirrorsSystemImageForRightToLeftLayoutDirection: Bool = false
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.cta = cta
        self.mirrorsSystemImageForRightToLeftLayoutDirection = mirrorsSystemImageForRightToLeftLayoutDirection
    }

    var body: some View {
        VStack(spacing: 0) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title.weight(.bold))
                    .scaleEffect(NomaScale.hintIcon)
                    .foregroundStyle(.textSecondary)
                    .flipsForRightToLeftLayoutDirection(mirrorsSystemImageForRightToLeftLayoutDirection)
                    .frame(maxWidth: .infinity)
            }

            if let title {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, systemImage == nil ? 0 : NomaSpacing.xxl)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, title == nil ? 0 : NomaSpacing.sm)
            }

            if let cta {
                PrimaryButton(cta.title, color: cta.color, action: cta.action)
                    .padding(.top, hasContentBeforeCTA ? NomaSpacing.xxl : 0)
            }
        }
        .padding(.horizontal, HintViewLayout.horizontalPadding)
        .frame(maxWidth: .infinity)
    }

    private var hasContentBeforeCTA: Bool {
        systemImage != nil || title != nil || subtitle != nil
    }
}
