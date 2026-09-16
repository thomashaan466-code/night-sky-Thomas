import SwiftUI

@main
struct NightSkyThomasApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

private struct RootView: View {
    var body: some View {
        TabView {
            TonightView()
                .tabItem { Label("Vanavond", systemImage: "sparkles") }

            SkyCalendarView()
                .tabItem { Label("Kalender", systemImage: "calendar") }

            ARFinderPlaceholderView()
                .tabItem { Label("Live Sky", systemImage: "camera.viewfinder") }
        }
    }
}

private struct SkyCalendarView: View {
    var body: some View {
        NavigationStack {
            List(DemoSkyEvents.upcoming) { event in
                HStack {
                    Image(systemName: event.type.symbolName)
                    VStack(alignment: .leading) {
                        Text(event.title)
                        Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Sky Calendar")
        }
    }
}

private struct ARFinderPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "AR Finder",
            systemImage: "camera.viewfinder",
            description: Text("Hier komt de live cameraweergave die met kompas en bewegingssensoren laat zien waar je moet kijken.")
        )
    }
}
