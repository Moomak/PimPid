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

        // 2. Fallback to SwiftPM auto-generated accessor (works in dev builds)
        return Bundle.module
    }()
}
