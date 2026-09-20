import SwiftUI
import SwiftData

struct SoundPickerSheet: View {
    @Environment(ContextEngine.self) private var runtime
    @Environment(\.lm) private var lm
    @Environment(ThemeEngine.self) private var theme
    @Environment(PurchaseManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    secondaryLayerSection
                    binauralSection
                    ForEach(grouped, id: \.context) { group in
                        soundGroup(group.context, sounds: group.sounds)
                    }
                }
                .padding(20)
            }
            .background(Color.black.opacity(0.2))
            .navigationTitle(lm.string("sounds_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.string("btn_done")) { dismiss() }
                }
            }
        }
        .presentationBackground(.regularMaterial)
    }

    private var grouped: [(context: AppContext, sounds: [Sound])] {
        [.commute, .focus, .reset, .sleep].map { ctx in
            (ctx, Sound.sounds(for: ctx))
        }
    }

    @ViewBuilder
    private var secondaryLayerSection: some View {
        if let sec = runtime.audio.secondarySound {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: sec.iconName)
                            .foregroundStyle(theme.gradient.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lm.string("mix_layer").uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.gradient.accentColor)
                            Text(sec.localizedTitle(using: lm))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Button {
                            HapticEngine.tap()
                            runtime.audio.stopSecondary()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.1.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                        Slider(
                            value: Binding(
                                get: { Double(runtime.audio.secondaryVolume) },
                                set: { runtime.audio.secondaryVolume = Float($0) }
                            ),
                            in: 0.0...1.0
                        )
                        .tint(theme.gradient.accentColor)
                        Text("\(Int(runtime.audio.secondaryVolume * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var binauralSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm.string("binaural_title").uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.45))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BinauralTone.allCases) { tone in
                        binauralChip(tone)
                    }
                }
            }
        }
    }

    private func binauralChip(_ tone: BinauralTone) -> some View {
        let selected = runtime.audio.binauralTone == tone
        return Button {
            runtime.audio.setBinauralTone(tone)
            HapticEngine.select()
        } label: {
            Text(lm.string(tone.localizationKey))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected ? .black : .white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selected ? theme.gradient.accentColor : Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }

    private func soundGroup(_ context: AppContext, sounds: [Sound]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm.string(context.localizationKey).uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.45))
            ForEach(sounds) { sound in
                soundRow(sound)
            }
        }
    }

    private func soundRow(_ sound: Sound) -> some View {
        let isProActive = store.isPro || StillwayTesting.unlockAllFeatures || (try? modelContext.fetch(FetchDescriptor<UserPreferences>()))?.first?.isPro == true
        let locked = !sound.isFree && !isProActive
        let selected = runtime.audio.primarySound?.id == sound.id
        let isSecondary = runtime.audio.secondarySound?.id == sound.id

        return HStack(spacing: 8) {
            Button {
                select(sound, locked: locked)
            } label: {
                soundRowLabel(sound, locked: locked, selected: selected)
            }
            .buttonStyle(.plain)

            if !locked && sound.id != runtime.audio.primarySound?.id {
                Button {
                    HapticEngine.tap()
                    if isSecondary {
                        runtime.audio.stopSecondary()
                    } else {
                        runtime.audio.playSecondary(sound: sound)
                    }
                } label: {
                    Image(systemName: isSecondary ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                        .font(.system(size: 15))
                        .foregroundStyle(isSecondary ? theme.gradient.accentColor : .white.opacity(0.45))
                        .frame(width: 36, height: 48)
                        .background(.ultraThinMaterial.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSecondary ? theme.gradient.accentColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSecondary ? lm.string("layer_remove") : lm.string("layer_add"))
            }
        }
    }

    private func select(_ sound: Sound, locked: Bool) {
        if locked {
            runtime.showSettings = true
            dismiss()
            return
        }
        let prefs = try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first
        let isProActive = store.isPro || StillwayTesting.unlockAllFeatures
        runtime.selectSound(sound, isPro: isProActive, preferences: prefs)
        HapticEngine.select()
        dismiss()
    }

    private func soundRowLabel(_ sound: Sound, locked: Bool, selected: Bool) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: sound.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.gradient.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(lm.string(sound.localizationKey))
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                        Text(sound.region.flag)
                    }
                    if locked {
                        Text(lm.string("mixer_locked"))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()
                trailingIcon(locked: locked, selected: selected)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(selected ? theme.gradient.accentColor.opacity(0.55) : .clear, lineWidth: 1)
        }
        .scaleEffect(selected ? 1.03 : 1)
    }

    @ViewBuilder
    private func trailingIcon(locked: Bool, selected: Bool) -> some View {
        if locked {
            Image(systemName: "lock.fill")
                .foregroundStyle(theme.gradient.accentColor.opacity(0.8))
        } else if selected {
            Image(systemName: "checkmark")
                .foregroundStyle(theme.gradient.accentColor)
        }
    }
}
