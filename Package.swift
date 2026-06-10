// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Dumette",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Dumette", targets: ["DumetteApp"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DumetteApp",
            path: "Sources/DumetteApp"
        ),
    ]
)
