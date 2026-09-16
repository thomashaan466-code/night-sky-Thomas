import SwiftUI

struct EventDetailView: View {
    let event: SkyEvent
    let conditions: ObservationConditions

    private var score: SkyScoreResult {
        SkyScore.calculate(event: event, conditions: conditions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: event.type.symbolName)
                    .font(.system(size: 52))
                Text(event.title)
                    .font(.largeTitle.bold())
                Text(event.startDate.formatted(date: .complete, time: .shortened))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    metric("Sky Score", "\(score.score)/100")
                    metric("Zichtkans", "\(score.visibilityChance)%")
                }

                Text(event.summary)
                    .font(.body)

                if let azimuth = event.azimuthDegrees {
                    detail("Kijkrichting", "\(Int(azimuth))° · \(compassDirection(azimuth))")
                }
                if let elevation = event.elevationDegrees {
                    detail("Hoogte", "\(Int(elevation))°")
                }
                if let magnitude = event.magnitude {
                    detail("Helderheid", String(format: "%.1f mag", magnitude))
                }
                detail("Bron", event.sourceName)

                Button {
                    // ARFinderView will become the live camera destination in V3.
                } label: {
                    Label("Open AR Finder", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(true)
            }
            .padding()
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func detail(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }

    private func compassDirection(_ degrees: Double) -> String {
        let directions = ["N", "NO", "O", "ZO", "Z", "ZW", "W", "NW"]
        let index = Int((degrees + 22.5) / 45.0) % 8
        return directions[index]
    }
}
