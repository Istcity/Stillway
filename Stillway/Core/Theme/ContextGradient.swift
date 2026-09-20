import SwiftUI

/// Ultra-smooth harmonic color palettes for ambient contexts and sounds.
/// Features tailored HSL gradients matching screenshots (Emerald transit, Warm golden amber,
/// Sunny gold, Ocean turquoise, Solfeggio violet, and Polar aurora).
struct ContextGradient: Equatable, Sendable {
    let bgColors: [Color]
    let waveColors: [Color]
    let accentColor: Color
    let glowColor: Color
    let cardTint: Color

    static func gradient(for soundID: String?, context: AppContext) -> ContextGradient {
        if let soundID {
            switch soundID {
            // Emerald Underground / Transit (Screenshot 1 & 4)
            case "tokyo_metro", "shinkansen", "paris_metro":
                return ContextGradient(
                    bgColors: [Color(hex: 0x01140E), Color(hex: 0x052B1D), Color(hex: 0x021A11)],
                    waveColors: [Color(hex: 0x00E676), Color(hex: 0x00B0FF), Color(hex: 0x1DE9B6)],
                    accentColor: Color(hex: 0x2EE59D),
                    glowColor: Color(hex: 0x2EE59D).opacity(0.48),
                    cardTint: Color(hex: 0x052B1D).opacity(0.65)
                )

            // Warm golden amber (Night Express, Sunset, Autumn Fireplace)
            case "deep_train", "autumn_432hz", "night_cafe":
                return ContextGradient(
                    bgColors: [Color(hex: 0x1A0E02), Color(hex: 0x331B05), Color(hex: 0x211203)],
                    waveColors: [Color(hex: 0xFFA726), Color(hex: 0xFFB300), Color(hex: 0xFF7043)],
                    accentColor: Color(hex: 0xFFA726),
                    glowColor: Color(hex: 0xFFA726).opacity(0.48),
                    cardTint: Color(hex: 0x331B05).opacity(0.65)
                )

            // Botanical moss & greenhouse rain
            case "greenhouse_rain", "tin_roof_rain":
                return ContextGradient(
                    bgColors: [Color(hex: 0x021714), Color(hex: 0x05302A), Color(hex: 0x03211D)],
                    waveColors: [Color(hex: 0x26A69A), Color(hex: 0x4DB6AC), Color(hex: 0x80CBC4)],
                    accentColor: Color(hex: 0x26A69A),
                    glowColor: Color(hex: 0x26A69A).opacity(0.45),
                    cardTint: Color(hex: 0x05302A).opacity(0.65)
                )

            // Sunny Gold / Gentle Summer Breeze & Study
            case "kyoto_bamboo", "study_cat", "minka_library":
                return ContextGradient(
                    bgColors: [Color(hex: 0x161301), Color(hex: 0x2E2704), Color(hex: 0x1D1902)],
                    waveColors: [Color(hex: 0xFFD54F), Color(hex: 0xFFCA28), Color(hex: 0xFFE082)],
                    accentColor: Color(hex: 0xFDD835),
                    glowColor: Color(hex: 0xFDD835).opacity(0.45),
                    cardTint: Color(hex: 0x2E2704).opacity(0.65)
                )

            // Deep ocean turquoise & Bosphorus
            case "rain_window", "istanbul_ferry", "mossy_waterfall":
                return ContextGradient(
                    bgColors: [Color(hex: 0x011A21), Color(hex: 0x03303D), Color(hex: 0x021F29)],
                    waveColors: [Color(hex: 0x00E5FF), Color(hex: 0x00B0FF), Color(hex: 0x26C6DA)],
                    accentColor: Color(hex: 0x00E5FF),
                    glowColor: Color(hex: 0x00E5FF).opacity(0.45),
                    cardTint: Color(hex: 0x03303D).opacity(0.65)
                )

            // Meditative Solfeggio & Temple bells (Ethereal purple & sacred violet)
            case "temple_bell", "gong_bath", "sacred_om", "healing_528hz":
                return ContextGradient(
                    bgColors: [Color(hex: 0x140821), Color(hex: 0x2B1245), Color(hex: 0x1C0C30)],
                    waveColors: [Color(hex: 0xBA68C8), Color(hex: 0xAB47BC), Color(hex: 0xE1BEE7)],
                    accentColor: Color(hex: 0xCE93D8),
                    glowColor: Color(hex: 0xCE93D8).opacity(0.48),
                    cardTint: Color(hex: 0x2B1245).opacity(0.65)
                )

            // Cozy Hygge Night (Warm fire embers)
            case "hygge_night":
                return ContextGradient(
                    bgColors: [Color(hex: 0x1E0A05), Color(hex: 0x3D160B), Color(hex: 0x270F07)],
                    waveColors: [Color(hex: 0xFF8A65), Color(hex: 0xFF7043), Color(hex: 0xFFAB91)],
                    accentColor: Color(hex: 0xFF7043),
                    glowColor: Color(hex: 0xFF7043).opacity(0.48),
                    cardTint: Color(hex: 0x3D160B).opacity(0.65)
                )

            // Polar Aurora & Cosmic Deep Night (Screenshot 4)
            case "aurora_ocean", "silent_snow", "moonlit_dunes", "night_forest", "tokyo_rain":
                return ContextGradient(
                    bgColors: [Color(hex: 0x040817), Color(hex: 0x0B1536), Color(hex: 0x070E24)],
                    waveColors: [Color(hex: 0x7C4DFF), Color(hex: 0x536DFE), Color(hex: 0x00E5FF)],
                    accentColor: Color(hex: 0x7C4DFF),
                    glowColor: Color(hex: 0x7C4DFF).opacity(0.45),
                    cardTint: Color(hex: 0x0B1536).opacity(0.65)
                )

            default:
                break
            }
        }
        return gradient(for: context)
    }

