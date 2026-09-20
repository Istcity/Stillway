import SwiftUI

/// World-class generative 3D atmospheric visual engine for Stillway.
///
/// Inspired by:
/// - Atmospheric & Weather Phenomena (Noctilucent clouds, polar auroras, oceanic mist, thermal convection)
/// - Light & Spatial Art (James Turrell skyspaces, teamLab bioluminescent projections, Mark Rothko color fields)
/// - Music & Acoustic Physics (Chladni cymatics resonance, harmonic wave interference, Brian Eno ambient generation)
/// - Modern Ambient Technology (VisionOS spatial volumetric gradients, Apple Music fluid audio responsive meshes)
///
/// Operates at a slow, meditative human breathing rhythm (12-30s cycles), producing an ultra-luxurious,
/// hypnotic ("içe alan"), soft, and living backdrop.
struct AtmosphereView: View {
    @Environment(ThemeEngine.self) private var theme
    @Environment(AudioEngine.self) private var audio
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fromKind: AtmosphereKind = .mist
    @State private var toKind: AtmosphereKind = .mist
    @State private var kindBlend: Double = 1

    private var targetKind: AtmosphereKind {
        AtmosphereKind.resolve(soundID: audio.primarySound?.id, context: theme.currentContext)
    }

    var body: some View {
        let colors = theme.gradient
        let playing = audio.isPlaying
        let blend = kindBlend

        // Meditative 24fps timeline (or 1fps on reduce motion)
        TimelineView(.periodic(from: .now, by: reduceMotion ? 1.0 : 1.0 / 24.0)) { timeline in
            let rawT = timeline.date.timeIntervalSinceReferenceDate
            // Deep meditative time dilation (breathing tempo ~16-30 second cycles)
            let t = rawT * 0.28
            let energy = playing ? 1.0 : 0.82

            Canvas { context, size in
                // 1. Deep atmospheric spatial backdrop with multi-point radial gradients
                drawAtmosphericBackdrop(context: &context, size: size, t: t, colors: colors, energy: energy)

                // 2. Active generative art mode with smooth cross-fade
                if fromKind != toKind, blend < 0.999 {
                    var outgoing = context
                    outgoing.opacity = 1 - blend
                    drawGenerativeMode(fromKind, context: &outgoing, size: size, t: t, colors: colors, energy: energy)

                    var incoming = context
                    incoming.opacity = blend
                    drawGenerativeMode(toKind, context: &incoming, size: size, t: t, colors: colors, energy: energy)
                } else {
                    var layer = context
                    drawGenerativeMode(toKind, context: &layer, size: size, t: t, colors: colors, energy: energy)
                }

                // 3. 3D Cosmic Stardust & Bioluminescent Micro-Particles (slow floating depth field)
                drawUniversalStardust(context: &context, size: size, t: t, colors: colors, energy: energy)
            }
        }
        .blur(radius: reduceMotion ? 0 : 0.6)
        .onAppear {
            fromKind = targetKind
            toKind = targetKind
            kindBlend = 1
        }
        .onChange(of: targetKind) { _, newKind in
            guard newKind != toKind else { return }
            fromKind = toKind
            toKind = newKind
            if reduceMotion {
                kindBlend = 1
                return
            }
            kindBlend = 0
            withAnimation(.easeInOut(duration: ThemeEngine.morphDuration)) {
                kindBlend = 1
            }
        }
        .animation(.easeInOut(duration: ThemeEngine.morphDuration), value: theme.blendProgress)
        .allowsHitTesting(false)
    }

    // MARK: - 0. Deep Atmospheric Spatial Backdrop

