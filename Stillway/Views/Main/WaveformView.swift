import SwiftUI

struct WaveformView: View {
    @Environment(ThemeEngine.self) private var theme
    @Environment(AudioEngine.self) private var audio
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let config = theme.waveConfig
        let colors = theme.gradient.waveColors
        let energy = audio.isPlaying ? 1.0 : 0.55

        if reduceMotion {
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .opacity(config.opacity * 0.35)
                .mask(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .blur(radius: 8)
                .padding(.horizontal, 28)
        } else {
            // Periodic keeps waves alive during taps/drags.
            TimelineView(.periodic(from: .now, by: 1.0 / 16.0)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate

                    // Luminous atmospheric horizon beam across center (matching build 17 screenshots)
                    let barH: CGFloat = 26.0
                    let barY = size.height * 0.5 - barH * 0.5
                    let barRect = CGRect(x: 16, y: barY, width: size.width - 32, height: barH)
                    var barCtx = context
                    barCtx.addFilter(.blur(radius: 14))
                    barCtx.blendMode = .plusLighter
                    let barGrad = Gradient(colors: colors.map { $0.opacity(0.72 * energy) })
                    barCtx.fill(
                        Path(roundedRect: barRect, cornerRadius: 13),
                        with: .linearGradient(barGrad, startPoint: CGPoint(x: 0, y: barY), endPoint: CGPoint(x: size.width, y: barY))
                    )
                    let layers = max(1, config.layerCount)
                    for layer in 0..<layers {
                        var path = Path()
                        let layerOffset = Double(layer) * 0.9
                        let amp = theme.effectiveAmplitude * energy * (1.0 - Double(layer) * 0.22)
                        let yBase = size.height * 0.52 + CGFloat(layer) * 14
                        path.move(to: CGPoint(x: 0, y: yBase))
                        let steps = Int(size.width / 6)
                        for i in 0...steps {
                            let x = size.width * CGFloat(i) / CGFloat(steps)
                            let phase = t * config.phaseSpeed * 0.85 + layerOffset
                            let slow = sin(Double(x) / size.width * .pi * 2 * config.frequency + phase)
                            let soft = sin(Double(x) / size.width * .pi * config.frequency * 0.45 + phase * 0.55) * 0.4
                            let y = yBase + CGFloat((slow + soft) * amp)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: size.width, y: size.height))
                        path.addLine(to: CGPoint(x: 0, y: size.height))
                        path.closeSubpath()

                        var layerContext = context
                        layerContext.addFilter(.blur(radius: 3 + Double(layer) * 2))
                        layerContext.blendMode = .plusLighter
                        let gradient = Gradient(colors: colors.map {
                            $0.opacity(config.opacity * energy * (0.38 - Double(layer) * 0.07))
                        })
                        layerContext.fill(
                            path,
                            with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
                        )
                    }
                }
            }
            .blur(radius: 5)
            .allowsHitTesting(false)
        }
    }
}
