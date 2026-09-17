// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NightSkyThomasCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "NightSkyThomasCore",
            targets: ["NightSkyThomasCore"]
        )
    ],
    targets: [
        .target(
            name: "NightSkyThomasCore",
            path: "NightSkyThomas",
            exclude: [
                "App",
                "Features"
            ],
            sources: [
                "Models",
                "Scoring",
                "Services"
            ]
        ),
        .testTarget(
            name: "NightSkyThomasCoreTests",
            dependencies: ["NightSkyThomasCore"],
            path: "NightSkyThomasTests"
        )
    ]
)
