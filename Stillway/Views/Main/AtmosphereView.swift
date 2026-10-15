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
        if let override = theme.atmosphereOverride {
            return override
        }
        return AtmosphereKind.resolve(soundID: audio.primarySound?.id, context: theme.currentContext)
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
            // 1. Sanat & Müzik: James Turrell Işık Açıklığı & Cymatics Harmonik Dalgaları + Bahar Çiçek Yaprakları
            drawCymaticsLightAperture(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawBotanicalFlowerPetals(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .aurora:
            // 2. Hava Olayı: Tromsø Kutup Işıkları + Çam Ağaçları + Ateşböcekleri + Gökyüzü Yıldızları & Kayan Yıldız
            drawAtmosphericAuroralCurtains(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawTwinklingStarsAndShootingStar(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawPineForestAndFireflies(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .lava:
            // 3. Teknoloji & Hız: Tokyo Shinkansen & Sinematik Uzun Pozlama Işık İzleri
            drawHyperTransitLightStreams(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .stream:
            // 4. Doğa & Akış: Okyanus Ufku, Biyo-lüminesans + Yaşayan Deniz Dalgaları, Akarsu Akıntıları & Süzülen Yapraklar
            drawBioluminescentOceanMist(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawLivingOceanWavesAndStreamCurrents(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawBotanicalFlowerPetals(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .ember:
            // 5. Termal Konveksiyon: Kuzey Şöminesi, Ağır Yükselen Közler & Gece Yıldızları
            drawThermalHearthConvection(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawTwinklingStarsAndShootingStar(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .rain:
            // 6. Hava Olayı: Şehir Gece Yağmuru + Su Birikintisi Konsantrik Dalgaları & Sıçramalar
            drawAtmosphericRainDiffusion(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawRainPuddleRipplesAndSplashes(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .snow:
            // 7. Hava Olayı: Sessiz Kar + Çam Ormanı & Gece Işıltıları (Silent Snow)
            drawSilentFallingSnow(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawPineForestAndFireflies(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .prism:
            // 8. Optik & Işık: Spektral Prizma + Parlak Güneş, Hacimsel Işık Hüzmeleri & Çiçek Bahçesi Yaprakları
            drawPrismaticRainbowHalo(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawRadiantSunAndGodRays(context: &context, size: size, t: t, colors: colors, energy: energy)
            drawBotanicalFlowerPetals(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .neonSmoke:
            // 9. Siber Neon Duman & Tepe Işık Tüpleri (Görüntüdeki Karşılıklı Duman Teması)
            drawDualNeonSmokeAtmosphere(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .lavaTube:
            // 10. Renkli Lav Tüpü & Akışkan Magma Lambası
            drawBioluminescentLavaTube(context: &context, size: size, t: t, colors: colors, energy: energy)

        case .lightShow:
            // 11. Dinamik Sahne Işık Oyunları & Spektral Prizmatik Lazer Huzmeleri
            drawPrismaticLightShowBeams(context: &context, size: size, t: t, colors: colors, energy: energy)
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

    // MARK: - 9. Siber Neon Duman (Cigarette / Incense Wisps & Dual Rising Plumes)
    // Ekranın sol ve sağından yükselen, ince zarif kıvrımlarla (laminar akıştan türbülanslı
    // girdaplara) süzülen sigara dumanı tülleri; merkezde birbiriyle kaynaşan mor/eflatun duman helezonları.
    private func drawDualNeonSmokeAtmosphere(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cx = size.width * 0.5
        let floorY = size.height * 0.92

        // 1. SOL VE SAĞ SİGARA DUMANI PLÜMLERİ (Left Magenta & Right Cyan Cigarette Smoke Plumes)
        // Her iki taraf için çok katmanlı, sinüsoidal kıvrımlı, merkez omurgalı ve spiral girdaplı duman tülleri
        struct SmokeSideConfig {
            let isLeft: Bool
            let baseColor: Color
            let glowColor: Color
            let coreColor: Color
            let baseXRatio: CGFloat
        }

        let sides: [SmokeSideConfig] = [
            SmokeSideConfig(
                isLeft: true,
                baseColor: Color(hex: 0xFF007F), // Canlı Neon Pembe / Macenta
                glowColor: Color(hex: 0x9C27B0), // Derin Mor / Eflatun
                coreColor: Color(hex: 0xFF80AB), // Parlak Duman Çekirdeği
                baseXRatio: 0.14
            ),
            SmokeSideConfig(
                isLeft: false,
                baseColor: Color(hex: 0x00E5FF), // Elektrik Camgöbeği
                glowColor: Color(hex: 0x0D47A1), // Kobalt / Okyanus
                coreColor: Color(hex: 0x80D8FF), // Parlak Camgöbeği Çekirdek
                baseXRatio: 0.86
            )
        ]

        for side in sides {
            let baseX = size.width * side.baseXRatio
            let dirSign: CGFloat = side.isLeft ? 1.0 : -1.0

            // Her plüm için 4 adet ince, bağımsız dalgalanan sigara dumanı şeridi (Smoke Ribbons)
            for ribbonIdx in 0..<4 {
                let seed = Double(ribbonIdx) * 2.87 + (side.isLeft ? 0.0 : 4.19)
                let ribbonPhase = t * 0.16 + seed

                var leftPath = Path()
                var rightPath = Path()
                var spinePath = Path()

                let steps = 30
                var spinePoints: [CGPoint] = []

                for step in 0...steps {
                    let u = Double(step) / Double(steps) // 0.0 (taban) -> 1.0 (üst tepe)
                    let y = floorY - CGFloat(u) * (size.height * 0.98)

                    // Taban kısımda laminar (ince ve düzgün), yukarı çıktıkça türbülans ve kıvrımlar artar
                    let laminarFactor = pow(u, 1.45)

                    // Sigara dumanının hava akımındaki salınımı ve helezonik kıvrımları
                    let wave1 = sin(u * 7.5 - ribbonPhase + seed) * (14.0 + laminarFactor * 48.0)
                    let wave2 = cos(u * 14.0 - ribbonPhase * 1.4 + seed * 1.5) * (6.0 + laminarFactor * 26.0)
                    let wave3 = sin(u * 22.0 - ribbonPhase * 2.0 + seed * 0.7) * (2.0 + laminarFactor * 12.0)
                    let totalCurl = CGFloat(wave1 + wave2 + wave3) * dirSign

                    // Merkeze doğru termal çekim ve birbirine doğru süzülüş
                    let centerDrift = dirSign * CGFloat(pow(u, 1.35)) * (size.width * 0.28)

                    let curX = baseX + totalCurl + centerDrift

                    // Sigara dumanının genişlemesi: Altta çok ince (4-8px), üstte tül gibi açılan (45-70px)
                    let ribbonW = (5.0 + CGFloat(laminarFactor) * 58.0 + CGFloat(sin(u * 10.0 + ribbonPhase) * 8.0))

                    let ptLeft = CGPoint(x: curX - ribbonW * 0.5, y: y)
                    let ptRight = CGPoint(x: curX + ribbonW * 0.5, y: y)
                    let ptSpine = CGPoint(x: curX, y: y)

                    spinePoints.append(ptSpine)

                    if step == 0 {
                        leftPath.move(to: ptLeft)
                        rightPath.move(to: ptRight)
                        spinePath.move(to: ptSpine)
                    } else {
                        leftPath.addLine(to: ptLeft)
                        rightPath.addLine(to: ptRight)
                        spinePath.addLine(to: ptSpine)
                    }
                }

                // Kapalı duman şeridi poligonu (Ribbon Mesh)
                var ribbonMesh = leftPath
                ribbonMesh.addLine(to: spinePoints.last ?? .zero)
                // Sağ kenarı yukarıdan aşağıya doğru birleştir
                var reversedRight = Path()
                let stepCount = spinePoints.count
                for step in (0..<stepCount).reversed() {
                    let u = Double(step) / Double(stepCount - 1)
                    let y = floorY - CGFloat(u) * (size.height * 0.98)
                    let laminarFactor = pow(u, 1.45)
                    let wave1 = sin(u * 7.5 - ribbonPhase + seed) * (14.0 + laminarFactor * 48.0)
                    let wave2 = cos(u * 14.0 - ribbonPhase * 1.4 + seed * 1.5) * (6.0 + laminarFactor * 26.0)
                    let wave3 = sin(u * 22.0 - ribbonPhase * 2.0 + seed * 0.7) * (2.0 + laminarFactor * 12.0)
                    let totalCurl = CGFloat(wave1 + wave2 + wave3) * dirSign
                    let centerDrift = dirSign * CGFloat(pow(u, 1.35)) * (size.width * 0.28)
                    let curX = baseX + totalCurl + centerDrift
                    let ribbonW = (5.0 + CGFloat(laminarFactor) * 58.0 + CGFloat(sin(u * 10.0 + ribbonPhase) * 8.0))
                    let ptRight = CGPoint(x: curX + ribbonW * 0.5, y: y)
                    if step == stepCount - 1 {
                        reversedRight.move(to: ptRight)
                    } else {
                        reversedRight.addLine(to: ptRight)
                    }
                }
                ribbonMesh.addPath(reversedRight)
                ribbonMesh.closeSubpath()

                // Katman 1: Yumuşak difüz duman tülü (Soft Volumetric Smoke Veil)
                var veilCtx = context
                veilCtx.addFilter(.blur(radius: 14 + CGFloat(ribbonIdx) * 3))
                veilCtx.blendMode = .plusLighter
                veilCtx.opacity = (0.28 - Double(ribbonIdx) * 0.04) * energy
                veilCtx.fill(
                    ribbonMesh,
                    with: .linearGradient(
                        Gradient(colors: [
                            side.baseColor.opacity(0.85),
                            side.glowColor.opacity(0.65),
                            side.glowColor.opacity(0.20),
                            .clear
                        ]),
                        startPoint: CGPoint(x: baseX, y: floorY),
                        endPoint: CGPoint(x: cx, y: size.height * 0.05)
                    )
                )

                // Katman 2: Sigara dumanının ışığı kıran parlak ince merkez omurgası (Illuminated Filament Spine)
                var spineCtx = context
                spineCtx.addFilter(.blur(radius: 2.4 + CGFloat(ribbonIdx) * 0.8))
                spineCtx.blendMode = .plusLighter
                spineCtx.opacity = (0.65 - Double(ribbonIdx) * 0.10) * energy
                spineCtx.stroke(
                    spinePath,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.95),
                            side.coreColor.opacity(0.80),
                            side.baseColor.opacity(0.40),
                            .clear
                        ]),
                        startPoint: CGPoint(x: baseX, y: floorY),
                        endPoint: CGPoint(x: cx, y: size.height * 0.10)
                    ),
                    lineWidth: CGFloat(2.2 - Double(ribbonIdx) * 0.3)
                )

                // Katman 3: Dumandan kopup dönen helezon girdaplar (Vorticity Smoke Curls)
                for curlIdx in 0..<5 {
                    let curlSeed = seed + Double(curlIdx) * 3.41
                    let uPos = 0.28 + Double(curlIdx) * 0.14
                    let ptIdx = min(steps, max(0, Int(uPos * Double(steps))))
                    let vortexCenter = spinePoints[ptIdx]

                    let curlAngleStart = t * 0.45 * Double(dirSign) + curlSeed
                    var curlPath = Path()
                    let spiralTurns = 12
                    let maxRadius: CGFloat = 8.0 + CGFloat(uPos * 28.0)

                    for s in 0...spiralTurns {
                        let frac = Double(s) / Double(spiralTurns)
                        let theta = curlAngleStart + frac * .pi * 2.2 * Double(dirSign)
                        let r = maxRadius * CGFloat(pow(frac, 1.2))
                        let px = vortexCenter.x + cos(theta) * r
                        let py = vortexCenter.y + sin(theta) * r * 0.65 - CGFloat(frac * 14.0)

                        if s == 0 {
                            curlPath.move(to: CGPoint(x: px, y: py))
                        } else {
                            curlPath.addLine(to: CGPoint(x: px, y: py))
                        }
                    }

                    var curlCtx = context
                    curlCtx.addFilter(.blur(radius: 4.5))
                    curlCtx.blendMode = .plusLighter
                    curlCtx.opacity = (0.35 + sin(t * 0.3 + curlSeed) * 0.12) * energy
                    curlCtx.stroke(
                        curlPath,
                        with: .color(side.coreColor),
                        lineWidth: 1.5
                    )
                }
            }

            // Taban Sigara / Köz Duman Çıkış Noktası (Base Incandescent Source)
            var basePointCtx = context
            basePointCtx.addFilter(.blur(radius: 12))
            basePointCtx.blendMode = .plusLighter
            basePointCtx.opacity = 0.70 * energy
            basePointCtx.fill(
                Path(ellipseIn: CGRect(x: baseX - 16, y: floorY - 8, width: 32, height: 16)),
                with: .color(side.baseColor)
            )
        }

        // 2. ORTA ALANDA ÇARPIŞAN VE BİRBİRİNE KARIŞAN MOR HELEZONLAR (Center Intertwining Smoke Clouds)
        for i in 0..<6 {
            let seed = Double(i) * 3.65
            let midY = size.height * (0.24 + CGFloat(i) * 0.10) + CGFloat(sin(t * 0.18 + seed)) * 18.0
            let driftX = cx + CGFloat(sin(t * 0.22 + seed)) * (size.width * 0.12)
            let puffW = size.width * (0.36 + CGFloat(sin(t * 0.14 + seed)) * 0.08)
            let puffH = 60.0 + CGFloat(cos(t * 0.19 + seed)) * 16.0

            var mixCtx = context
            mixCtx.addFilter(.blur(radius: 26))
            mixCtx.blendMode = .plusLighter
            mixCtx.opacity = (0.26 + sin(t * 0.24 + seed) * 0.08) * energy

            mixCtx.fill(
                Path(ellipseIn: CGRect(x: driftX - puffW * 0.5, y: midY - puffH * 0.5, width: puffW, height: puffH)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: 0xBA68C8).opacity(0.75), // Lila / Mor Duman Karışımı
                        Color(hex: 0x7E57C2).opacity(0.45),
                        Color(hex: 0x00E5FF).opacity(0.15),
                        .clear
                    ]),
                    center: CGPoint(x: driftX, y: midY),
                    startRadius: 0,
                    endRadius: puffW * 0.55
                )
            )
        }

        // 3. ZEMİN SİS VE YANSIMA KATMANI (Floor Ambient Glow)
        var floorGlow = context
        floorGlow.addFilter(.blur(radius: 32))
        floorGlow.blendMode = .plusLighter
        floorGlow.opacity = 0.32 * energy
        floorGlow.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.08, y: floorY - 12, width: size.width * 0.84, height: 28)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: 0xFF007F).opacity(0.6),
                    Color(hex: 0x7C4DFF).opacity(0.4),
                    Color(hex: 0x00E5FF).opacity(0.6)
                ]),
                startPoint: CGPoint(x: size.width * 0.08, y: floorY),
                endPoint: CGPoint(x: size.width * 0.92, y: floorY)
            )
        )

        // 4. DUMAN İÇİNDE HAVALANAN MİKRO IŞILTI KIVILCIMLARI (Airborne Micro-Sparks)
        for i in 0..<16 {
            let seed = Double(i) * 5.43
            let isLeft = (i % 2 == 0)
            let riseProg = (t * 0.12 + seed * 0.12).truncatingRemainder(dividingBy: 1.0)
            let sparkY = floorY - CGFloat(riseProg) * (size.height * 0.84)
            let baseX = isLeft ? size.width * 0.16 : size.width * 0.84
            let drift = sin(riseProg * 7.0 + seed) * (28.0 + riseProg * 35.0)
            let dirSign: CGFloat = isLeft ? 1.0 : -1.0
            let sparkX = baseX + CGFloat(drift) + (dirSign * CGFloat(pow(riseProg, 1.4)) * (size.width * 0.22))

            let r = CGFloat(1.2 + (sin(seed) * 0.5 + 0.5) * 1.8)

            var sparkCtx = context
            sparkCtx.addFilter(.blur(radius: 1.5))
            sparkCtx.blendMode = .plusLighter
            sparkCtx.opacity = (0.50 + sin(t * 0.6 + seed) * 0.35) * energy

            let sparkCol = isLeft ? Color(hex: 0xFF80AB) : Color(hex: 0x80D8FF)
            sparkCtx.fill(
                Path(ellipseIn: CGRect(x: sparkX - r, y: sparkY - r, width: r * 2, height: r * 2)),
                with: .color(sparkCol)
            )
        }
    }

    // MARK: - 10. Renkli Lav Tüpü & Akışkan Magma Lambası (Bioluminescent Lava Tube)
    // Fizik tabanlı akışkan magma: tabandan uzayarak KOPMA (Pinch-off / Snapping) efekti,
    // havada karşılaşan kürelerin ÇARPMA VE BÜYÜME (Collision, Coalescence & Radial Expansion) dinamikleri.
    private func drawBioluminescentLavaTube(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cx = size.width * 0.5
        let tubeW = min(size.width * 0.84, 400.0)
        let tubeLeft = cx - tubeW * 0.5
        let tubeRight = cx + tubeW * 0.5
        let topY = size.height * 0.08
        let bottomY = size.height * 0.90
        let tubeH = bottomY - topY

        // 1. Cam Silindir Çerçevesi & Ambient İç Aydınlatma (Glass Tube Walls & Fluid Ambience)
        var glassCtx = context
        glassCtx.addFilter(.blur(radius: 3.5))
        glassCtx.blendMode = .plusLighter
        glassCtx.opacity = 0.45 * energy

        var leftWall = Path()
        leftWall.move(to: CGPoint(x: tubeLeft, y: topY))
        leftWall.addLine(to: CGPoint(x: tubeLeft, y: bottomY))
        glassCtx.stroke(
            leftWall,
            with: .linearGradient(
                Gradient(colors: [.clear, Color(hex: 0xFF3D00).opacity(0.85), Color(hex: 0xFF007F).opacity(0.85), .clear]),
                startPoint: CGPoint(x: tubeLeft, y: topY),
                endPoint: CGPoint(x: tubeLeft, y: bottomY)
            ),
            lineWidth: 2.2
        )

        var rightWall = Path()
        rightWall.move(to: CGPoint(x: tubeRight, y: topY))
        rightWall.addLine(to: CGPoint(x: tubeRight, y: bottomY))
        glassCtx.stroke(
            rightWall,
            with: .linearGradient(
                Gradient(colors: [.clear, Color(hex: 0xD500F9).opacity(0.85), Color(hex: 0x00E5FF).opacity(0.85), .clear]),
                startPoint: CGPoint(x: tubeRight, y: topY),
                endPoint: CGPoint(x: tubeRight, y: bottomY)
            ),
            lineWidth: 2.2
        )

        // İç akışkan ambient mor/erik ışıltısı
        var fluidBg = context
        fluidBg.addFilter(.blur(radius: 50))
        fluidBg.blendMode = .plusLighter
        fluidBg.opacity = 0.26 * energy
        fluidBg.fill(
            Path(roundedRect: CGRect(x: tubeLeft + 15, y: topY + 15, width: tubeW - 30, height: tubeH - 30), cornerRadius: 40),
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: 0x31003D),
                    Color(hex: 0x4A0033),
                    Color(hex: 0x1A052E)
                ]),
                startPoint: CGPoint(x: cx, y: topY),
                endPoint: CGPoint(x: cx, y: bottomY)
            )
        )

        // 2. TABANDAN UZAYIP KOPMA EFEKTİ (Bottom Necking, Pinch-Off & Satellite Droplet Snap)
        // Sıcak tabandan yükselen magma damlası yukarı doğru uzar, incelir (boyun yapar) ve KOPARAK fırlar
        let snapPeriod = 8.5
        let snapProg = (t / snapPeriod).truncatingRemainder(dividingBy: 1.0) // 0.0 -> 1.0 döngü
        let baseHeaterY = bottomY - 18.0

        if snapProg < 0.50 {
            // EVRE 1: Boyun Yapma ve Yukarı Uzama (Necking & Stretching)
            let stretchRatio = snapProg / 0.50 // 0.0 -> 1.0
            let domeH = 40.0 + CGFloat(stretchRatio * 150.0)
            let domeY = baseHeaterY - domeH
            let domeX = cx + CGFloat(sin(t * 0.3)) * 25.0
            let domeRadius: CGFloat = 32.0 + CGFloat(sin(stretchRatio * .pi)) * 12.0
            let neckW = max(3.5, CGFloat(34.0 * (1.0 - stretchRatio * 0.92))) // İyice incelen boyun!

            // Gövde ile taban arasındaki incelen akışkan boyun köprüsü
            var neckPath = Path()
            neckPath.move(to: CGPoint(x: domeX - neckW * 0.5, y: domeY))
            neckPath.addQuadCurve(
                to: CGPoint(x: cx - 42.0, y: baseHeaterY),
                control: CGPoint(x: domeX - neckW * 0.8, y: (domeY + baseHeaterY) * 0.55)
            )
            neckPath.addLine(to: CGPoint(x: cx + 42.0, y: baseHeaterY))
            neckPath.addQuadCurve(
                to: CGPoint(x: domeX + neckW * 0.5, y: domeY),
                control: CGPoint(x: domeX + neckW * 0.8, y: (domeY + baseHeaterY) * 0.55)
            )
            neckPath.closeSubpath()

            var neckCtx = context
            neckCtx.addFilter(.blur(radius: 8))
            neckCtx.blendMode = .plusLighter
            neckCtx.opacity = 0.85 * energy
            neckCtx.fill(
                neckPath,
                with: .linearGradient(
                    Gradient(colors: [Color(hex: 0xFFEA00), Color(hex: 0xFF3D00), Color(hex: 0xD500F9)]),
                    startPoint: CGPoint(x: domeX, y: domeY),
                    endPoint: CGPoint(x: cx, y: baseHeaterY)
                )
            )

            // Uzayan üst küre başlığı
            var domeCtx = context
            domeCtx.addFilter(.blur(radius: 7))
            domeCtx.blendMode = .plusLighter
            domeCtx.opacity = 0.90 * energy
            domeCtx.fill(
                Path(ellipseIn: CGRect(x: domeX - domeRadius, y: domeY - domeRadius * 1.15, width: domeRadius * 2, height: domeRadius * 2.3)),
                with: .radialGradient(
                    Gradient(colors: [Color.white, Color(hex: 0xFFEA00), Color(hex: 0xFF3D00), .clear]),
                    center: CGPoint(x: domeX, y: domeY),
                    startRadius: 0,
                    endRadius: domeRadius * 1.15
                )
            )
        } else {
            // EVRE 2: KOPMA ANI VE YAYLANARAK YÜKSELİŞ (The Snap, Recoil & Detached Rising Blob)
            let postSnapRatio = (snapProg - 0.50) / 0.50 // 0.0 -> 1.0
            // Boyun koptuğu anda tabanın geri yaylanması (elastic recoil)
            let recoil = exp(-postSnapRatio * 6.0) * sin(postSnapRatio * .pi * 5.0) * 16.0

            // Kopan ve serbestçe yükselen magma damlası
            let detachedY = (baseHeaterY - 190.0) - CGFloat(postSnapRatio * (tubeH * 0.55))
            let detachedX = cx + CGFloat(sin(t * 0.4)) * 35.0
            // Sıvı yüzey gerilimi osilasyonu (damla şekil değiştirerek yaylanır)
            let wobble = sin(postSnapRatio * .pi * 8.0) * 0.22
            let curRx = 38.0 * (1.0 - wobble)
            let curRy = 38.0 * (1.0 + wobble)

            // Kopan damla gövdesi
            var blobCtx = context
            blobCtx.addFilter(.blur(radius: 8))
            blobCtx.blendMode = .plusLighter
            blobCtx.opacity = 0.92 * energy
            blobCtx.fill(
                Path(ellipseIn: CGRect(x: detachedX - curRx, y: detachedY - curRy, width: curRx * 2, height: curRy * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color.white, Color(hex: 0xFFEA00), Color(hex: 0xFF3D00), Color(hex: 0xD500F9).opacity(0.3), .clear]),
                    center: CGPoint(x: detachedX, y: detachedY),
                    startRadius: 0,
                    endRadius: max(curRx, curRy)
                )
            )

            // Kopma anında fırlayan küçük uydu damlacık (Satellite Snap Droplet)
            if postSnapRatio < 0.35 {
                let satelliteY = detachedY + 45.0 + CGFloat(postSnapRatio * 30.0)
                let satR: CGFloat = max(1.5, 4.5 * CGFloat(1.0 - postSnapRatio / 0.35))
                var satCtx = context
                satCtx.addFilter(.blur(radius: 2))
                satCtx.blendMode = .plusLighter
                satCtx.opacity = 0.95 * energy
                satCtx.fill(
                    Path(ellipseIn: CGRect(x: detachedX - satR, y: satelliteY - satR, width: satR * 2, height: satR * 2)),
                    with: .color(Color(hex: 0xFFEA00))
                )
            }

            // Taban rezervuarının kopma sonrası sönümlenen geri tepmesi (Base Recoil)
            var baseRecoilCtx = context
            baseRecoilCtx.addFilter(.blur(radius: 12))
            baseRecoilCtx.blendMode = .plusLighter
            baseRecoilCtx.opacity = 0.80 * energy
            baseRecoilCtx.fill(
                Path(ellipseIn: CGRect(x: cx - 45, y: baseHeaterY - 15 - CGFloat(recoil), width: 90, height: 30 + CGFloat(recoil * 0.5))),
                with: .color(Color(hex: 0xFF3D00))
            )
        }

        // Taban Isıtıcı Havuz Bloğu (Molten Base Pool)
        var basePoolCtx = context
        basePoolCtx.addFilter(.blur(radius: 22))
        basePoolCtx.blendMode = .plusLighter
        basePoolCtx.opacity = 0.85 * energy
        basePoolCtx.fill(
            Path(ellipseIn: CGRect(x: tubeLeft + 10, y: bottomY - 32, width: tubeW - 20, height: 50)),
            with: .color(Color(hex: 0xFF3D00))
        )

        // 3. SÜZÜLEN MAGMA KÜRELERİ (Floating Magma Blobs Data)
        struct LavaBlobState {
            let id: Int
            let baseProg: Double
            let relX: Double
            let baseR: CGFloat
            let speed: Double
            let mainColor: Color
            let coreColor: Color
        }

        let floatingBlobs: [LavaBlobState] = [
            LavaBlobState(id: 1, baseProg: 0.12, relX: -0.24, baseR: 54, speed: 0.08, mainColor: Color(hex: 0xFF007F), coreColor: Color(hex: 0xFF80AB)),
            LavaBlobState(id: 2, baseProg: 0.35, relX: 0.22,  baseR: 62, speed: 0.09, mainColor: Color(hex: 0xD500F9), coreColor: Color(hex: 0xEA80FC)),
            LavaBlobState(id: 3, baseProg: 0.58, relX: -0.06, baseR: 68, speed: 0.07, mainColor: Color(hex: 0xFF3D00), coreColor: Color(hex: 0xFFEA00)),
            LavaBlobState(id: 4, baseProg: 0.78, relX: 0.16,  baseR: 50, speed: 0.11, mainColor: Color(hex: 0x00E5FF), coreColor: Color(hex: 0xB2EBF2)),
            LavaBlobState(id: 5, baseProg: 0.42, relX: -0.32, baseR: 40, speed: 0.12, mainColor: Color(hex: 0xFF6D00), coreColor: Color(hex: 0xFFD54F)),
            LavaBlobState(id: 6, baseProg: 0.88, relX: 0.28,  baseR: 46, speed: 0.10, mainColor: Color(hex: 0xAA00FF), coreColor: Color(hex: 0xE1BEE7))
        ]

        // Hesaplanan anlık pozisyon ve boyutlar
        struct ComputedBlob {
            let state: LavaBlobState
            var center: CGPoint
            var currentRadius: CGFloat
            var growthRatio: CGFloat
        }

        var computed: [ComputedBlob] = []

        for b in floatingBlobs {
            let phase = t * b.speed + b.baseProg * (.pi * 2.0)
            let cycle = sin(phase)
            let normY = (cycle * 0.5 + 0.5) // 0 (alt) -> 1 (üst)
            let curY = bottomY - 50.0 - CGFloat(normY) * (tubeH - 100.0)

            let sway = sin(t * 0.14 + Double(b.id) * 1.6) * 24.0
            let curX = cx + CGFloat(b.relX) * (tubeW * 0.36) + CGFloat(sway)

            computed.append(ComputedBlob(state: b, center: CGPoint(x: curX, y: curY), currentRadius: b.baseR, growthRatio: 1.0))
        }

        // 4. ÇARPMA VE BÜYÜME DİNAMİĞİ (Collision Detection, Coalescence & Expansion)
        // İki magma küresi birbirine çarptığında:
        // a) Yarıçapları birleşerek büyür ("büyüme efekti")
        // b) Aralarında organik akışkan metaball köprüsü oluşur
        // c) Çarpma noktasında termal enerji parlaması (flare) meydana gelir
        for i in 0..<computed.count {
            for j in (i + 1)..<computed.count {
                let p1 = computed[i].center
                let p2 = computed[j].center
                let dist = hypot(p1.x - p2.x, p1.y - p2.y)
                let rSum = computed[i].currentRadius + computed[j].currentRadius

                // Çarpışma ve temas mesafesi
                if dist < (rSum + 28.0) {
                    let overlap = max(0.0, 1.0 - (dist / (rSum + 28.0)))
                    let growthBoost = CGFloat(overlap * 0.38) // %38'e varan çarpışma büyümesi!

                    computed[i].growthRatio += growthBoost
                    computed[j].growthRatio += growthBoost

                    // Organik akışkan köprü (Metaball Neck Fusion)
                    let midP = CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5)
                    let bridgeWidth = (rSum * 0.48) * CGFloat(overlap)

                    var bridgeCtx = context
                    bridgeCtx.addFilter(.blur(radius: 11))
                    bridgeCtx.blendMode = .plusLighter
                    bridgeCtx.opacity = (0.75 * overlap) * energy

                    var bridgePath = Path()
                    bridgePath.move(to: p1)
                    bridgePath.addQuadCurve(to: p2, control: midP)
                    bridgeCtx.stroke(
                        bridgePath,
                        with: .color(computed[i].state.mainColor),
                        lineWidth: bridgeWidth
                    )

                    // Çarpışma noktasında yoğunlaşan termal beyaz/sarı ışık patlaması (Impact Flare)
                    if overlap > 0.40 {
                        var flareCtx = context
                        flareCtx.addFilter(.blur(radius: 8))
                        flareCtx.blendMode = .plusLighter
                        flareCtx.opacity = Double(overlap) * 0.85 * energy
                        let flareR = CGFloat(16.0 * overlap)
                        flareCtx.fill(
                            Path(ellipseIn: CGRect(x: midP.x - flareR, y: midP.y - flareR, width: flareR * 2, height: flareR * 2)),
                            with: .color(Color(hex: 0xFFFFF0))
                        )
                    }
                }
            }
        }

        // 5. BÜYÜMÜŞ VE ŞEKİLLENMİŞ MAGMA KÜRELERİNİ ÇİZ (Render Coalesced Magma Blobs)
        for b in computed {
            let finalR = b.currentRadius * b.growthRatio
            let curX = b.center.x
            let curY = b.center.y

            // Dikey hız uzaması (viscous squash & stretch)
            let velocity = cos(t * b.state.speed + b.state.baseProg * (.pi * 2.0))
            let stretchY = 1.0 + abs(velocity) * 0.28
            let squashX = 1.0 - abs(velocity) * 0.18

            let rx = finalR * CGFloat(squashX)
            let ry = finalR * CGFloat(stretchY)

            // Dış termal aura
            var auraCtx = context
            auraCtx.addFilter(.blur(radius: 24))
            auraCtx.blendMode = .plusLighter
            auraCtx.opacity = 0.42 * energy
            auraCtx.fill(
                Path(ellipseIn: CGRect(x: curX - rx * 1.35, y: curY - ry * 1.35, width: rx * 2.7, height: ry * 2.7)),
                with: .color(b.state.mainColor)
            )

            // Magma gövdesi (erimiş renk gradyanı)
            var blobCtx = context
            blobCtx.addFilter(.blur(radius: 9))
            blobCtx.blendMode = .plusLighter
            blobCtx.opacity = 0.82 * energy
            blobCtx.fill(
                Path(ellipseIn: CGRect(x: curX - rx, y: curY - ry, width: rx * 2, height: ry * 2)),
                with: .radialGradient(
                    Gradient(colors: [
                        b.state.coreColor,
                        b.state.mainColor,
                        b.state.mainColor.opacity(0.35),
                        .clear
                    ]),
                    center: CGPoint(x: curX, y: curY),
                    startRadius: 0,
                    endRadius: max(rx, ry)
                )
            )

            // Akkor sıcak çekirdek
            var coreCtx = context
            coreCtx.addFilter(.blur(radius: 3))
            coreCtx.blendMode = .plusLighter
            coreCtx.opacity = 0.90 * energy
            coreCtx.fill(
                Path(ellipseIn: CGRect(x: curX - rx * 0.38, y: curY - ry * 0.38, width: rx * 0.76, height: ry * 0.76)),
                with: .color(Color.white)
            )
        }

        // 6. ÜST SOĞUMA HAVUZU (Top Cooling Liquid Cap)
        var topCapCtx = context
        topCapCtx.addFilter(.blur(radius: 20))
        topCapCtx.blendMode = .plusLighter
        topCapCtx.opacity = 0.55 * energy
        topCapCtx.fill(
            Path(ellipseIn: CGRect(x: tubeLeft + 15, y: topY - 15, width: tubeW - 30, height: 40)),
            with: .color(Color(hex: 0x9C27B0))
        )

        // 7. YAVAŞÇA YÜKSELEN MİKRO SIVI KABARCIKLARI (Rising Micro-Bubbles)
        for i in 0..<12 {
            let seed = Double(i) * 6.81
            let bubbleProg = (t * 0.14 + seed * 0.12).truncatingRemainder(dividingBy: 1.0)
            let by = bottomY - CGFloat(bubbleProg) * (tubeH * 0.90)
            let bx = cx + sin(bubbleProg * 6.5 + seed) * (tubeW * 0.36)
            let br: CGFloat = 1.8 + CGFloat(sin(seed)) * 1.4

            var bubbleCtx = context
            bubbleCtx.addFilter(.blur(radius: 1.2))
            bubbleCtx.blendMode = .plusLighter
            bubbleCtx.opacity = (0.50 + sin(t * 0.45 + seed) * 0.30) * energy

            bubbleCtx.fill(
                Path(ellipseIn: CGRect(x: bx - br, y: by - br, width: br * 2, height: br * 2)),
                with: .color(Color(hex: 0xFFEA00))
            )
        }
    }

    // MARK: - 11. Dinamik Sahne Işık Oyunları & Spektral Prizmatik Lazer Huzmeleri (Light Show)
    // Sahne/oda içerisinde ritmik ve büyüleyici şekilde kesişen hacimsel ışık konileri,
    // lazer huzmeleri, prizmatik renk kırınımları ve dans eden optik yansımalar.
    private func drawPrismaticLightShowBeams(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let cx = size.width * 0.5
        let cy = size.height * 0.5

        let beamColors: [Color] = [
            Color(hex: 0x00F0FF),
            Color(hex: 0xFF007F),
            Color(hex: 0x7C4DFF),
            Color(hex: 0x00E676),
            Color(hex: 0xFFD600),
            Color(hex: 0x00B0FF)
        ]

        // 1. TAVANDAN VE KÖŞELERDEN YAYILAN 6 HACİMSEL IŞIK KONİSİ (Volumetric Searchlight Cones)
        let beamCount = 6
        for i in 0..<beamCount {
            let isTopOrigin = (i < 4)

            let originX = isTopOrigin ? (size.width * (0.15 + Double(i) * 0.24)) : (i == 4 ? -20 : size.width + 20)
            let originY = isTopOrigin ? -20.0 : size.height * 0.85

            let sweep = sin(t * 0.16 + Double(i) * 1.3) * 0.45 + cos(t * 0.08 + Double(i)) * 0.18
            let baseAngle: Double
            if isTopOrigin {
                baseAngle = .pi * 0.5 + sweep
            } else {
                baseAngle = (i == 4 ? -0.4 : -.pi + 0.4) + sweep
            }

            let beamLength = max(size.width, size.height) * 1.35
            let endX = originX + cos(baseAngle) * beamLength
            let endY = originY + sin(baseAngle) * beamLength

            let spreadAngle = 0.14
            let leftEndX = originX + cos(baseAngle - spreadAngle) * beamLength
            let leftEndY = originY + sin(baseAngle - spreadAngle) * beamLength
            let rightEndX = originX + cos(baseAngle + spreadAngle) * beamLength
            let rightEndY = originY + sin(baseAngle + spreadAngle) * beamLength

            var conePath = Path()
            conePath.move(to: CGPoint(x: originX, y: originY))
            conePath.addLine(to: CGPoint(x: leftEndX, y: leftEndY))
            conePath.addLine(to: CGPoint(x: rightEndX, y: rightEndY))
            conePath.closeSubpath()

            let col = beamColors[i % beamColors.count]

            var coneCtx = context
            coneCtx.addFilter(.blur(radius: 28))
            coneCtx.blendMode = .plusLighter
            coneCtx.opacity = 0.32 * energy

            coneCtx.fill(
                conePath,
                with: .linearGradient(
                    Gradient(colors: [
                        col.opacity(0.85),
                        col.opacity(0.40),
                        .clear
                    ]),
                    startPoint: CGPoint(x: originX, y: originY),
                    endPoint: CGPoint(x: endX, y: endY)
                )
            )

            var laserPath = Path()
            laserPath.move(to: CGPoint(x: originX, y: originY))
            laserPath.addLine(to: CGPoint(x: endX, y: endY))

            var laserCtx = context
            laserCtx.addFilter(.blur(radius: 3.5))
            laserCtx.blendMode = .plusLighter
            laserCtx.opacity = 0.75 * energy

            laserCtx.stroke(
                laserPath,
                with: .linearGradient(
                    Gradient(colors: [Color.white, col, .clear]),
                    startPoint: CGPoint(x: originX, y: originY),
                    endPoint: CGPoint(x: endX, y: endY)
                ),
                lineWidth: 2.4
            )
        }

        // 2. ORTA MERKEZDE KESİŞEN OPTİK KIRINIM HALESİ (Optical Caustic Focal Flare)
        var flareCtx = context
        flareCtx.addFilter(.blur(radius: 45))
        flareCtx.blendMode = .plusLighter
        let flarePulse = sin(t * 0.28) * 0.15
        flareCtx.opacity = (0.42 + flarePulse) * energy
        flareCtx.fill(
            Path(ellipseIn: CGRect(x: cx - 110, y: cy - 70, width: 220, height: 140)),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color(hex: 0x00F0FF).opacity(0.70),
                    Color(hex: 0xFF007F).opacity(0.35),
                    .clear
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: 110
            )
        )

        // 3. TARAYAN SPEKTRAL IŞIK DALGALARI (Optical Horizontal Sweep Waves)
        for i in 0..<4 {
            let seed = Double(i) * 2.81
            let scanProg = (t * 0.08 + seed * 0.25).truncatingRemainder(dividingBy: 1.0)
            let scanY = size.height * CGFloat(scanProg)

            var scanCtx = context
            scanCtx.addFilter(.blur(radius: 12))
            scanCtx.blendMode = .plusLighter
            scanCtx.opacity = (0.24 * (1.0 - abs(scanProg - 0.5) * 1.5)) * energy

            var scanPath = Path()
            scanPath.move(to: CGPoint(x: 0, y: scanY))
            scanPath.addLine(to: CGPoint(x: size.width, y: scanY + 15.0))

            scanCtx.stroke(
                scanPath,
                with: .linearGradient(
                    Gradient(colors: [.clear, Color(hex: 0x00E5FF).opacity(0.7), Color(hex: 0xFF007F).opacity(0.7), .clear]),
                    startPoint: CGPoint(x: 0, y: scanY),
                    endPoint: CGPoint(x: size.width, y: scanY)
                ),
                lineWidth: 2.0
            )
        }

        // 4. IŞIK DEMETLERİNDE PARILDAYAN TOZ VE FLARE TANECİKLERİ (Dancing Beam Flares)
        for i in 0..<20 {
            let seed = Double(i) * 4.91
            let px = size.width * (sin(seed * 2.1 + t * 0.05) * 0.45 + 0.5)
            let py = size.height * (cos(seed * 1.7 + t * 0.04) * 0.45 + 0.5)
            let r: CGFloat = 1.8 + CGFloat(sin(seed)) * 1.6

            var sparkleCtx = context
            sparkleCtx.addFilter(.blur(radius: 1.2))
            sparkleCtx.blendMode = .plusLighter
            let flash = pow(sin(t * 0.6 + seed) * 0.5 + 0.5, 3.0)
            sparkleCtx.opacity = (0.20 + flash * 0.70) * energy

            sparkleCtx.fill(
                Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                with: .color(Color.white)
            )
        }
    }

    // MARK: - A. Çam Ağaçları & Gece Ormanı Ateşböcekleri (Pine Forest Silhouette & Fireflies)

    private func drawPineForestAndFireflies(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let forestBaseY = size.height * 0.94

        // 1. Arka Plan Puslu Çam Tepeleri (Distant Misty Pines)
        let bgTreeCount = 14
        var bgForestPath = Path()
        for i in 0..<bgTreeCount {
            let seed = Double(i) * 4.19
            let tx = size.width * (CGFloat(i) / CGFloat(bgTreeCount - 1)) + CGFloat(sin(seed)) * 12.0
            let treeH: CGFloat = 70.0 + CGFloat(sin(seed * 2.3) * 0.5 + 0.5) * 45.0
            let treeW: CGFloat = 26.0 + CGFloat(sin(seed * 1.7) * 0.5 + 0.5) * 16.0
            let ty = forestBaseY - CGFloat(sin(Double(i) * 0.45)) * 18.0

            appendPineTree(to: &bgForestPath, at: CGPoint(x: tx, y: ty), width: treeW, height: treeH)
        }

        var bgForestCtx = context
        bgForestCtx.addFilter(.blur(radius: 4.5))
        bgForestCtx.opacity = 0.55 * energy
        let bgForestColor = colors.bgColors.first?.opacity(0.85) ?? Color.black.opacity(0.85)
        bgForestCtx.fill(bgForestPath, with: .color(bgForestColor))

        // 2. Ön Plan Detaylı Çam Ağaçları Silüeti (Sharp Foreground Pine Horizon)
        let fgTreeCount = 9
        var fgForestPath = Path()
        for i in 0..<fgTreeCount {
            let seed = Double(i) * 6.71 + 1.5
            let tx = size.width * (CGFloat(i) / CGFloat(fgTreeCount - 1)) + CGFloat(cos(seed)) * 18.0
            let treeH: CGFloat = 95.0 + CGFloat(sin(seed * 2.8) * 0.5 + 0.5) * 60.0
            let treeW: CGFloat = 38.0 + CGFloat(sin(seed * 1.4) * 0.5 + 0.5) * 20.0
            let ty = forestBaseY + 12.0

            appendPineTree(to: &fgForestPath, at: CGPoint(x: tx, y: ty), width: treeW, height: treeH)
        }

        var fgForestCtx = context
        fgForestCtx.addFilter(.blur(radius: 0.8))
        fgForestCtx.opacity = 0.88 * energy
        fgForestCtx.fill(fgForestPath, with: .color(Color(hex: 0x02060D)))

        // 3. Çam Ağaçları Arasında Uçuşan Biyo-lüminesans Ateşböcekleri (Glowing Fireflies)
        let fireflyCount = 12
        for i in 0..<fireflyCount {
            let seed = Double(i) * 5.37
            let flyProg = t * 0.18 + seed
            let fx = size.width * 0.5 + sin(flyProg * 0.6 + seed) * (size.width * 0.44)
            let fy = (forestBaseY - 110.0) + cos(flyProg * 0.8 + seed * 1.3) * 60.0 + sin(t * 0.12 + seed) * 20.0

            let glowPulse = pow(sin(t * 0.8 + seed * 2.0) * 0.5 + 0.5, 3.0)
            guard glowPulse > 0.05 else { continue }

            let r: CGFloat = 2.0 + CGFloat(glowPulse * 1.8)

            var flyCtx = context
            flyCtx.addFilter(.blur(radius: 3.5))
            flyCtx.blendMode = .plusLighter
            flyCtx.opacity = (0.35 + glowPulse * 0.60) * energy

            flyCtx.fill(
                Path(ellipseIn: CGRect(x: fx - r * 2.5, y: fy - r * 2.5, width: r * 5.0, height: r * 5.0)),
                with: .color(Color(hex: 0xD4E157).opacity(0.4))
            )

            var coreCtx = context
            coreCtx.addFilter(.blur(radius: 0.6))
            coreCtx.blendMode = .plusLighter
            coreCtx.opacity = (0.75 + glowPulse * 0.25) * energy
            coreCtx.fill(
                Path(ellipseIn: CGRect(x: fx - r, y: fy - r, width: r * 2.0, height: r * 2.0)),
                with: .color(Color(hex: 0xFFF9C4))
            )
        }
    }

    private func appendPineTree(to path: inout Path, at base: CGPoint, width: CGFloat, height: CGFloat) {
        let trunkW = max(3.0, width * 0.14)
        let trunkH = height * 0.20
        path.addRect(CGRect(x: base.x - trunkW * 0.5, y: base.y - trunkH, width: trunkW, height: trunkH))

        let foliageH = height - trunkH
        let tiers = 4
        for tier in 0..<tiers {
            let tierFrac = CGFloat(tier) / CGFloat(tiers)
            let tierBaseY = base.y - trunkH - tierFrac * (foliageH * 0.80)
            let tierTopY = tierBaseY - (foliageH * 0.38)
            let tierW = width * (1.0 - tierFrac * 0.24)

            path.move(to: CGPoint(x: base.x, y: tierTopY))
            path.addLine(to: CGPoint(x: base.x + tierW * 0.5, y: tierBaseY))
            path.addQuadCurve(
                to: CGPoint(x: base.x - tierW * 0.5, y: tierBaseY),
                control: CGPoint(x: base.x, y: tierBaseY - 4.0)
            )
            path.closeSubpath()
        }
    }

    // MARK: - B. Çiçek Bahçeleri & Süzülen Çiçek Yaprakları (Floating Botanical Petals)

    private func drawBotanicalFlowerPetals(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let petalCount = 18
        for i in 0..<petalCount {
            let seed = Double(i) * 7.91
            let z = 0.2 + (sin(seed * 2.4) * 0.5 + 0.5) * 0.8

            let driftSpeed = 16.0 + z * 24.0
            let fallSpeed = 22.0 + z * 32.0

            let rawX = (seed * 97.0 + t * driftSpeed)
            let sway = sin(t * 0.35 + seed * 1.5) * (35.0 + z * 30.0)
            let px = (rawX + sway).truncatingRemainder(dividingBy: size.width + 120.0) - 60.0

            let py = (seed * 137.0 + t * fallSpeed).truncatingRemainder(dividingBy: size.height + 100.0) - 50.0

            let spinAngle = t * (0.8 + z * 0.6) + seed * 2.0
            let rollFrac = abs(cos(spinAngle))
            let tiltAngle = sin(t * 0.4 + seed) * 0.45

            let baseR: CGFloat = 4.5 + CGFloat(z * 6.5)
            let petalW = max(1.5, baseR * CGFloat(rollFrac) * 1.4)
            let petalH = baseR * 1.8

            var petalPath = Path()
            petalPath.move(to: CGPoint(x: 0, y: petalH * 0.5))
            petalPath.addCurve(
                to: CGPoint(x: 0, y: -petalH * 0.5),
                control1: CGPoint(x: -petalW, y: petalH * 0.2),
                control2: CGPoint(x: -petalW * 0.8, y: -petalH * 0.4)
            )
            petalPath.addCurve(
                to: CGPoint(x: 0, y: petalH * 0.5),
                control1: CGPoint(x: petalW * 0.8, y: -petalH * 0.4),
                control2: CGPoint(x: petalW, y: petalH * 0.2)
            )

            var pCtx = context
            pCtx.translateBy(x: px, y: py)
            pCtx.rotate(by: .radians(tiltAngle + spinAngle * 0.2))

            let blurAmount = (1.0 - z) * 2.2 + 0.3
            pCtx.addFilter(.blur(radius: blurAmount))
            pCtx.blendMode = .plusLighter
            pCtx.opacity = (0.35 + z * 0.50) * energy

            let isPink = (i % 3 != 0)
            let petalColor1 = isPink ? Color(hex: 0xFF80AB) : Color(hex: 0xFFD54F)
            let petalColor2 = isPink ? Color(hex: 0xFFE082) : Color(hex: 0xFF8A65)

            pCtx.fill(
                petalPath,
                with: .linearGradient(
                    Gradient(colors: [petalColor1.opacity(0.85), petalColor2.opacity(0.60), Color.white.opacity(0.40)]),
                    startPoint: CGPoint(x: -petalW * 0.5, y: -petalH * 0.5),
                    endPoint: CGPoint(x: petalW * 0.5, y: petalH * 0.5)
                )
            )
        }
    }

    // MARK: - C. Gerçekçi Yağmur & Konsantrik Su Dalgalanma Halkaları (Rain Ripples & Splashes)

    private func drawRainPuddleRipplesAndSplashes(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let puddleBaseY = size.height * 0.88
        let rippleCenters: [(x: CGFloat, y: CGFloat, seed: Double)] = [
            (size.width * 0.18, puddleBaseY - 14.0, 1.2),
            (size.width * 0.38, puddleBaseY + 12.0, 3.7),
            (size.width * 0.62, puddleBaseY - 6.0, 5.1),
            (size.width * 0.82, puddleBaseY + 18.0, 7.8),
            (size.width * 0.50, puddleBaseY + 28.0, 9.4)
        ]

        for item in rippleCenters {
            let period = 2.4
            let cycle = (t / period + item.seed).truncatingRemainder(dividingBy: 1.0)

            for ringIdx in 0..<2 {
                let ringPhase = (cycle + Double(ringIdx) * 0.28).truncatingRemainder(dividingBy: 1.0)
                let maxRx: CGFloat = 32.0 + CGFloat(item.seed * 3.0)
                let rx = maxRx * CGFloat(ringPhase)
                let ry = rx * 0.34

                guard rx > 2.0 else { continue }

                var ringCtx = context
                ringCtx.addFilter(.blur(radius: 1.0))
                ringCtx.blendMode = .plusLighter
                let alpha = (1.0 - ringPhase) * 0.45 * energy
                ringCtx.opacity = max(0.0, alpha)

                let rippleRect = CGRect(x: item.x - rx, y: item.y - ry, width: rx * 2.0, height: ry * 2.0)
                ringCtx.stroke(
                    Path(ellipseIn: rippleRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            colors.accentColor.opacity(0.8),
                            Color.white.opacity(0.9),
                            colors.accentColor.opacity(0.3)
                        ]),
                        startPoint: CGPoint(x: item.x - rx, y: item.y),
                        endPoint: CGPoint(x: item.x + rx, y: item.y)
                    ),
                    lineWidth: CGFloat(1.4 - ringPhase * 0.8)
                )
            }

            if cycle < 0.25 {
                let splashProg = cycle / 0.25
                let splashH = sin(splashProg * .pi) * 8.0
                let splashY = item.y - CGFloat(splashH)

                var splashCtx = context
                splashCtx.addFilter(.blur(radius: 0.8))
                splashCtx.blendMode = .plusLighter
                splashCtx.opacity = (1.0 - splashProg) * 0.70 * energy
                splashCtx.fill(
                    Path(ellipseIn: CGRect(x: item.x - 1.2, y: splashY - 1.2, width: 2.4, height: 2.4)),
                    with: .color(Color.white)
                )
            }
        }
    }

    // MARK: - D. Akarsu & Yaşayan Nehir Akıntıları, Deniz Köpükleri (Living Stream & Sea Foam)

    private func drawLivingOceanWavesAndStreamCurrents(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let streamY = size.height * 0.60

        // 1. Akarsu Yüzey Işıltısı ve Nehir Şeritleri (Flowing Water Ribbons)
        let ribbonCount = 5
        for i in 0..<ribbonCount {
            let normIdx = Double(i) / Double(ribbonCount)
            let baseY = streamY + CGFloat(i * 22)
            let amp = (8.0 + Double(i) * 4.0) * energy

            var foamPath = Path()
            let steps = 40
            for s in 0...steps {
                let xNorm = Double(s) / Double(steps)
                let x = size.width * CGFloat(xNorm)

                let w1 = sin(xNorm * 5.2 - t * 0.35 + Double(i) * 1.5) * 0.6
                let w2 = cos(xNorm * 3.4 + t * 0.22 + Double(i) * 0.8) * 0.4
                let y = baseY + (w1 + w2) * amp

                if s == 0 {
                    foamPath.move(to: CGPoint(x: x, y: y))
                } else {
                    foamPath.addLine(to: CGPoint(x: x, y: y))
                }
            }

            var foamCtx = context
            foamCtx.addFilter(.blur(radius: 1.8 + normIdx * 2.0))
            foamCtx.blendMode = .plusLighter
            let foamAlpha = (0.28 + sin(t * 0.4 + Double(i) * 1.1) * 0.12) * energy
            foamCtx.opacity = max(0.08, foamAlpha)

            foamCtx.stroke(
                foamPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.85),
                        colors.accentColor.opacity(0.70),
                        colors.glowColor.opacity(0.20)
                    ]),
                    startPoint: CGPoint(x: 0, y: baseY),
                    endPoint: CGPoint(x: size.width, y: baseY)
                ),
                lineWidth: CGFloat(1.5 + normIdx * 1.8)
            )
        }

        // 2. Yakamoz & Güneş/Ay Işıltı Yansıması (Specular Riverbed Shimmer)
        let glintCount = 14
        for i in 0..<glintCount {
            let seed = Double(i) * 4.87
            let gx = size.width * (0.25 + CGFloat(sin(seed + t * 0.08)) * 0.35)
            let gy = streamY + 20.0 + CGFloat((i % 4) * 22) + CGFloat(cos(t * 0.25 + seed)) * 8.0

            let glintW = 12.0 + CGFloat(sin(t * 0.5 + seed)) * 8.0
            let glintH = 2.2 + CGFloat(cos(t * 0.4 + seed)) * 1.0

            var glintCtx = context
            glintCtx.addFilter(.blur(radius: 1.2))
            glintCtx.blendMode = .plusLighter
            let glintFlash = pow(sin(t * 0.7 + seed) * 0.5 + 0.5, 2.5)
            glintCtx.opacity = (0.25 + glintFlash * 0.65) * energy

            glintCtx.fill(
                Path(ellipseIn: CGRect(x: gx - glintW * 0.5, y: gy - glintH * 0.5, width: glintW, height: glintH)),
                with: .color(Color.white)
            )
        }
    }

    // MARK: - E. Gökyüzü, Parlayan Yıldızlar & Kayan Yıldız (Twinkling Stars & Shooting Star)

    private func drawTwinklingStarsAndShootingStar(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let starCount = 32
        for i in 0..<starCount {
            let seed = Double(i) * 6.31
            let sx = (sin(seed * 3.7) * 0.5 + 0.5) * size.width
            let sy = (sin(seed * 5.1) * 0.5 + 0.5) * (size.height * 0.46)

            let z = 0.2 + (sin(seed * 1.9) * 0.5 + 0.5) * 0.8
            let twinkle = pow(sin(t * (0.4 + z * 0.5) + seed) * 0.5 + 0.5, 3.0)

            let r: CGFloat = 1.0 + CGFloat(z * 1.8)

            var starCtx = context
            starCtx.addFilter(.blur(radius: (1.0 - z) * 1.2 + 0.4))
            starCtx.blendMode = .plusLighter
            starCtx.opacity = (0.25 + twinkle * 0.70) * energy

            starCtx.fill(
                Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2.0, height: r * 2.0)),
                with: .color(z > 0.7 ? Color.white : colors.accentColor)
            )

            if z > 0.85 && twinkle > 0.65 {
                var spikeCtx = context
                spikeCtx.addFilter(.blur(radius: 0.5))
                spikeCtx.blendMode = .plusLighter
                spikeCtx.opacity = Double(twinkle) * 0.60 * energy
                let spikeLen: CGFloat = 6.0 + CGFloat(twinkle * 4.0)

                var spikePath = Path()
                spikePath.move(to: CGPoint(x: sx - spikeLen, y: sy))
                spikePath.addLine(to: CGPoint(x: sx + spikeLen, y: sy))
                spikePath.move(to: CGPoint(x: sx, y: sy - spikeLen))
                spikePath.addLine(to: CGPoint(x: sx, y: sy + spikeLen))
                spikeCtx.stroke(spikePath, with: .color(Color.white), lineWidth: 0.8)
            }
        }

        let meteorPeriod = 20.0
        let meteorProg = (t / meteorPeriod).truncatingRemainder(dividingBy: 1.0)
        if meteorProg < 0.12 {
            let u = meteorProg / 0.12
            let startX = size.width * 0.15
            let startY = size.height * 0.08
            let endX = size.width * 0.85
            let endY = size.height * 0.32

            let headX = startX + (endX - startX) * CGFloat(u)
            let headY = startY + (endY - startY) * CGFloat(u)

            let tailLen: CGFloat = 85.0
            let dirX = (endX - startX)
            let dirY = (endY - startY)
            let dirNorm = hypot(dirX, dirY)
            let tailX = headX - (dirX / dirNorm) * tailLen * CGFloat(sin(u * .pi))
            let tailY = headY - (dirY / dirNorm) * tailLen * CGFloat(sin(u * .pi))

            var meteorPath = Path()
            meteorPath.move(to: CGPoint(x: tailX, y: tailY))
            meteorPath.addLine(to: CGPoint(x: headX, y: headY))

            var meteorCtx = context
            meteorCtx.addFilter(.blur(radius: 1.2))
            meteorCtx.blendMode = .plusLighter
            let alpha = sin(u * .pi) * 0.90 * energy
            meteorCtx.opacity = alpha

            meteorCtx.stroke(
                meteorPath,
                with: .linearGradient(
                    Gradient(colors: [.clear, colors.accentColor.opacity(0.6), Color.white]),
                    startPoint: CGPoint(x: tailX, y: tailY),
                    endPoint: CGPoint(x: headX, y: headY)
                ),
                lineWidth: 1.8
            )

            var headCtx = context
            headCtx.addFilter(.blur(radius: 3.0))
            headCtx.blendMode = .plusLighter
            headCtx.opacity = alpha
            headCtx.fill(
                Path(ellipseIn: CGRect(x: headX - 4.0, y: headY - 4.0, width: 8.0, height: 8.0)),
                with: .color(Color.white)
            )
        }
    }

    // MARK: - F. Parlak Güneş & Hacimsel Işık Hüzmeleri (Radiant Sun & God-Rays)

    private func drawRadiantSunAndGodRays(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        colors: ContextGradient,
        energy: Double
    ) {
        let sunX = size.width * 0.78
        let sunY = size.height * 0.20
        let sunCoreRadius: CGFloat = 55.0

        let breathe = sin(t * 0.22) * 6.0
        var coronaCtx = context
        coronaCtx.addFilter(.blur(radius: 40))
        coronaCtx.blendMode = .plusLighter
        coronaCtx.opacity = (0.58 + sin(t * 0.18) * 0.10) * energy
        coronaCtx.fill(
            Path(ellipseIn: CGRect(x: sunX - sunCoreRadius - CGFloat(breathe), y: sunY - sunCoreRadius - CGFloat(breathe), width: (sunCoreRadius + CGFloat(breathe)) * 2, height: (sunCoreRadius + CGFloat(breathe)) * 2)),
            with: .radialGradient(
                Gradient(colors: [
                    Color(hex: 0xFFFDE7),
                    Color(hex: 0xFFD54F).opacity(0.85),
                    Color(hex: 0xFF8A65).opacity(0.40),
                    .clear
                ]),
                center: CGPoint(x: sunX, y: sunY),
                startRadius: 0,
                endRadius: (sunCoreRadius + CGFloat(breathe)) * 1.8
            )
        )

        let rayCount = 7
        for i in 0..<rayCount {
            let baseAngle = .pi * 0.65 + Double(i) * 0.14
            let sweep = sin(t * 0.12 + Double(i) * 1.4) * 0.08
            let rayAngle = baseAngle + sweep
            let rayLength = max(size.width, size.height) * 1.25

            let spread = 0.09
            let leftEndX = sunX + cos(rayAngle - spread) * rayLength
            let leftEndY = sunY + sin(rayAngle - spread) * rayLength
            let rightEndX = sunX + cos(rayAngle + spread) * rayLength
            let rightEndY = sunY + sin(rayAngle + spread) * rayLength

            var rayPath = Path()
            rayPath.move(to: CGPoint(x: sunX, y: sunY))
            rayPath.addLine(to: CGPoint(x: leftEndX, y: leftEndY))
            rayPath.addLine(to: CGPoint(x: rightEndX, y: rightEndY))
            rayPath.closeSubpath()

            var rayCtx = context
            rayCtx.addFilter(.blur(radius: 26))
            rayCtx.blendMode = .plusLighter
            let rayPulse = sin(t * 0.20 + Double(i) * 0.9) * 0.06
            rayCtx.opacity = (0.24 + rayPulse) * energy

            rayCtx.fill(
                rayPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(hex: 0xFFF9C4).opacity(0.70),
                        Color(hex: 0xFFE082).opacity(0.35),
                        .clear
                    ]),
                    startPoint: CGPoint(x: sunX, y: sunY),
                    endPoint: CGPoint(x: (leftEndX + rightEndX) * 0.5, y: (leftEndY + rightEndY) * 0.5)
                )
            )
        }

        for i in 0..<16 {
            let seed = Double(i) * 4.73
            let mx = size.width * (0.25 + CGFloat(sin(seed + t * 0.06)) * 0.40)
            let my = size.height * (0.35 + CGFloat(cos(seed * 1.5 + t * 0.05)) * 0.35)
            let r: CGFloat = 1.5 + CGFloat(sin(seed)) * 1.4

            var moteCtx = context
            moteCtx.addFilter(.blur(radius: 1.0))
            moteCtx.blendMode = .plusLighter
            let flash = pow(sin(t * 0.45 + seed) * 0.5 + 0.5, 2.0)
            moteCtx.opacity = (0.20 + flash * 0.55) * energy

            moteCtx.fill(
                Path(ellipseIn: CGRect(x: mx - r, y: my - r, width: r * 2.0, height: r * 2.0)),
                with: .color(Color(hex: 0xFFF9C4))
            )
        }
    }
}
