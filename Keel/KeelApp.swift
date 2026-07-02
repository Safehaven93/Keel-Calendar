import SwiftUI
import SwiftData

@main
struct KeelApp: App {
    var body: some Scene {
        WindowGroup {
            AgendaView()
        }
        .modelContainer(for: Event.self)
    }
}
