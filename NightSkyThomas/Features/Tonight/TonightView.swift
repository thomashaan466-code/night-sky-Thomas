import SwiftUI

struct TonightView: View {
    @State private var conditions = ObservationConditions.ideal
    @State private var isLoadingWeather = true

    private let weatherService = OpenMeteoWeatherService()

    private var events: [SkyEvent] {
        DemoSkyEvents.upcoming
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    conditionsCard
                    if let best = rankedEvents.first {
                        hero(event: best.event, score: best.score)
                    }
                    upcoming
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color.indigo.opacity(0.42), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .preferredColorScheme(.dark)
            .navigationTitle("Vanavond")
            .task { await loadWeather() }
        }
    }

    private var rankedEvents: [(event: SkyEvent, score: SkyScoreResult)] {
        events
            .map { ($0, SkyScore.calculate(event: $0, conditions: conditions)) }
            .sorted { $0.1.score > $1.1.score }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MIDDELBURG")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Wat is er de moeite waard?")
                .font(.largeTitle.bold())
        }
    }

    private var conditionsCard: some View {
        HStack {
            Label("\(Int(conditions.cloudCover))% bewolking", systemImage: "cloud.fill")
            Spacer()
            Text(conditions.isDark ? "Donker" : "Daglicht")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .redacted(reason: isLoadingWeather ? .placeholder : [])
    }

    private func hero(event: SkyEvent, score: SkyScoreResult) -> some View {
        NavigationLink {
            EventDetailView(event: event, conditions: conditions)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("TOP EVENT", systemImage: "flame.fill")
                        .font(.caption.bold())
                    Spacer()
                    Text("\(score.score)/100")
                        .font(.headline.monospacedDigit())
                }
                Text(event.title)
                    .font(.title.bold())
                Text(event.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                Text(event.summary)
                    .foregroundStyle(.secondary)
                HStack {
                    Label(score.label, systemImage: "sparkles")
                    Spacer()
                    Text("Zichtkans \(score.visibilityChance)%")
                }
                .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26))
        }
        .buttonStyle(.plain)
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daarna")
                .font(.title2.bold())
            ForEach(rankedEvents.dropFirst(), id: \.event.id) { item in
                NavigationLink {
                    EventDetailView(event: item.event, conditions: conditions)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: item.event.type.symbolName)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text(item.event.title).font(.headline)
                            Text(item.event.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(item.score.score)")
                            .font(.headline.monospacedDigit())
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @MainActor
    private func loadWeather() async {
        defer { isLoadingWeather = false }
        do {
            // Approximate city-level default; LocationService will replace this with live device location.
            conditions = try await weatherService.conditions(latitude: 51.50, longitude: 3.61)
        } catch {
            conditions = .ideal
        }
    }
}
