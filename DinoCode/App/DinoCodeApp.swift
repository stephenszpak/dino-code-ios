import SwiftUI

@main
struct DinoCodeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Landscape-only iPad app for classroom projection.
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}
