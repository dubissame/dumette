import SwiftUI

@main
struct DumetteApp: App {
    @StateObject private var model = PhotoViewerModel()

    var body: some Scene {
        WindowGroup("Dumette") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1000, minHeight: 700)
        }
    }
}
