import AppKit
import Foundation
import SwiftUI

final class PhotoViewerModel: ObservableObject {
    static let supportedImageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "heic", "heif", "tif", "tiff", "bmp", "webp"
    ]

    struct PhotoSource: Identifiable, Hashable {
        let id = UUID()
        let url: URL
        let isFolder: Bool
    }

    @Published var sources: [PhotoSource] = []
    @Published var includeSubfolders = true
    @Published private(set) var photoURLs: [URL] = []
    @Published var currentIndex = 0
    @Published var currentImage: NSImage?
    @Published var isSlideshowActive = false
    @Published var isLoading = false
    @Published var zoomScale: CGFloat = 1.0
    @Published var panOffset = CGSize.zero
    @Published var statusMessage: String = "Select your pictures and folders to start."

    private let cache = NSCache<NSURL, NSImage>()
    private let imageQueue = DispatchQueue(label: "Dumette.imageLoader", qos: .userInitiated)

    var currentImageName: String {
        guard currentIndex < photoURLs.count else { return "No image" }
        return photoURLs[currentIndex].lastPathComponent
    }

    var currentIndexText: String {
        guard !photoURLs.isEmpty else { return "0 / 0" }
        return "\(currentIndex + 1) / \(photoURLs.count)"
    }

    var isZoomedIn: Bool {
        return zoomScale > 1.001
    }

    var canStartSlideshow: Bool {
        !photoURLs.isEmpty
    }

    func addEntries(urls: [URL]) {
        let additions = urls.map { url in
            PhotoSource(url: url, isFolder: url.hasDirectoryPath)
        }
        sources.append(contentsOf: additions)
        statusMessage = "Added \(additions.count) selector item(s)."
    }

    func removeSource(at offsets: IndexSet) {
        sources.remove(atOffsets: offsets)
    }

    func buildPhotoList() {
        var collected: [URL] = []
        for source in sources {
            if source.isFolder {
                collected.append(contentsOf: gatherImages(in: source.url))
            } else if Self.isSupportedImage(url: source.url) {
                collected.append(source.url)
            }
        }
        photoURLs = collected
    }

    func prepareSlideshow() {
        buildPhotoList()
        photoURLs.shuffle()
        currentIndex = 0
        zoomScale = 1.0
        panOffset = .zero
        currentImage = nil
        isSlideshowActive = true
        loadCurrentImage()
        statusMessage = "Starting slideshow with \(photoURLs.count) image(s)."
    }

    func returnToSelector() {
        isSlideshowActive = false
        currentImage = nil
        zoomScale = 1.0
        panOffset = .zero
    }

    func nextPicture() {
        guard !photoURLs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % photoURLs.count
        resetViewStateForNewPhoto()
    }

    func previousPicture() {
        guard !photoURLs.isEmpty else { return }
        currentIndex = (currentIndex - 1 + photoURLs.count) % photoURLs.count
        resetViewStateForNewPhoto()
    }

    func adjustZoom(by delta: CGFloat) {
        let next = (zoomScale + delta).clamped(to: 0.2...5.0)
        zoomScale = next
        if zoomScale <= 1.0 {
            panOffset = .zero
        }
    }

    func pan(by translation: CGSize) {
        guard isZoomedIn else { return }
        panOffset.width += translation.width
        panOffset.height += translation.height
    }

    private func resetViewStateForNewPhoto() {
        zoomScale = 1.0
        panOffset = .zero
        loadCurrentImage()
    }

    private func loadCurrentImage() {
        guard currentIndex < photoURLs.count else {
            currentImage = nil
            return
        }

        let url = photoURLs[currentIndex]
        if let cached = cache.object(forKey: url as NSURL) {
            currentImage = cached
            preloadAdjacentImages()
            return
        }

        isLoading = true
        imageQueue.async { [weak self] in
            guard let self = self else { return }
            let image = NSImage(contentsOf: url)
            DispatchQueue.main.async {
                if let image {
                    self.cache.setObject(image, forKey: url as NSURL)
                }
                self.currentImage = image
                self.isLoading = false
                self.preloadAdjacentImages()
            }
        }
    }

    private func preloadAdjacentImages() {
        let targets = adjacentIndexes().compactMap { index in
            guard photoURLs.indices.contains(index) else { return nil }
            return photoURLs[index]
        }
        for url in targets {
            if cache.object(forKey: url as NSURL) != nil { continue }
            imageQueue.async { [weak self] in
                guard let self = self else { return }
                if let image = NSImage(contentsOf: url) {
                    self.cache.setObject(image, forKey: url as NSURL)
                }
            }
        }
    }

    private func adjacentIndexes() -> [Int] {
        guard !photoURLs.isEmpty else { return [] }
        let previous = (currentIndex - 1 + photoURLs.count) % photoURLs.count
        let next = (currentIndex + 1) % photoURLs.count
        return [previous, next]
    }

    private func gatherImages(in folder: URL) -> [URL] {
        let fileManager = FileManager.default
        if includeSubfolders {
            guard let enumerator = fileManager.enumerator(
                at: folder,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                return []
            }

            return enumerator.compactMap { item in
                guard let url = item as? URL else { return nil }
                return Self.isSupportedImage(url: url) ? url : nil
            }
        }

        guard let items = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return []
        }
        return items.filter(Self.isSupportedImage(url:))
    }

    private static func isSupportedImage(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedImageExtensions.contains(ext)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