    private func drawAtmosphericBackdrop(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let rect = CGRect(origin: .zero, size: size)

        // Dark celestial base
        let bgBase = colors.bgColors.first ?? Color.black
        let bgDeep = colors.bgColors.last ?? Color.black
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [bgBase, bgDeep]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Slow undulating volumetric aura centers (breathing light fields)
        let cx = size.width * 0.5
        let cy = size.height * 0.52

        // Breathing offset (James Turrell aperture modulation)
        let breathe1 = sin(t * 0.18) * 25.0
        let breathe2 = cos(t * 0.14) * 20.0

        // Primary ambient light field (deep glow)
        var aura1 = context
        aura1.addFilter(.blur(radius: 80))
        aura1.blendMode = .plusLighter
        aura1.opacity = 0.38 * energy
        let r1 = max(size.width, size.height) * 0.45
        aura1.fill(
            Path(ellipseIn: CGRect(x: cx - r1 + breathe1, y: cy - r1 + breathe2, width: r1 * 2, height: r1 * 2)),
            with: .color(colors.accentColor)
        )

        // Secondary harmonic light pool
        var aura2 = context
        aura2.addFilter(.blur(radius: 95))
        aura2.blendMode = .plusLighter
        aura2.opacity = 0.28 * energy
        let r2 = max(size.width, size.height) * 0.38
        aura2.fill(
            Path(ellipseIn: CGRect(x: cx - r2 - breathe2 * 1.2, y: cy - r2 * 0.7 - breathe1, width: r2 * 2, height: r2 * 1.6)),
            with: .color(colors.glowColor)
        )
    }

    // MARK: - Generative Mode Dispatcher

