import SwiftUI

struct OnboardPage1: View {
    var onContinue: () -> Void
    @Environment(\.lm) private var lm
    @Environment(ThemeEngine.self) private var theme

    var body: some View {
        ZStack {
            MeshBackgroundView().ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "waveform")
                    .font(.system(size: 96, weight: .light))
                    .foregroundStyle(theme.gradient.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
                Text(lm.string("onboard_1_title"))
                    .font(.system(size: 34, weight: .light))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text(lm.string("onboard_1_body"))
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                PillButton(label: lm.string("onboard_1_btn"), action: onContinue)
                    .accessibilityIdentifier("OnboardContinueButton")
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
            .padding(.top, 80)
        }
        .onAppear { theme.apply(context: .commute) }
    }
}
