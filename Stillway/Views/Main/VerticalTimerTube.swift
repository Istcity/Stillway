import SwiftUI

/// Living metaphorical vertical timer tube.
/// - Su Saati (Reset / Doğa): Realistic falling water droplets, liquid meniscus with ripples, rising micro-bubbles.
/// - Kum Saati (Focus / Odak): Cascading golden sand grains streaming down the central axis, accumulating into a curved sand dune mound.
/// - Güneş Saati (Walking / Yürüyüş): Sundial logic - clean steady solar light fill (sabit artış) with glowing crest, rotating sun icon.
/// - Ay Saati (Sleep / Uyku): Lunar clock logic - clean steady nocturnal lunar light fill (sabit artış) with gentle lunar crest, moon icon.
/// - Zaman / Ray (Commute / Diğer): Clean steady ambient gradient fill (sabit artış) with clock icon.
///
/// Motion is tuned to be deeply calm and ultra-slow for meditation.
/// Only water and sand have particle physics; all others feature steady proportional rise.
struct VerticalTimerTube: View {
    var progress: Double // 0.0 (just started) to 1.0 (finished)
    var remainingSeconds: Int
    var isPlaying: Bool
    var context: AppContext? = nil
    var hideTopIcon: Bool = false
    var onSelectMinutes: (Int?) -> Void

    @Environment(ThemeEngine.self) private var theme
    @Environment(\.lm) private var lm
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showPicker = false

    private var effectiveContext: AppContext {
        context ?? theme.currentContext
    }

    private var accent: Color { theme.gradient.accentColor }
    private var glow: Color { theme.gradient.glowColor }

