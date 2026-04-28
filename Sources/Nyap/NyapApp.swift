import SwiftUI

@main
struct NyapApp: App {
    @State private var store = SessionStore()

    var body: some Scene {
        WindowGroup(L10n.tr("app.name")) {
            RootContentView(store: store)
                .frame(minWidth: 980, minHeight: 760)
        }

        Window(L10n.tr("app.breakWindowTitle"), id: SessionStore.breakOverlayWindowID) {
            CatOverlayView(store: store)
                .frame(minWidth: 480, minHeight: 360)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            MenuBarLabelView(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct RootContentView: View {
    let store: SessionStore

    var body: some View {
        MainView(store: store)
            .onAppear {
                store.bindNotificationPermission()
            }
    }
}

private struct MenuBarLabelView: View {
    let store: SessionStore
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Text(store.menuBarTitle)
            .onAppear {
                store.bindNotificationPermission()
            }
            .task(id: store.isBreakOverlayPresented) {
                if store.isBreakOverlayPresented {
                    openWindow(id: SessionStore.breakOverlayWindowID)
                } else {
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
            Button(L10n.tr("menu.startWork")) {
                store.startWorkSession()
            }
            .disabled(store.phase == .work)
            Button(L10n.tr("menu.skipBreak")) {
                store.skipBreak()
            }
            .disabled(store.phase != .breakTime)
            Button(L10n.tr("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}
