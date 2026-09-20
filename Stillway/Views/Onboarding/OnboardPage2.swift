import SwiftUI

struct OnboardPage2: View {
    var onContinue: () -> Void
    var onSkip: () -> Void
    @Environment(\.lm) private var lm
    @Environment(ThemeEngine.self) private var theme

    var body: some View {
        ZStack {
            MeshBackgroundView().ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Text("STILLWAY")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 16) {
                    Image(systemName: "airpodspro")
                    Image(systemName: "arrow.right")
                    Image(systemName: "waveform")
                }
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(theme.gradient.accentColor)
                .symbolEffect(.variableColor.iterative, options: .repeating)
                Text(lm.string("onboard_2_title"))
                    .font(.system(size: 34, weight: .light))
                    .multilineTextAlignment(.center)
                Text(lm.string("onboard_2_body"))
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                PillButton(label: lm.string("onboard_2_btn"), action: onContinue)
                    .accessibilityIdentifier("OnboardContinueButton")
                    .padding(.horizontal, 24)
                Button(lm.string("onboard_2_skip"), action: onSkip)
                    .accessibilityIdentifier("OnboardSkipButton")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, 48)
            }
            .padding(.top, 80)
        }
        .onAppear { theme.apply(context: .focus) }
    }
}
