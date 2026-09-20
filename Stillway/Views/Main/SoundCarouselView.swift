import SwiftUI

/// Horizontal interactive sound carousel matching the bottom of user screenshots.
/// Displays circular sound cards, enlarges the active sound with a glowing neon ring,
/// shows a mini play/pause badge on the active sound, and allows smooth selection.
struct SoundCarouselView: View {
    let sounds: [Sound]
    let selectedSound: Sound?
    let isPlaying: Bool
    let onSelectSound: (Sound) -> Void
    let onTogglePlay: () -> Void

    @Environment(ThemeEngine.self) private var theme
    @Environment(\.lm) private var lm
    private var accent: Color { theme.gradient.accentColor }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Left spacer padding
                    Color.clear.frame(width: 16)

                    ForEach(sounds) { sound in
                        let isSelected = selectedSound?.id == sound.id
                        soundItem(sound: sound, isSelected: isSelected)
                            .id(sound.id)
                    }

                    // Right spacer padding
                    Color.clear.frame(width: 16)
                }
                .padding(.vertical, 12)
            }
            .onAppear {
                if let selectedSound {
                    proxy.scrollTo(selectedSound.id, anchor: .center)
                }
            }
            .onChange(of: selectedSound?.id) { _, newID in
                if let newID {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
        }
    }

    private func soundItem(sound: Sound, isSelected: Bool) -> some View {
        Button {
            HapticEngine.select()
            if isSelected {
                onTogglePlay()
            } else {
                onSelectSound(sound)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Outer aura for selected item
                    if isSelected {
                        Circle()
                            .fill(accent.opacity(0.18))
                            .frame(width: 72, height: 72)
                            .blur(radius: 8)
                    }

                    // Main circle background
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.22 : 0.08))
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? accent : Color.white.opacity(0.14),
                                    lineWidth: isSelected ? 2.5 : 0.8
                                )
                        )
                        .frame(width: isSelected ? 66 : 52, height: isSelected ? 66 : 52)
                        .shadow(color: isSelected ? accent.opacity(0.65) : .clear, radius: 12)

                    // Sound icon
                    Image(systemName: sound.iconName)
                        .font(.system(size: isSelected ? 24 : 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                        .frame(width: isSelected ? 66 : 52, height: isSelected ? 66 : 52)

                    // Mini play/pause badge on the selected sound
                    if isSelected {
                        Circle()
                            .fill(Color.black.opacity(0.88))
                            .overlay(
                                Circle().stroke(accent.opacity(0.75), lineWidth: 1.2)
                            )
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 3, y: -3)
                    }
                }

                // Sound label text under the circle (strictly NO underline)
                Text(sound.localizedTitle(using: lm))
                    .font(.system(size: isSelected ? 12 : 11, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.58))
                    .lineLimit(1)
                    .frame(width: isSelected ? 92 : 78)
            }
            .scaleEffect(isSelected ? 1.08 : 0.94)
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