    static func gradient(for context: AppContext) -> ContextGradient {
        switch context {
        case .commute:
            // Emerald Underground / Transit (Screenshot 1 & 4)
            return ContextGradient(
                bgColors: [Color(hex: 0x01140E), Color(hex: 0x052B1D), Color(hex: 0x021A11)],
                waveColors: [Color(hex: 0x00E676), Color(hex: 0x00B0FF), Color(hex: 0x1DE9B6)],
                accentColor: Color(hex: 0x2EE59D),
                glowColor: Color(hex: 0x2EE59D).opacity(0.45),
                cardTint: Color(hex: 0x052B1D).opacity(0.65)
            )
        case .focus:
            // Warm Amber Focus (Screenshot 2 & 3)
            return ContextGradient(
                bgColors: [Color(hex: 0x1A0E02), Color(hex: 0x331B05), Color(hex: 0x211203)],
                waveColors: [Color(hex: 0xFFA726), Color(hex: 0xFFB300), Color(hex: 0xFF7043)],
                accentColor: Color(hex: 0xFFA726),
                glowColor: Color(hex: 0xFFA726).opacity(0.48),
                cardTint: Color(hex: 0x331B05).opacity(0.65)
            )
        case .sleep:
            // Deep Starlight & Cosmic Purple
            return ContextGradient(
                bgColors: [Color(hex: 0x040817), Color(hex: 0x0B1536), Color(hex: 0x070E24)],
                waveColors: [Color(hex: 0x7C4DFF), Color(hex: 0x536DFE), Color(hex: 0x00E5FF)],
                accentColor: Color(hex: 0x7C4DFF),
                glowColor: Color(hex: 0x7C4DFF).opacity(0.45),
                cardTint: Color(hex: 0x0B1536).opacity(0.65)
            )
        case .reset:
            // Ocean Turquoise & Water Breeze
            return ContextGradient(
                bgColors: [Color(hex: 0x011A21), Color(hex: 0x03303D), Color(hex: 0x021F29)],
                waveColors: [Color(hex: 0x00E5FF), Color(hex: 0x00B0FF), Color(hex: 0x26C6DA)],
                accentColor: Color(hex: 0x00E5FF),
                glowColor: Color(hex: 0x00E5FF).opacity(0.45),
                cardTint: Color(hex: 0x03303D).opacity(0.65)
            )
        case .walking:
            // Güneş Saati: Warm Solar Rays & Golden Morning Plasma
            return ContextGradient(
                bgColors: [Color(hex: 0x221303), Color(hex: 0x3B2005), Color(hex: 0x1A0D02)],
                waveColors: [Color(hex: 0xFFD54F), Color(hex: 0xFF9800), Color(hex: 0xFFE082)],
                accentColor: Color(hex: 0xFFB300),
                glowColor: Color(hex: 0xFFD54F).opacity(0.50),
                cardTint: Color(hex: 0x3B2005).opacity(0.65)
            )
        case .deepWork:
            // Volcanic Crimson & Deep Embers
            return ContextGradient(
                bgColors: [Color(hex: 0x1A0505), Color(hex: 0x360808), Color(hex: 0x240505)],
                waveColors: [Color(hex: 0xFF5252), Color(hex: 0xFF1744), Color(hex: 0xFF7043)],
                accentColor: Color(hex: 0xFF5252),
                glowColor: Color(hex: 0xFF5252).opacity(0.45),
                cardTint: Color(hex: 0x360808).opacity(0.65)
            )
        case .unknown:
            return ContextGradient(
                bgColors: [Color(hex: 0x050505), Color(hex: 0x0E0E12), Color(hex: 0x08080A)],
                waveColors: [Color(hex: 0x64B5F6), Color(hex: 0x81D4FA), Color(hex: 0x4DD0E1)],
                accentColor: Color(hex: 0x64B5F6),
                glowColor: Color(hex: 0x64B5F6).opacity(0.35),
                cardTint: Color(hex: 0x121217).opacity(0.65)
            )
        }
    }

    static func `for`(_ context: AppContext) -> ContextGradient {
        gradient(for: context)
    }

    static func blended(from: ContextGradient, to: ContextGradient, t: Double) -> ContextGradient {
        let t = min(1, max(0, t))
        if t <= 0.001 { return from }
        if t >= 0.999 { return to }
        return ContextGradient(
            bgColors: zipPad(from.bgColors, to.bgColors).map { $0.mix(with: $1, t: t) },
            waveColors: zipPad(from.waveColors, to.waveColors).map { $0.mix(with: $1, t: t) },
            accentColor: from.accentColor.mix(with: to.accentColor, t: t),
            glowColor: from.glowColor.mix(with: to.glowColor, t: t),
            cardTint: from.cardTint.mix(with: to.cardTint, t: t)
        )
    }

    private static func zipPad(_ a: [Color], _ b: [Color]) -> [(Color, Color)] {
        let count = max(a.count, b.count)
        return (0..<count).map { i in
            (a[min(i, a.count - 1)], b[min(i, b.count - 1)])
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    func mix(with other: Color, t: Double) -> Color {
        let t = min(1, max(0, t))
        #if canImport(UIKit)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        guard UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        else {
            return t < 0.5 ? self : other
        }
        return Color(
            .sRGB,
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t),
            opacity: Double(a1 + (a2 - a1) * t)
        )
        #else
        return t < 0.5 ? self : other
        #endif
    }
}