    private var displayMinutes: String {
        let m = max(1, remainingSeconds / 60)
        return "\(m)\(lm.string("timer_min"))"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Main vertical tube column
            VStack(spacing: 8) {
                // Top living metaphorical icon (hidden in landscape for pure clock mode)
                if !hideTopIcon {
                    topLivingIcon
                        .id(effectiveContext)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 28, height: 28)
                        .shadow(color: accent.opacity(0.65), radius: 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }

                // Living vertical glass tube
                ZStack(alignment: .bottom) {
                    // Outer glass track chamber
                    Capsule()
                        .fill(Color.black.opacity(0.40))
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.38), Color.white.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )

                    // Living animated contents (strictly top-to-bottom, proportional filling)
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height

                        // Su ve kum saati için taban havuzu (~%4), diğer sabit artışlı saatler için tam doğrusal oran
                        let normProg = max(0.0, min(1.0, progress))
                        let isParticleClock = (effectiveContext == .reset || effectiveContext == .focus || effectiveContext == .deepWork)
                        let fillRatio = isParticleClock ? (0.04 + (normProg * 0.96)) : normProg
                        let fillHeight = h * CGFloat(fillRatio)

                        TimelineView(.periodic(from: .now, by: reduceMotion ? 1.0 : 1.0 / 30.0)) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate

                            Canvas { context, size in
                                drawLivingTube(
                                    context: &context,
                                    size: size,
                                    fillHeight: fillHeight,
                                    t: t,
                                    isPlaying: isPlaying,
                                    accent: accent,
                                    glow: glow
                                )
                            }
                        }
                    }
                    .clipShape(Capsule())

                    // Glass tube specular reflection (vertical left highlight line)
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.50), Color.clear, Color.white.opacity(0.18)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 0.9
                        )
                }
                .frame(width: 22, height: 124)

                // Remaining time label under the tube
                Text(displayMinutes)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.65), radius: 3, x: 0, y: 1)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial.opacity(0.35), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            .contentShape(Rectangle())
            .onTapGesture {
                HapticEngine.tap()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    showPicker.toggle()
                }
            }

            // Expanded timer picker popover menu
            if showPicker {
                VStack(spacing: 8) {
                    pickerPill(label: "15 \(lm.string("timer_min"))", minutes: 15)
                    pickerPill(label: "25 \(lm.string("timer_min"))", minutes: 25)
                    pickerPill(label: "30 \(lm.string("timer_min"))", minutes: 30)
                    pickerPill(label: "45 \(lm.string("timer_min"))", minutes: 45)
                    pickerPill(label: "∞", minutes: nil)
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                )
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
    }

    // MARK: - Top Living Metaphorical Icon
    // Su Saati -> Damla, Kum Saati -> Kum Saati, Güneş Saati -> Güneş, Ay Saati -> Hilal, Zaman -> Saat

    @ViewBuilder
    private var topLivingIcon: some View {
        switch effectiveContext {
        case .focus, .deepWork:
            // KUM SAATİ (Focus): Kum akışı, sakin nabız darbesi
            Image(systemName: "hourglass")
                .symbolEffect(.pulse, options: .repeating, isActive: isPlaying)

        case .walking:
            // GÜNEŞ SAATİ (Walking): Güneş saati mantığıyla çok yavaş göksel dönüş
            TimelineView(.periodic(from: .now, by: 1.0 / 24.0)) { timeline in
                let angle = timeline.date.timeIntervalSinceReferenceDate * (isPlaying ? 5.0 : 2.5)
                Image(systemName: "sun.max.fill")
                    .rotationEffect(.degrees(angle))
            }

        case .reset:
            // SU SAATİ (Reset / Doğa): Salınan su damlası
            Image(systemName: "drop.fill")
                .symbolEffect(.bounce, options: .repeating, isActive: isPlaying)

        case .sleep:
            // AY SAATİ (Sleep): Gece hilali
            Image(systemName: "moon.fill")

        case .commute:
            // ZAMAN (Commute): Saat ikonu
            Image(systemName: "clock.fill")

        case .unknown:
            Image(systemName: "hourglass")
        }
    }

    // MARK: - Living Tube Drawing Engine
    // Sadece Su Saati ve Kum Saati'nde yukarıdan aşağıya süzülen parçacık grafikleri bulunur.
    // Güneş, Ay ve Zaman saatlerinde parçacık grafikleri iptal edilmiştir; güneş saati mantığıyla sabit doğrusal artış kullanılır.

    private func drawLivingTube(
        context: inout GraphicsContext,
        size: CGSize,
        fillHeight: CGFloat,
        t: Double,
        isPlaying: Bool,
        accent: Color,
        glow: Color
    ) {
        let w = size.width
        let h = size.height
        let currentFill = min(h, max(0.0, fillHeight))
        let surfaceY = max(0.0, h - currentFill)
        let speedMult = isPlaying ? 1.0 : 0.65

        switch effectiveContext {
        case .reset:
            // =========================================================================
            // 1. SU SAATİ (Water Clepsydra):
            // - Tüpün üstünden su seviyesine doğru aşağıya çok yavaş süzülen gerçek su damlaları.
            // - Su yüzeyinde menisküs dalgalanması.
            // - Suyun içinde yukarı yükselen mikro hava kabarcıkları.
            // =========================================================================

            // A. Alt Su Sütunu (Translucent water reservoir, filling proportionally)
            let waterRect = CGRect(x: 0, y: surfaceY, width: w, height: currentFill)
            context.fill(
                Path(roundedRect: waterRect, cornerRadius: 5),
                with: .linearGradient(
                    Gradient(colors: [
                        accent.opacity(0.95),
                        glow.opacity(0.85),
                        Color(hex: 0x004466)
                    ]),
                    startPoint: CGPoint(x: w * 0.5, y: surfaceY),
                    endPoint: CGPoint(x: w * 0.5, y: h)
                )
            )

            // B. Su Yüzeyi Menisküsü ve Çarpma Dalgalanması (Çok yavaş ve yumuşak salınım)
            let ripple = sin(t * 1.8 * speedMult) * 1.2
            var surfCtx = context
            surfCtx.addFilter(.blur(radius: 0.8))
            surfCtx.fill(
                Path(ellipseIn: CGRect(x: 1, y: surfaceY - 2.0 + ripple, width: w - 2, height: 4.5)),
                with: .color(Color.white.opacity(0.92))
            )

            // C. Tüpün Üstünden Su Seviyesine Doğru Çok Yavaş Süzülen Gerçek Su Damlaları
            if surfaceY > 8 {
                let dropCount = 2
                for i in 0..<dropCount {
                    let seed = Double(i) * 0.50
                    let prog = (t * 0.22 * speedMult + seed).truncatingRemainder(dividingBy: 1.0)
                    let dropY = pow(prog, 1.4) * surfaceY

                    let dropW: CGFloat = 4.8
                    let dropH: CGFloat = 7.0
                    let dropX = w * 0.5

                    if dropY < surfaceY + 2 {
                        var dropPath = Path()
                        dropPath.move(to: CGPoint(x: dropX, y: dropY - dropH * 0.5))
                        dropPath.addQuadCurve(
                            to: CGPoint(x: dropX + dropW * 0.5, y: dropY + dropH * 0.15),
                            control: CGPoint(x: dropX + dropW * 0.5, y: dropY - dropH * 0.15)
                        )
                        dropPath.addArc(
                            center: CGPoint(x: dropX, y: dropY + dropH * 0.15),
                            radius: dropW * 0.5,
                            startAngle: .degrees(0),
                            endAngle: .degrees(180),
                            clockwise: false
                        )
                        dropPath.addQuadCurve(
                            to: CGPoint(x: dropX, y: dropY - dropH * 0.5),
                            control: CGPoint(x: dropX - dropW * 0.5, y: dropY - dropH * 0.15)
                        )
                        dropPath.closeSubpath()

                        var dropCtx = context
                        dropCtx.addFilter(.blur(radius: 0.3))
                        dropCtx.fill(dropPath, with: .color(Color.white.opacity(0.96)))

                        dropCtx.fill(
                            Path(ellipseIn: CGRect(x: dropX - 1.2, y: dropY - 1.0, width: 2.4, height: 2.8)),
                            with: .color(Color(hex: 0x80D8FF))
                        )
                    }
                }
            }

            // D. Suyun İçinde Çok Yavaş Yükselen Mikro Hava Kabarcıkları
            for b in 0..<4 {
                let bSeed = Double(b) * 1.35
                let bProg = (t * 0.12 * speedMult + bSeed).truncatingRemainder(dividingBy: 1.0)
                let bY = h - CGFloat(bProg) * currentFill
                let bX = w * 0.5 + CGFloat(sin(t * 1.2 + bSeed)) * (w * 0.25)
                let r: CGFloat = 1.5

                if bY > surfaceY {
                    context.fill(
                        Path(ellipseIn: CGRect(x: bX - r, y: bY - r, width: r * 2, height: r * 2)),
                        with: .color(Color.white.opacity(0.78))
                    )
                    context.stroke(
                        Path(ellipseIn: CGRect(x: bX - r, y: bY - r, width: r * 2, height: r * 2)),
                        with: .color(Color.white.opacity(0.95)),
                        lineWidth: 0.5
                    )
                }
            }

        case .focus, .deepWork:
            // =========================================================================
            // 2. KUM SAATİ (Sand Hourglass):
            // - Tüpün merkez ekseninde yukarıdan aşağıya çok yavaş süzülen altın rengi kum taneleri.
            // - Altta biriken kavisli kum tepesi.
            // =========================================================================

            // A. Altta Biriken Altın Kum Sütunu (Süreyle orantılı yükselir)
            let sandRect = CGRect(x: 0, y: surfaceY, width: w, height: currentFill)
            context.fill(
                Path(roundedRect: sandRect, cornerRadius: 4),
                with: .linearGradient(
                    Gradient(colors: [
                        accent.opacity(0.98),
                        Color(hex: 0xFFB300),
                        Color(hex: 0xE65100)
                    ]),
                    startPoint: CGPoint(x: w * 0.5, y: surfaceY),
                    endPoint: CGPoint(x: w * 0.5, y: h)
                )
            )

            // B. Altta Biriken Kum Tepesi (Kavisli Kumul Menisküsü)
            var dunePath = Path()
            dunePath.move(to: CGPoint(x: 1, y: surfaceY + 2))
            dunePath.addQuadCurve(
                to: CGPoint(x: w - 1, y: surfaceY + 2),
                control: CGPoint(x: w * 0.5, y: max(0, surfaceY - 5.0))
            )
            dunePath.addLine(to: CGPoint(x: w - 1, y: surfaceY + 5))
            dunePath.addLine(to: CGPoint(x: 1, y: surfaceY + 5))
            dunePath.closeSubpath()

            var duneCtx = context
            duneCtx.addFilter(.blur(radius: 0.4))
            duneCtx.fill(dunePath, with: .color(Color(hex: 0xFFE082).opacity(0.95)))

            // C. Merkez Ekseninde Çok Yavaş ve Hipnotik Süzülen Altın Kum Taneleri
            if surfaceY > 8 {
                let grainCount = 8
                for g in 0..<grainCount {
                    let gSeed = Double(g) / Double(grainCount)
                    let prog = (t * 0.30 * speedMult + gSeed).truncatingRemainder(dividingBy: 1.0)
                    let grainY = pow(prog, 1.3) * (surfaceY - 2.0)
                    let jitterX = w * 0.5 + CGFloat(sin(t * 3.5 + Double(g) * 2.8)) * 1.8

                    let grainR: CGFloat = (g % 3 == 0) ? 2.0 : 1.5
                    var grainCtx = context
                    grainCtx.addFilter(.blur(radius: 0.2))

                    let grainColor = (g % 2 == 0) ? Color.white : Color(hex: 0xFFD54F)
                    grainCtx.fill(
                        Path(ellipseIn: CGRect(x: jitterX - grainR, y: grainY - grainR, width: grainR * 2, height: grainR * 2)),
                        with: .color(grainColor)
                    )

                    var trailPath = Path()
                    trailPath.move(to: CGPoint(x: jitterX, y: max(0, grainY - 3.0)))
                    trailPath.addLine(to: CGPoint(x: jitterX, y: grainY))
                    context.stroke(trailPath, with: .color(Color(hex: 0xFFE082).opacity(0.40)), lineWidth: 0.7)
                }
            }

        case .walking:
            // =========================================================================
            // 3. GÜNEŞ SAATİ (Sundial Logic):
            // Parçacık grafiği YOK. Güneş saati mantığıyla sıcak ışığın süreyle sabit artışı.
            // =========================================================================

            if currentFill > 0 {
                // A. Güneş Işığı Sütunu (Süreyle orantılı sabit artış)
                let sunRect = CGRect(x: 0, y: surfaceY, width: w, height: currentFill)
                context.fill(
                    Path(roundedRect: sunRect, cornerRadius: 4),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: 0xFFF9C4), // Parlak güneş tepesi
                            accent.opacity(0.98),  // Sıcak kehribar güneş ışığı
                            Color(hex: 0xFF6F00)   // Derin günbatımı temeli
                        ]),
                        startPoint: CGPoint(x: w * 0.5, y: surfaceY),
                        endPoint: CGPoint(x: w * 0.5, y: h)
                    )
                )

                // B. Güneş Saati Işık Menisküsü (Süre yüzeyinde parlayan güneş tacı)
                var sunCrestCtx = context
                sunCrestCtx.addFilter(.blur(radius: 1.0))
                sunCrestCtx.fill(
                    Path(ellipseIn: CGRect(x: 1, y: surfaceY - 2.0, width: w - 2, height: 4.0)),
                    with: .color(Color.white.opacity(0.95))
                )
            }

        case .sleep:
            // =========================================================================
            // 4. AY SAATİ (Lunar Clock Logic):
            // Parçacık grafiği YOK. Güneş saatiyle aynı mantıkta dingin ay ışığının sabit artışı.
            // =========================================================================

            if currentFill > 0 {
                // A. Ay Işığı Sütunu (Süreyle orantılı sabit artış)
                let moonRect = CGRect(x: 0, y: surfaceY, width: w, height: currentFill)
                context.fill(
                    Path(roundedRect: moonRect, cornerRadius: 4),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: 0xE1BEE7), // Ay ışığı ışıltısı
                            accent.opacity(0.95),  // Gece leylağı
                            Color(hex: 0x1A0836)   // Derin gece moru
                        ]),
                        startPoint: CGPoint(x: w * 0.5, y: surfaceY),
                        endPoint: CGPoint(x: w * 0.5, y: h)
                    )
                )

                // B. Ay Işığı Menisküsü (Süre yüzeyinde yumuşak ay hilali ışıltısı)
                var moonCrestCtx = context
                moonCrestCtx.addFilter(.blur(radius: 1.0))
                moonCrestCtx.fill(
                    Path(ellipseIn: CGRect(x: 1, y: surfaceY - 2.0, width: w - 2, height: 4.0)),
                    with: .color(Color.white.opacity(0.90))
                )
            }

        default:
            // =========================================================================
            // 5. ZAMAN / RAY (Commute / Default):
            // Parçacık grafiği YOK. Süreyle orantılı temiz sabit artış.
            // =========================================================================

            if currentFill > 0 {
                let defRect = CGRect(x: 0, y: surfaceY, width: w, height: currentFill)
                context.fill(
                    Path(roundedRect: defRect, cornerRadius: 4),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: 0xB9F6CA),
                            accent.opacity(0.95),
                            Color(hex: 0x002B1B)
                        ]),
                        startPoint: CGPoint(x: w * 0.5, y: surfaceY),
                        endPoint: CGPoint(x: w * 0.5, y: h)
                    )
                )

                var defCrestCtx = context
                defCrestCtx.addFilter(.blur(radius: 1.0))
                defCrestCtx.fill(
                    Path(ellipseIn: CGRect(x: 1, y: surfaceY - 2.0, width: w - 2, height: 4.0)),
                    with: .color(Color.white.opacity(0.90))
                )
            }
        }
    }

    // MARK: - Picker Pill Item
    private func pickerPill(label: String, minutes: Int?) -> some View {
        Button {
            HapticEngine.select()
            onSelectMinutes(minutes)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showPicker = false
            }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 58, height: 32)
                .background(Color.white.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
