import SwiftUI

@main
struct NyapApp: App {
    @State private var store = SessionStore()

    var body: some Scene {
        WindowGroup("Nyap") {
            RootContentView(store: store)
                .frame(minWidth: 560, minHeight: 520)
        }

        Window("休憩", id: SessionStore.breakOverlayWindowID) {
            CatOverlayView(store: store)
                .frame(minWidth: 480, minHeight: 360)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            Text(store.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct RootContentView: View {
    let store: SessionStore
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        MainView(store: store)
            .onAppear {
                store.bindNotificationPermission()
            }
            .onChange(of: store.isBreakOverlayPresented) { _, isPresented in
                if isPresented {
                    openWindow(id: SessionStore.breakOverlayWindowID)
                } else {
                    dismissWindow(id: SessionStore.breakOverlayWindowID)
                }
            }
            .onChange(of: store.phase) { _, phase in
                if phase != .breakTime {
                    dismissWindow(id: SessionStore.breakOverlayWindowID)
                }
            }
    }
}

private struct MenuBarView: View {
    let store: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.phaseTitle)
                .font(.headline)
            Text(store.remainingTimeText)
                .font(.system(.title3, design: .monospaced))
            Divider()
            Button("作業を開始") {
                store.startWorkSession()
            }
            .disabled(store.phase == .work)
            Button("休憩をスキップ") {
                store.skipBreak()
            }
            .disabled(store.phase != .breakTime)
            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}
