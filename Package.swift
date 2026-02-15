// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PimPid",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PimPid", targets: ["PimPid"]),
    ],
    targets: [
        .executableTarget(
            name: "PimPid",
            path: "PimPid",
            exclude: ["PimPid.entitlements", "README.md", "Icon"]
        ),
    ]
)
