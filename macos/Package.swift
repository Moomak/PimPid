// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PimPid",
    defaultLocalization: "th",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PimPid", targets: ["PimPid"]),
    ],
    targets: [
        .executableTarget(
            name: "PimPid",
            path: "PimPid",
            exclude: ["PimPid.entitlements", "README.md", "Icon", "Info.plist"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PimPidTests",
            dependencies: ["PimPid"],
            path: "Tests/PimPidTests"
        ),
    ]
)
