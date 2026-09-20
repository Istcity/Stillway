import WidgetKit
import SwiftUI

struct HomeScreenWidget: Widget {
    let kind = "StillwayHomeScreen"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StillwayTimelineProvider()) { entry in
            HomeScreenWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.01, green: 0.03, blue: 0.09), Color(red: 0.05, green: 0.11, blue: 0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .widgetURL(URL(string: "stillway://toggle"))
        }
        .configurationDisplayName("Stillway Session")
        .description("See the active sound and remaining time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeScreenWidgetView: View {
    var entry: StillwayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.contextName.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Color(red: 0.25, green: 0.41, blue: 0.88))
            Text(entry.soundName)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white)
            Spacer()
            HStack {
                Image(systemName: entry.isPlaying ? "waveform" : "moon.zzz")
                Spacer()
                Text(entry.remainingLabel)
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .tracking(-1)
            }
            .foregroundStyle(.white)
        }
        .padding(4)
    }
}

struct StillwayEntry: TimelineEntry {
    let date: Date
    var contextName: String
    var soundName: String
    var remainingLabel: String
    var isPlaying: Bool
}

struct StillwayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StillwayEntry {
        StillwayEntry(date: .now, contextName: "Commute", soundName: "Tokyo Rain", remainingLabel: "24:17", isPlaying: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (StillwayEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StillwayEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.sinannergiz.stillway")
        let entry = StillwayEntry(
            date: .now,
            contextName: defaults?.string(forKey: "contextName") ?? "Stillway",
            soundName: defaults?.string(forKey: "soundName") ?? "Tokyo Rain",
            remainingLabel: defaults?.string(forKey: "remaining") ?? "--:--",
            isPlaying: defaults?.bool(forKey: "isPlaying") ?? false
        )
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60))))
    }
}
