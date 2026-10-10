import SwiftUI

@main
struct YouTubeCleanerDesktopApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 960, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 780)

        Settings {
            SettingsView()
                .environmentObject(model)
                .frame(width: 560)
        }
    }
}
