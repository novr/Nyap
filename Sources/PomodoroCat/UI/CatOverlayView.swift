import SwiftUI

struct CatOverlayView: View {
    let store: SessionStore
    @State private var animateCat = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("Cat", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                .scaleEffect(store.catDisplayStyle == "animated" && animateCat ? 1.04 : 0.96)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateCat)

                Text("休憩タイム")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text(store.remainingTimeText)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("猫が寝そべっています。少し離れて休憩しましょう。")
                    .foregroundStyle(.white.opacity(0.9))

                Button("今は休憩しない") {
                    store.skipBreak()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
        }
        .background(OverlayWindowConfigurator())
        .onAppear {
            animateCat = true
        }
    }
}

private struct OverlayWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.level = .floating
            window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = false
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
