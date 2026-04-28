import SwiftUI

struct CatOverlayView: View {
    let store: SessionStore
    @State private var animateCat = false
    private var shouldAnimateCat: Bool {
        store.catDisplayStyle == "animated"
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.clear
                    .ignoresSafeArea()

                Image(store.selectedCatAssetName, bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: proxy.size.width * 0.995,
                        maxHeight: proxy.size.height * 0.97
                    )
                    .scaleEffect(shouldAnimateCat && animateCat ? 1.04 : 1.0)
                    .animation(
                        shouldAnimateCat ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : nil,
                        value: animateCat
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 4) {
                    if store.isBreakOverlayPreviewMode {
                        Text("表示確認モード")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text(store.remainingTimeText)
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
                .padding(.leading, 36)
                .padding(.top, 28)

                HStack {
                    Spacer()
                    Button(store.isBreakOverlayPreviewMode ? "閉じる" : "今は休憩しない") {
                        if store.isBreakOverlayPreviewMode {
                            store.markBreakOverlayClosed()
                        } else {
                            store.skipBreak()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(OverlayWindowConfigurator())
        .onAppear {
            animateCat = shouldAnimateCat
        }
        .onChange(of: store.catDisplayStyle) { _, newStyle in
            if newStyle == "animated" {
                animateCat = false
                DispatchQueue.main.async {
                    animateCat = true
                }
            } else {
                animateCat = false
            }
        }
    }
}

private struct OverlayWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.level = .statusBar
            window.styleMask = [.borderless, .fullSizeContentView]
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .stationary]
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = false
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            let targetScreen = window.screen ?? NSScreen.main
            if let frame = targetScreen?.frame {
                window.setFrame(frame, display: true)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
