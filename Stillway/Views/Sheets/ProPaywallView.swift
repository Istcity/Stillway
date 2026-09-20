import SwiftUI
import StoreKit

struct ProPaywallView: View {
    @Environment(PurchaseManager.self) private var store
    @Environment(ThemeEngine.self) private var theme
    @Environment(\.lm) private var lm
    @Environment(\.openURL) private var openURL

    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var alertMessage = ""

    private let termsURL = URL(string: "https://istcity.github.io/Stillway/terms.html")!
    private let privacyURL = URL(string: "https://istcity.github.io/Stillway/privacy.html")!

    var body: some View {
        ZStack {
            AtmosphereView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            RadialGradient(
                colors: [
                    theme.gradient.glowColor.opacity(0.45),
                    Color.black.opacity(0.85),
                    Color.black
                ],
                center: .top,
                startRadius: 20,
                endRadius: 600
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header Badge
                    VStack(spacing: 6) {
                        Text("STILLWAY")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .tracking(6)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 16)

                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                            Text(lm.string("paywall_badge"))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                        }
                        .accessibilityIdentifier("PaywallBadge")
                        .foregroundStyle(Color(red: 0.95, green: 0.78, blue: 0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.95, green: 0.78, blue: 0.45).opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 0.95, green: 0.78, blue: 0.45).opacity(0.35), lineWidth: 1)
                                )
                        )
                    }

                    // Dynamic Waveform Visual
                    WaveformView()
                        .frame(height: 58)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)

                    // Hero Hook Title
                    VStack(spacing: 8) {
                        GradientText(
                            text: lm.string("paywall_hook_title"),
                            colors: [
                                .white,
                                Color(red: 0.95, green: 0.85, blue: 0.7),
                                theme.gradient.glowColor
                            ]
                        )
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                        Text(lm.string("paywall_hook_subtitle"))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }

                    // Feature Cards (Editorial Layout)
                    VStack(spacing: 8) {
                        featureRow(icon: "waveform.badge.magnifyingglass", titleKey: "settings_pro_feature_1")
                        featureRow(icon: "slider.horizontal.2.square", titleKey: "settings_pro_feature_2")
                        featureRow(icon: "tram.fill", titleKey: "settings_pro_feature_3")
                        featureRow(icon: "mappin.and.ellipse", titleKey: "settings_pro_feature_4")
                        featureRow(icon: "brain.head.profile", titleKey: "settings_pro_feature_5")
                        featureRow(icon: "moon.stars.fill", titleKey: "settings_pro_feature_6")
                    }
                    .padding(.horizontal, 22)

                    // Call to Action Box
                    VStack(spacing: 12) {
                        Button {
                            handlePurchase()
                        } label: {
                            HStack(spacing: 10) {
                                if store.isLoading || isPurchasing {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text(ctaButtonText)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.86, blue: 0.62),
                                        Color(red: 0.92, green: 0.72, blue: 0.38)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundStyle(Color.black)
                            .clipShape(Capsule())
                            .shadow(color: Color(red: 0.95, green: 0.78, blue: 0.45).opacity(0.35), radius: 14, y: 4)
                        }
                        .accessibilityIdentifier("PaywallPurchaseButton")
                        .disabled(store.isLoading || isPurchasing)

                        // Guarantee tag
                        Text(lm.string("paywall_guarantee"))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))

                        // Restore Purchases Button
                        Button {
                            handleRestore()
                        } label: {
                            Text(lm.string("settings_restore"))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .underline(false)
                        }
                        .accessibilityIdentifier("PaywallRestoreButton")
                        .padding(.top, 4)

                        // Legal & Compliance Links (Mandatory for App Store)
                        HStack(spacing: 18) {
                            Button(lm.string("paywall_terms")) {
                                openURL(termsURL)
                            }
                            .accessibilityIdentifier("PaywallTermsButton")

                            Text("•")
                                .foregroundStyle(.white.opacity(0.3))

                            Button(lm.string("settings_privacy")) {
                                openURL(privacyURL)
                            }
                            .accessibilityIdentifier("PaywallPrivacyButton")
                        }
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text(lm.string("pro_error")),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var ctaButtonText: String {
        let localizedPrice: String
        switch lm.currentLanguage {
        case .tr:
            localizedPrice = "999 TL"
        case .ja:
            localizedPrice = "¥3,000"
        default:
            localizedPrice = "$19.99"
        }

        if let product = store.proProduct, !ProcessInfo.processInfo.arguments.contains("-forcePaywall") {
            return String(format: lm.string("paywall_cta_price"), product.displayPrice)
        } else {
            return String(format: lm.string("paywall_cta_price"), localizedPrice)
        }
    }

    private func featureRow(icon: String, titleKey: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.95, green: 0.8, blue: 0.5))
            }

            Text(lm.string(titleKey))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6.5)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func handlePurchase() {
        HapticEngine.tap()
        isPurchasing = true
        Task {
            await store.purchase()
            isPurchasing = false
            if store.isPro {
                HapticEngine.success()
            } else if let err = store.errorMessage {
                alertMessage = err
                showingError = true
            }
        }
    }

    private func handleRestore() {
        HapticEngine.tap()
        isPurchasing = true
        Task {
            await store.restorePurchases()
            isPurchasing = false
            if store.isPro {
                HapticEngine.success()
            } else if let err = store.errorMessage {
                alertMessage = err
                showingError = true
            } else {
                alertMessage = lm.string("pro_error")
                showingError = true
            }
        }
    }
}
