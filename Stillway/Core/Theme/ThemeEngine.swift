import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ThemeEngine {
    /// Logical context after the latest request.
    var currentContext: AppContext = .focus
    var currentSoundID: String? = nil
    var isTransitioning = false
    /// 0 = outgoing palette, 1 = incoming. Animates for soft theme morphs.
    var blendProgress: Double = 1
    /// Kept near 1 — no hard collapse/flip on theme change.
    var transitionAmplitude: Double = 1

    private var fromGradient: ContextGradient = ContextGradient.gradient(for: .focus)
    private var toGradient: ContextGradient = ContextGradient.gradient(for: .focus)
    private var fromWave: WaveConfig = WaveConfig.config(for: .focus)
    private var toWave: WaveConfig = WaveConfig.config(for: .focus)
    private var transitionTask: Task<Void, Never>?

    var displayedContext: AppContext { currentContext }

    var gradient: ContextGradient {
        ContextGradient.blended(from: fromGradient, to: toGradient, t: blendProgress)
    }

    var waveConfig: WaveConfig {
        WaveConfig.blended(from: fromWave, to: toWave, t: blendProgress)
    }

    var effectiveAmplitude: Double { waveConfig.amplitude * transitionAmplitude }
    var waveAmplitudeScale: Double { transitionAmplitude }

    /// Soft theme morph — weather-like palette shift (peak theme work).
    static let morphDuration: TimeInterval = 4.8

    func apply(soundID: String? = nil, context: AppContext) {
        let soundChanged = soundID != nil && soundID != currentSoundID
        let contextChanged = context != currentContext
        currentSoundID = soundID
        guard contextChanged || soundChanged || blendProgress < 0.999 else { return }
        transitionTask?.cancel()
        transitionTask = Task { await transition(to: context, soundID: soundID) }
    }

    func apply(context: AppContext) {
        apply(soundID: currentSoundID, context: context)
    }

    func apply(_ context: AppContext) {
        apply(context: context)
    }

    /// Instant set for first paint / defaults — no animation.
    func setImmediate(_ context: AppContext) {
        transitionTask?.cancel()
        currentContext = context
        let g = ContextGradient.gradient(for: context)
        let w = WaveConfig.config(for: context)
        fromGradient = g
        toGradient = g
        fromWave = w
        toWave = w
        blendProgress = 1
        transitionAmplitude = 1
        isTransitioning = false
    }

    func transition(to context: AppContext, soundID: String? = nil) async {
        let visualGradient = gradient
        let visualWave = waveConfig
        fromGradient = visualGradient
        fromWave = visualWave
        toGradient = ContextGradient.gradient(for: soundID ?? currentSoundID, context: context)
        toWave = WaveConfig.config(for: context)
        currentContext = context
        blendProgress = 0
        isTransitioning = true

        // Gentle breath on waves only — never collapse to near-zero (that reads as a hard cut).
        withAnimation(.easeInOut(duration: Self.morphDuration * 0.45)) {
            transitionAmplitude = 0.88
        }
        withAnimation(.easeInOut(duration: Self.morphDuration)) {
            blendProgress = 1
        }
        withAnimation(.easeInOut(duration: Self.morphDuration).delay(Self.morphDuration * 0.35)) {
            transitionAmplitude = 1
        }

        try? await Task.sleep(for: .seconds(Self.morphDuration + 0.15))
        guard !Task.isCancelled else { return }
        fromGradient = toGradient
        fromWave = toWave
        blendProgress = 1
        transitionAmplitude = 1
        isTransitioning = false
    }
}
