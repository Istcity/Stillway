import SwiftUI
import SwiftData

struct PlacesSheet: View {
    @Environment(\.lm) private var lm
    @Environment(ContextEngine.self) private var runtime
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserPlace.visitCount, order: .reverse) private var places: [UserPlace]

    var body: some View {
        NavigationStack {
            Group {
                if places.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 42, weight: .light))
                            .symbolEffect(.pulse)
                        Text(lm.string("places_empty"))
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(places) { place in
                                GlassCard {
                                    HStack(spacing: 14) {
                                        Image(systemName: place.label.sfSymbol)
                                            .font(.system(size: 20))
                                            .frame(width: 36)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(place.customName ?? lm.string(place.label.localizationKey))
                                                .font(.system(size: 17))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            if place.homeConfidence > 0.2 {
                                                Text(String(format: lm.string("places_confidence"), Int(place.homeConfidence * 100)))
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.white.opacity(0.4))
                                                    .lineLimit(1)
                                            }
                                            Text("\(place.visitCount) \(lm.string("places_visits"))")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.45))
                                                .lineLimit(1)
                                            Text(lm.string("places_last_seen") + " " + place.lastSeen.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 11))
                                                .foregroundStyle(.white.opacity(0.35))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.75)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Spacer()
                                        Toggle("", isOn: Binding(
                                            get: { place.autoStartEnabled },
                                            set: { runtime.visitTracker?.setAutoStart(for: place, enabled: $0) }
                                        ))
                                        .labelsHidden()
                                        .tint(.green)
                                    }
                                }
                                .onTapGesture {
                                    runtime.visitTracker?.pendingLabelPlace = place
                                    runtime.showPlaceLabel = true
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(lm.string("places_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.string("btn_done")) { dismiss() }
                }
            }
            .sheet(isPresented: Bindable(runtime).showPlaceLabel) {
                PlaceLabelSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .presentationBackground(.regularMaterial)
    }
}