    private func drawGenerativeMode(
        _ kind: AtmosphereKind,
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        switch kind {
        case .mist:
            // 1. Sanat & Müzik: James Turrell Işık Açıklığı & Cymatics Harmonik Dalgaları
            drawCymaticsLightAperture(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .aurora:
            // 2. Hava Olayı: Tromsø Kutup Işıkları (Aurora Borealis) & Gece Bulutları
            drawAtmosphericAuroralCurtains(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .lava:
            // 3. Teknoloji & Hız: Tokyo Shinkansen & Sinematik Uzun Pozlama Işık İzleri
            drawHyperTransitLightStreams(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .stream:
            // 4. Doğa & Akış: Okyanus Ufku, Biyo-lüminesans & Boğaz Sisi
            drawBioluminescentOceanMist(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .ember:
            // 5. Termal Konveksiyon: Kuzey Şöminesi, Ağır Yükselen Közler & Yıldız Tozu
            drawThermalHearthConvection(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .rain:
            // 6. Hava Olayı: Şehir Gece Yağmuru & Islak Asfalt Işık Difüzyonu
            drawAtmosphericRainDiffusion(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .snow:
            // 7. Hava Olayı: Sessiz Kar, Kristal Süzülüşü & Beyaz Huzur (Silent Snow)
            drawSilentFallingSnow(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .prism:
            // 8. Optik & Işık: Spektral Prizma & Atmosferik Gökkuşağı Halesi (Rainbow Prism)
            drawPrismaticRainbowHalo(context: &context, size: size, t: t, colors: colors, energy: energy)
        }
    }

    // MARK: - 1. Sanat & Müzik: James Turrell Işık Açıklığı & Cymatics Akustik Rezonansı
    // Focus, Solfeggio 528Hz, Sacred Om, Derin Odaklanma

    private func drawCymaticsLightAperture(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cx = size.width * 0.5
        let cy = size.height * 0.50

        // Yavaş, meditatif nefes döngüsü (~16 saniyede bir tam nefes)
        let breathPhase = sin(t * 0.22)
        let coreRadius = 65.0 + breathPhase * 8.0

        // James Turrell Luminous Aperture (Derinlikli Işık Boşluğu)
        var coreGlow = context
        coreGlow.addFilter(.blur(radius: 28))
        coreGlow.blendMode = .plusLighter
        coreGlow.opacity = (0.62 + breathPhase * 0.12) * energy
        coreGlow.fill(
            Path(ellipseIn: CGRect(x: cx - coreRadius, y: cy - coreRadius, width: coreRadius * 2, height: coreRadius * 2)),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(0.92),
                    colors.accentColor.opacity(0.85),
                    colors.glowColor.opacity(0.35),
                    .clear
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: coreRadius * 1.15
            )
        )

        // Akustik Cymatics Rezonans Halkaları (Harmonik Çap Oranları: 1 : 1.618 : 2.4 : 3.2)
        let cymaticsRatios: [Double] = [1.55, 2.25, 3.10, 4.15]
        for (i, ratio) in cymaticsRatios.enumerated() {
            let ringRadius = coreRadius * ratio
            let phaseOffset = Double(i) * 0.95
            // Çok yavaş dalgalanan genlik modülasyonu
            let ringPulse = sin(t * 0.18 - phaseOffset) * 6.0
            let r = ringRadius + ringPulse

            var ringCtx = context
            let blurAmount = 6.0 + Double(i) * 4.5
            ringCtx.addFilter(.blur(radius: blurAmount))
            ringCtx.blendMode = .plusLighter
            let alpha = max(0.06, (0.34 - Double(i) * 0.06) * (0.85 + breathPhase * 0.15)) * energy
            ringCtx.opacity = alpha

            // 3D eliptik yatıklık (hafif uzamsal perspektif)
            let rect = CGRect(x: cx - r, y: cy - r * 0.58, width: r * 2, height: r * 1.16)
            ringCtx.stroke(
                Path(ellipseIn: rect),
                with: .linearGradient(
                    Gradient(colors: [
                        colors.accentColor.opacity(0.8),
                        colors.waveColors[i % colors.waveColors.count].opacity(0.6),
                        colors.glowColor.opacity(0.2)
                    ]),
                    startPoint: CGPoint(x: cx - r, y: cy),
                    endPoint: CGPoint(x: cx + r, y: cy)
                ),
                lineWidth: CGFloat(2.2 + Double(i) * 1.0)
            )
        }

        // Kırınımlı Işık Hüzmeleri (Delicate Optical Rays)
        let rayCount = 6
        for i in 0..<rayCount {
            let baseAngle = Double(i) * (.pi * 2.0 / Double(rayCount))
            let rayAngle = baseAngle + sin(t * 0.07 + Double(i)) * 0.08
            let rayLength = size.width * 0.55

            let endX = cx + cos(rayAngle) * rayLength
            let endY = cy + sin(rayAngle) * (rayLength * 0.6)

            var rayPath = Path()
            rayPath.move(to: CGPoint(x: cx, y: cy))
            rayPath.addLine(to: CGPoint(x: endX, y: endY))

            var rayCtx = context
            rayCtx.addFilter(.blur(radius: 16))
            rayCtx.blendMode = .plusLighter
            rayCtx.opacity = 0.12 * energy
            rayCtx.stroke(
                rayPath,
                with: .linearGradient(
                    Gradient(colors: [colors.accentColor.opacity(0.6), .clear]),
                    startPoint: CGPoint(x: cx, y: cy),
                    endPoint: CGPoint(x: endX, y: endY)
                ),
                lineWidth: 8.0
            )
        }
    }

    // MARK: - 2. Hava Olayı: Tromsø Kutup Işıkları & Noctilucent Bulut Perdeleri
    // Sleep, Gece Ormanı, Aurora Okyanusu, Sessiz Kar

    private func drawAtmosphericAuroralCurtains(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let curtainCount = 3
        for layer in 0..<curtainCount {
            let depthZ = Double(layer + 1) / Double(curtainCount)
            let baseY = size.height * (0.34 + Double(layer) * 0.13)
            let amp = (32.0 + Double(layer) * 14.0) * energy

            var path = Path()
            path.move(to: CGPoint(x: -40, y: size.height + 40))
            path.addLine(to: CGPoint(x: -40, y: baseY))

            // İpeksi atmosferik rüzgar dalgası (harmonik sinüs toplamı)
            let steps = 45
            for s in 0...steps {
                let xNorm = Double(s) / Double(steps)
                let x = size.width * CGFloat(xNorm)

                // Çok yavaş, sakin akan kutup rüzgarı salınımları
                let w1 = sin(xNorm * 4.2 + t * 0.12 + Double(layer) * 1.8)
                let w2 = cos(xNorm * 2.8 - t * 0.08 + Double(layer) * 0.9)
                let w3 = sin(xNorm * 6.5 + t * 0.16) * 0.35

                let y = baseY + (w1 * 0.6 + w2 * 0.4 + w3) * amp
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: size.width + 40, y: size.height + 40))
            path.closeSubpath()

            var curtainCtx = context
            // İpeksi soft difüzyon (30-55pt blur)
            curtainCtx.addFilter(.blur(radius: 32.0 + Double(layer) * 12.0))
            curtainCtx.blendMode = .plusLighter
            curtainCtx.opacity = (0.26 + depthZ * 0.16) * energy

            let waveColor = colors.waveColors[layer % colors.waveColors.count]
            let curtainGradient = Gradient(colors: [
                waveColor.opacity(0.72),
                colors.accentColor.opacity(0.48),
                colors.glowColor.opacity(0.18),
                .clear
            ])

            curtainCtx.fill(
                path,
                with: .linearGradient(
                    curtainGradient,
                    startPoint: CGPoint(x: size.width * 0.5, y: baseY - 40),
                    endPoint: CGPoint(x: size.width * 0.5, y: baseY + 240)
                )
            )
        }
    }

    // MARK: - 3. Teknoloji & Hız: Tokyo Shinkansen & Sinematik Uzun Pozlama Işık İzleri
    // Tokyo Metro, Shinkansen, Banliyö, Paris Metrosu

    private func drawHyperTransitLightStreams(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cx = size.width * 0.50
        let cy = size.height * 0.54

        // Ufuk Işıltısı (Vanishing Horizon Core Glow)
        var horizonGlow = context
        horizonGlow.addFilter(.blur(radius: 45))
        horizonGlow.blendMode = .plusLighter
        horizonGlow.opacity = 0.48 * energy
        horizonGlow.fill(
            Path(ellipseIn: CGRect(x: cx - 110, y: cy - 40, width: 220, height: 80)),
            with: .color(colors.accentColor)
        )

        // Akıcı Perspektif Işık Şeritleri (Yumuşak eğriler, gözü yormayan sinematik akış)
        let streamCount = 5
        for i in 0..<streamCount {
            // Yavaş döngü: Her kemer 14 saniyede ufuktan ekran önüne doğru zarifçe akar
            let phase = (t * 0.09 + Double(i) / Double(streamCount)).truncatingRemainder(dividingBy: 1.0)
            let zProgress = pow(phase, 2.4) // Perspektif derinlik açılımı

            let w = size.width * 1.35 * CGFloat(zProgress)
            let h = size.height * 0.72 * CGFloat(zProgress)
            guard w > 12, h > 6 else { continue }

            let rect = CGRect(x: cx - w * 0.5, y: cy - h * 0.5, width: w, height: h)

            var streamCtx = context
            // Ufukta daha bulanık, yaklaştıkça daha parlak ve yumuşak
            let blur = max(4.0, (1.0 - zProgress) * 16.0)
            streamCtx.addFilter(.blur(radius: blur))
            streamCtx.blendMode = .plusLighter
            streamCtx.opacity = min(0.38, zProgress * 0.52) * energy

            streamCtx.stroke(
                Path(ellipseIn: rect),
                with: .linearGradient(
                    Gradient(colors: [
                        colors.accentColor.opacity(0.85),
                        colors.glowColor.opacity(0.4),
                        .clear
                    ]),
                    startPoint: CGPoint(x: cx - w * 0.5, y: cy),
                    endPoint: CGPoint(x: cx + w * 0.5, y: cy)
                ),
                lineWidth: CGFloat(2.0 + zProgress * 7.0)
            )
        }

        // Şehir Işığı Yan Bokeh Parçacıkları (Lateral Night City Lights)
        for i in 0..<12 {
            let seed = Double(i) * 3.81
            let side = (i % 2 == 0) ? 1.0 : -1.0
            let lateralProg = (t * 0.05 + seed * 0.1).truncatingRemainder(dividingBy: 1.0)

            let x = cx + side * (size.width * 0.18 + CGFloat(pow(lateralProg, 1.6)) * (size.width * 0.40))
            let y = cy + CGFloat(sin(seed * 2.0)) * 60.0 + CGFloat(lateralProg * 120.0)
            let r = 3.0 + CGFloat(lateralProg * 10.0)

            var bokehCtx = context
            bokehCtx.addFilter(.blur(radius: 3.5 + lateralProg * 4.0))
            bokehCtx.blendMode = .plusLighter
            bokehCtx.opacity = (0.15 + lateralProg * 0.35) * energy

            bokehCtx.fill(
                Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                with: .color(colors.accentColor)
            )
        }
    }

    // MARK: - 4. Doğa & Akış: Okyanus Ufku, Biyo-lüminesans & Boğaz Sisi
    // Yağmur Penceresi, İstanbul Vapuru, Yosunlu Şelale

    private func drawBioluminescentOceanMist(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let horizonY = size.height * 0.56

        // Boğaz & Okyanus Ufuk Sisi (Atmospheric Sea Mist Bank)
        var mist = context
        mist.addFilter(.blur(radius: 50))
        mist.blendMode = .plusLighter
        mist.opacity = 0.36 * energy
        mist.fill(
            Path(CGRect(x: 0, y: horizonY - 60, width: size.width, height: 120)),
            with: .color(colors.accentColor)
        )

        // Hacimsel Sıvı Dalga Düzlemleri (Organik trochoidal okyanus dalgalanması)
        let waveLayers = 3
        for i in 0..<waveLayers {
            let layerY = horizonY + CGFloat(i * 26)
            let amp = (10.0 + Double(i) * 5.0) * energy

            var path = Path()
            path.move(to: CGPoint(x: -20, y: layerY))

            let steps = 36
            for s in 0...steps {
                let xNorm = Double(s) / Double(steps)
                let x = size.width * CGFloat(xNorm)

                // Çok yavaş, meditatif deniz ritmi
                let wave = sin(xNorm * 3.8 + t * 0.14 + Double(i) * 1.2) * 0.7 +
                           cos(xNorm * 2.1 - t * 0.08) * 0.3
                let y = layerY + wave * amp
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: size.width + 20, y: size.height))
            path.addLine(to: CGPoint(x: -20, y: size.height))
            path.closeSubpath()

            var oceanCtx = context
            oceanCtx.addFilter(.blur(radius: 12.0 + Double(i) * 6.0))
            oceanCtx.blendMode = .plusLighter
            oceanCtx.opacity = (0.18 + Double(i) * 0.10) * energy

            let grad = Gradient(colors: [
                colors.waveColors[i % colors.waveColors.count].opacity(0.65),
                colors.accentColor.opacity(0.35),
                .clear
            ])

            oceanCtx.fill(
                path,
                with: .linearGradient(
                    grad,
                    startPoint: CGPoint(x: 0, y: layerY - 20),
                    endPoint: CGPoint(x: 0, y: layerY + 120)
                )
            )
        }

        // Biyo-lüminesans Işık Havuzları (Bioluminescent Caustics Plankton)
        for i in 0..<6 {
            let seed = Double(i) * 4.31
            let poolX = size.width * (0.2 + CGFloat(i) * 0.13) + CGFloat(sin(t * 0.1 + seed)) * 30.0
            let poolY = horizonY + 25.0 + CGFloat(sin(seed * 2.5 + t * 0.12)) * 35.0
            let poolW = 50.0 + CGFloat(cos(t * 0.15 + seed)) * 18.0

            var poolCtx = context
            poolCtx.addFilter(.blur(radius: 20))
            poolCtx.blendMode = .plusLighter
            poolCtx.opacity = (0.22 + sin(t * 0.2 + seed) * 0.12) * energy

            poolCtx.fill(
                Path(ellipseIn: CGRect(x: poolX - poolW * 0.5, y: poolY - 12, width: poolW, height: 24)),
                with: .color(colors.glowColor)
            )
        }
    }

    // MARK: - 5. Termal Konveksiyon: Kuzey Şöminesi, Ağır Yükselen Közler & Yıldız Tozu
    // Sonbahar 432Hz, Hygge Gecesi, Gece Kafesi

    private func drawThermalHearthConvection(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cx = size.width * 0.50
        let hearthY = size.height * 0.68

        // Volumetric Warm Hearth Core (Nefes alan şömine sıcağı)
        let breathe = sin(t * 0.24)
        var core = context
        core.addFilter(.blur(radius: 65))
        core.blendMode = .plusLighter
        core.opacity = (0.46 + breathe * 0.10) * energy
        core.fill(
            Path(ellipseIn: CGRect(x: cx - 130, y: hearthY - 80, width: 260, height: 160)),
            with: .color(colors.accentColor)
        )

        // İpeksi Ağır Yükselen Köz Kıvılcımları (Termal Konveksiyon Hızı Yarıya İndirildi)
        let emberCount = 24
        for i in 0..<emberCount {
            let seed = Double(i) * 6.17
            let z = (sin(seed * 1.8) * 0.5 + 0.5) // Derinlik 0..1

            // Sakin termal akıntı salınımı
            let xOffset = sin(seed + t * (0.15 + z * 0.10)) * (size.width * 0.42)
            let x = cx + xOffset

            // Meditatif yükseliş hızı (Önceki 35.0 yerine 12.0)
            let riseSpeed = 10.0 + z * 16.0
            let yProg = (t * riseSpeed + seed * 45.0).truncatingRemainder(dividingBy: size.height * 0.70)
            let y = size.height * 0.86 - yProg

            let r = 1.4 + z * 3.2
            var sparkCtx = context
            sparkCtx.addFilter(.blur(radius: (1.0 - z) * 2.8 + 0.8))
            sparkCtx.blendMode = .plusLighter
            sparkCtx.opacity = (0.28 + z * 0.52) * energy

            sparkCtx.fill(
                Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                with: .color(z > 0.65 ? Color.white : colors.accentColor)
            )
        }
    }

    // MARK: - 6. Hava Olayı: Şehir Gece Yağmuru & Islak Asfalt Işık Difüzyonu
    // Gece Yağmuru, Tokyo Yağmuru, Seralarda Yağmur, Teneke Çatı

    private func drawAtmosphericRainDiffusion(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cy = size.height * 0.52

        // Şehir Işığı Difüzyonu (Soft Ambient Rain Glow)
        var mist = context
        mist.addFilter(.blur(radius: 65))
        mist.blendMode = .plusLighter
        mist.opacity = 0.35 * energy
        mist.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.12, y: cy - 90, width: size.width * 0.76, height: 180)),
            with: .color(colors.glowColor)
        )

        // Hacimsel Yağmur Tülleri (Hızlı düşen çizgiler yerine yumuşak, dinlendirici su tülleri)
        let dropCount = 28
        for i in 0..<dropCount {
            let seed = Double(i) * 5.43
            let z = (sin(seed * 1.9) * 0.5 + 0.5) // Derinlik katmanı 0..1
            let x = (sin(seed * 2.8) * 0.5 + 0.5) * size.width

            // Rahatlatıcı meditatif iniş hızı (Önceki 180.0 yerine 45.0)
            let fallSpeed = 35.0 + z * 65.0
            let y = (t * fallSpeed + seed * 60.0).truncatingRemainder(dividingBy: size.height + 80.0) - 40.0

            let streakLen = 8.0 + z * 18.0

            var dropCtx = context
            dropCtx.addFilter(.blur(radius: (1.0 - z) * 3.2 + 0.6))
            dropCtx.blendMode = .plusLighter
            dropCtx.opacity = (0.20 + z * 0.45) * energy

            var dropPath = Path()
            dropPath.move(to: CGPoint(x: x, y: y))
            // Hafif rüzgar açısı ile iniş
            dropPath.addLine(to: CGPoint(x: x + 2.5, y: y + streakLen))

            dropCtx.stroke(
                dropPath,
                with: .linearGradient(
                    Gradient(colors: [colors.accentColor.opacity(0.8), .clear]),
                    startPoint: CGPoint(x: x, y: y),
                    endPoint: CGPoint(x: x + 2.5, y: y + streakLen)
                ),
                lineWidth: CGFloat(1.2 + z * 1.6)
            )
        }

        // Islak Zemin Yansımaları (Ground Refraction Puddles)
        let groundY = size.height * 0.88
        for i in 0..<4 {
            let seed = Double(i) * 7.12
            let rx = size.width * (0.2 + CGFloat(i) * 0.22)
            let rw = 60.0 + CGFloat(sin(t * 0.12 + seed)) * 25.0

            var groundCtx = context
            groundCtx.addFilter(.blur(radius: 22))
            groundCtx.blendMode = .plusLighter
            groundCtx.opacity = (0.22 + cos(t * 0.18 + seed) * 0.08) * energy

            groundCtx.fill(
                Path(ellipseIn: CGRect(x: rx - rw * 0.5, y: groundY, width: rw, height: 18)),
                with: .color(colors.accentColor)
            )
        }
    }

    // MARK: - 7. Evrensel 3D Yıldız Tozu & Biyo-Parçacık Derinliği (Global Stardust)

    private func drawUniversalStardust(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let particleCount = 20
        for i in 0..<particleCount {
            let seed = Double(i) * 8.41
            // 3D derinlik katmanı z: 0.1 (uzak mikro) - 1.0 (kameraya yakın)
            let z = 0.15 + (sin(seed * 3.14) * 0.5 + 0.5) * 0.85

            // Yavaş, meditatif 3D Browniyen süzülüş
            let driftX = sin(seed + t * 0.04) * (size.width * 0.44)
            let x = size.width * 0.5 + driftX

            // Y ekseninde neredeyse duran, yerçekimsiz süzülüş
            let driftY = cos(seed * 1.4 + t * 0.03) * (size.height * 0.42)
            let y = size.height * 0.52 + driftY

            let radius = CGFloat(1.2 + z * 4.2)
            let blurAmount = (1.0 - z) * 3.0 + 0.6

            var pCtx = context
            pCtx.addFilter(.blur(radius: blurAmount))
            pCtx.blendMode = .plusLighter
            // Yumuşak nabız atışı
            let pulse = sin(t * 0.18 + seed) * 0.15
            pCtx.opacity = max(0.08, (0.16 + z * 0.40 + pulse) * energy)

            let particleColor = z > 0.7 ? Color.white : colors.accentColor

            pCtx.fill(
                Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                with: .color(particleColor)
            )
        }
    }

    // MARK: - 8. Hava Olayı: 3D Sessiz Kar Yağışı & Kristal Süzülüşü (Silent Snow)
    // Sessiz Kar, Minka Kütüphanesi

    private func drawSilentFallingSnow(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        // Yumuşak Kış Gecesi Atmosfer Sisi
        let cy = size.height * 0.50
        var winterMist = context
        winterMist.addFilter(.blur(radius: 70))
        winterMist.blendMode = .plusLighter
        winterMist.opacity = 0.32 * energy
        winterMist.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.1, y: cy - 100, width: size.width * 0.8, height: 200)),
            with: .color(Color(hex: 0x80D8FF).opacity(0.4))
        )

        // 3D Derinlikli Lapa Lapa Kar Kristalleri (Yavaş ve Hipnotik Süzülüş)
        let flakeCount = 38
        for i in 0..<flakeCount {
            let seed = Double(i) * 7.73
            let z = 0.15 + (sin(seed * 2.3) * 0.5 + 0.5) * 0.85 // Derinlik katmanı: 0.15 (uzak) - 1.0 (önde)
            
            // Rüzgar ve hava akımı ile yatay salınım (Brownian drift)
            let baseOffsetX = (sin(seed * 3.7) * 0.5 + 0.5) * size.width
            let sway = sin(t * 0.28 + seed * 1.8) * (16.0 + z * 18.0)
            let x = (baseOffsetX + sway).truncatingRemainder(dividingBy: size.width)
            
            // Çok sakin ve meditatif iniş hızı (Ön plandakiler biraz daha hızlı, arka plandakiler asılı gibi)
            let fallSpeed = 14.0 + z * 22.0
            let y = (t * fallSpeed + seed * 48.0).truncatingRemainder(dividingBy: size.height + 60.0) - 30.0
            
            let radius = CGFloat(1.5 + z * 3.8)
            let blurAmount = (1.0 - z) * 2.6 + 0.4
            
            var flakeCtx = context
            flakeCtx.addFilter(.blur(radius: blurAmount))
            flakeCtx.blendMode = .plusLighter
            
            // Kar tanesinin hafif ışıltı nabzı
            let twinkle = sin(t * 0.35 + seed) * 0.12
            flakeCtx.opacity = max(0.15, (0.35 + z * 0.55 + twinkle) * energy)
            
            // Kar tanesi gövdesi
            flakeCtx.fill(
                Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                with: .color(Color.white)
            )
            
            // Ön plandaki tanelere hafif kristal ışıltısı
            if z > 0.75 {
                var crystalCtx = context
                crystalCtx.addFilter(.blur(radius: 0.3))
                crystalCtx.stroke(
                    Path(ellipseIn: CGRect(x: x - radius * 1.3, y: y - radius * 1.3, width: radius * 2.6, height: radius * 2.6)),
                    with: .color(Color(hex: 0xE1F5FE).opacity(0.8)),
                    lineWidth: 0.6
                )
            }
        }
        
        // Zemin Kış Işıltısı (Ground Frost Shimmer)
        let groundY = size.height * 0.90
        var frostCtx = context
        frostCtx.addFilter(.blur(radius: 25))
        frostCtx.blendMode = .plusLighter
        frostCtx.opacity = 0.28 * energy
        frostCtx.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.05, y: groundY, width: size.width * 0.90, height: 28)),
            with: .color(Color.white.opacity(0.7))
        )
    }

    // MARK: - 9. Optik & Işık: Spektral Prizma & Atmosferik Gökkuşağı Halesi (Rainbow Prism)
    // 528Hz Şifa Frekansı, Kutsal OM, Sonbahar 432Hz

    private func drawPrismaticRainbowHalo(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cx = size.width * 0.50
        let cy = size.height * 0.44

        // Nefes Alan Güneş/Prizma Işığı Çekirdeği
        let breathe = sin(t * 0.20)
        var core = context
        core.addFilter(.blur(radius: 50))
        core.blendMode = .plusLighter
        core.opacity = (0.50 + breathe * 0.12) * energy
        core.fill(
            Path(ellipseIn: CGRect(x: cx - 90, y: cy - 90, width: 180, height: 180)),
            with: .color(Color(hex: 0xFFF9C4))
        )

        // Atmosferik Prizmatik Gökkuşağı Halesi (Spectral Refraction Bands)
        // Kırmızı -> Turuncu -> Sarı -> Zümrüt -> Camgöbeği -> Safir -> Leylak
        let spectralColors: [Color] = [
            Color(hex: 0xFF1744), // Kırmızı
            Color(hex: 0xFF9100), // Turuncu
            Color(hex: 0xFFEA00), // Altın Sarı
            Color(hex: 0x00E676), // Canlı Zümrüt
            Color(hex: 0x00E5FF), // Elektrik Camgöbeği
            Color(hex: 0x2979FF), // Safir Mavi
            Color(hex: 0xD500F9)  // Derin Leylak
        ]

        let baseRadius = 110.0 + breathe * 12.0

        for (idx, col) in spectralColors.enumerated() {
            let r = baseRadius + Double(idx) * 9.5
            var arcCtx = context
            arcCtx.addFilter(.blur(radius: 9.0))
            arcCtx.blendMode = .plusLighter
            
            // Spektral bant dalgalanması
            let bandPhase = sin(t * 0.24 + Double(idx) * 0.4) * 0.08
            arcCtx.opacity = (0.24 + bandPhase) * energy

            arcCtx.stroke(
                Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                with: .color(col),
                lineWidth: 7.0
            )
        }

        // Gökyüzünde Süzülen Mikro Prizma Parıltıları
        for i in 0..<12 {
            let seed = Double(i) * 5.21
            let angle = t * 0.06 + seed
            let dist = baseRadius + CGFloat(sin(t * 0.15 + seed)) * 55.0
            let px = cx + cos(angle) * dist
            let py = cy + sin(angle) * dist
            
            var sparkCtx = context
            sparkCtx.addFilter(.blur(radius: 1.2))
            sparkCtx.blendMode = .plusLighter
            sparkCtx.opacity = (0.35 + sin(t * 0.4 + seed) * 0.25) * energy
            
            let sparkCol = spectralColors[i % spectralColors.count]
            sparkCtx.fill(
                Path(ellipseIn: CGRect(x: px - 2.5, y: py - 2.5, width: 5.0, height: 5.0)),
                with: .color(sparkCol)
            )
        }
    }
}
