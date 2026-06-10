import AppKit
import SwiftUI

struct SlideshowView: View {
    @EnvironmentObject private var model: PhotoViewerModel

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let image = model.currentImage {
                GeometryReader { geometry in
                    HighQualityImageView(image: image)
                        .scaleEffect(model.zoomScale)
                        .offset(x: model.panOffset.width, y: model.panOffset.height)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .animation(.easeOut(duration: 0.1), value: model.zoomScale)
                        .animation(.easeOut(duration: 0.1), value: model.panOffset)
                }
            } else if model.isLoading {
                ProgressView("Loading…")
                    .progressViewStyle(.circular)
                    .foregroundColor(.white)
            } else {
                Text("No image loaded")
                    .foregroundColor(.white)
                    .font(.title2)
            }

            VStack {
                HStack {
                    Button(action: model.returnToSelector) {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)

                    Spacer()
                    InfoPanelView()
                }
                .padding()
                Spacer()
            }

            KeyEventHandlingView { event in
                guard let specialKey = event.specialKey else {
                    handleCharacter(event.charactersIgnoringModifiers)
                    return true
                }
                switch specialKey {
                case .leftArrow:
                    handleArrow(dx: 40, dy: 0, backwards: true)
                case .rightArrow:
                    handleArrow(dx: 40, dy: 0, backwards: false)
                case .upArrow:
                    handleArrow(dx: 0, dy: 40, backwards: false)
                case .downArrow:
                    handleArrow(dx: 0, dy: 40, backwards: true)
                default:
                    break
                }
                return true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            model.loadCurrentImage()
        }
    }

    private func handleArrow(dx: CGFloat, dy: CGFloat, backwards: Bool) {
        if model.isZoomedIn {
            model.pan(by: CGSize(width: backwards ? dx : -dx, height: dy * (backwards ? -1 : 1)))
        } else {
            if backwards {
                model.previousPicture()
            } else {
                model.nextPicture()
            }
        }
    }

    private func handleCharacter(_ characters: String?) {
        guard let key = characters?.lowercased() else { return }
        switch key {
        case "+", "=":
            model.adjustZoom(by: 0.01)
        case "-":
            model.adjustZoom(by: -0.01)
        default:
            break
        }
    }
}

struct InfoPanelView: View {
    @EnvironmentObject private var model: PhotoViewerModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(model.currentImageName)
                .font(.headline)
                .foregroundColor(.white)
            Text(model.currentIndexText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Zoom: \(Int(model.zoomScale * 100))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Use ←/→ to move, +/‑ to zoom, Esc to return.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.black.opacity(0.45))
        .cornerRadius(10)
    }
}

struct HighQualityImageView: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.imageAlignment = .center
        view.canDrawSubviewsIntoLayer = true
        view.wantsLayer = true
        view.layer?.magnificationFilter = .trilinear
        view.image = image
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = image
    }
}

struct KeyEventHandlingView: NSViewRepresentable {
    var handler: (NSEvent) -> Bool

    func makeNSView(context: Context) -> KeyboardCaptureView {
        let view = KeyboardCaptureView()
        view.handler = handler
        return view
    }

    func updateNSView(_ nsView: KeyboardCaptureView, context: Context) {
        nsView.handler = handler
    }

    class KeyboardCaptureView: NSView {
        var handler: ((NSEvent) -> Bool)?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }

        override func keyDown(with event: NSEvent) {
            if handler?(event) != false {
                return
            }
            super.keyDown(with: event)
        }
    }
}
