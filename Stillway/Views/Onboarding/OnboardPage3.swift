import SwiftUI

struct OnboardPage3: View {
    var onBegin: () -> Void
    @Environment(\.lm) private var lm
    @Environment(ThemeEngine.self) private var theme

    var body: some View {
        ZStack {
            AtmosphereView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            RadialGradient(
                colors: [
                    theme.gradient.glowColor.opacity(0.55),
                    .clear,
                    .black.opacity(0.55)
                ],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 24) {
                Spacer()
                Text("STILLWAY")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.7))
                WaveformView()
                    .frame(height: UIScreen.main.bounds.height * 0.26)
                    .padding(.horizontal, 12)
                GradientText(
                    text: lm.string("onboard_3_title"),
                    colors: theme.gradient.waveColors
                )
                .font(.system(size: 34, weight: .light))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                Text(lm.string("onboard_3_body"))
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                PillButton(label: lm.string("onboard_3_btn"), action: onBegin)
                    .accessibilityIdentifier("OnboardBeginButton")
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            theme.setImmediate(.reset)
        }
    }
}
