import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: PhotoViewerModel

    var body: some View {
        Group {
            if model.isSlideshowActive {
                SlideshowView()
            } else {
                SelectionView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.isSlideshowActive)
    }
}

struct SelectionView: View {
    @EnvironmentObject private var model: PhotoViewerModel

    var body: some View {
        VStack(spacing: 14) {
            header
            Divider()
            selectionPanel
            Divider()
            Text(model.statusMessage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dumette Photo Viewer")
                .font(.largeTitle)
                .bold()
            Text("Choose folders, photos, or drop images to build a randomized looped slideshow.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectionPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: openSelectionPanel) {
                    Label("Add Photos / Folders", systemImage: "plus.circle")
                }
                Button(action: model.prepareSlideshow) {
                    Label("Start Slideshow", systemImage: "play.fill")
                }
                .disabled(model.sources.isEmpty)
                Spacer()
                Toggle("Include Subfolders", isOn: $model.includeSubfolders)
                    .toggleStyle(.switch)
                    .frame(maxWidth: 220)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Text("Selected sources")
                    .font(.headline)
                    .padding(.horizontal)
                if model.sources.isEmpty {
                    Text("No photos selected yet. Add folders or image files to display.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    List {
                        ForEach(model.sources) { source in
                            HStack(spacing: 10) {
                                Image(systemName: source.isFolder ? "folder.fill" : "photo")
                                    .foregroundColor(source.isFolder ? .accentColor : .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.url.lastPathComponent)
                                        .font(.subheadline)
                                    Text(source.url.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: model.removeSource)
                    }
                    .frame(minHeight: 280)
                }
            }
        }
    }

    private func openSelectionPanel() {
        let panel = NSOpenPanel()
        panel.title = "Select images or folders"
        panel.allowedContentTypes = [.image, .folder]
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.begin { response in
            guard response == .OK else { return }
            model.addEntries(urls: panel.urls)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PhotoViewerModel())
    }
}
