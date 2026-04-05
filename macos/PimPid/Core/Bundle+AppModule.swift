import Foundation

extension Bundle {
    /// Custom resource bundle accessor that checks Contents/Resources/ first.
    /// SwiftPM auto-generated `Bundle.module` only checks the .app root,
    /// which fails codesign ("unsealed contents in bundle root").
    static let appModule: Bundle = {
        let bundleName = "PimPid_PimPid"

        // 1. Standard .app location: Contents/Resources/
        if let resourceURL = Bundle.main.resourceURL,
           let bundle = Bundle(url: resourceURL.appendingPathComponent("\(bundleName).bundle")) {
            return bundle
        }

        // 2. Alongside the executable (SwiftPM dev builds)
        let executableURL = Bundle.main.bundleURL.appendingPathComponent("\(bundleName).bundle")
        if let bundle = Bundle(url: executableURL) {
            return bundle
        }

        fatalError("could not load resource bundle: \(bundleName)")
    }()
}
