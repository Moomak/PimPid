import SwiftUI
import AppKit

/// About view with app information and quick start guide
struct AboutView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var thaiWordLoader = ThaiWordListLoader.shared

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    // App icon
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // App name and version
                    VStack(spacing: 4) {
                        Text("PimPid")
                            .font(.system(size: 24, weight: .bold))

                        Text(String(format: String(localized: "about.version", bundle: appState.localizedBundle), Bundle.main.appVersion, Bundle.main.buildNumber))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    // Description
                    Text(String(localized: "about.description1", bundle: appState.localizedBundle))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "about.description2", bundle: appState.localizedBundle))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    QuickStartStep(
                        number: 1,
                        title: String(localized: "about.quickstart.step1.title", bundle: appState.localizedBundle),
                        description: String(localized: "about.quickstart.step1.desc", bundle: appState.localizedBundle)
                    )

                    QuickStartStep(
                        number: 2,
                        title: String(localized: "about.quickstart.step2.title", bundle: appState.localizedBundle),
                        description: String(localized: "about.quickstart.step2.desc", bundle: appState.localizedBundle)
                    )

                    QuickStartStep(
                        number: 3,
                        title: String(localized: "about.quickstart.step3.title", bundle: appState.localizedBundle),
                        description: String(localized: "about.quickstart.step3.desc", bundle: appState.localizedBundle)
                    )
                }
            } header: {
                Text("Quick Start Guide")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Link(destination: URL(string: "https://github.com/Moomak/PimPid")!) {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("GitHub")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("github.com/Moomak/PimPid")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text("License")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("MIT License")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/Moomak/PimPid/releases")!) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text(String(localized: "about.check_update", bundle: appState.localizedBundle))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: copyDiagnosticInfo) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("Copy diagnostic info")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: exportStatsAsJSON) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text(String(localized: "about.export_json", bundle: appState.localizedBundle))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: exportStatsAsCSV) {
                        HStack {
                            Image(systemName: "tablecells")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text(String(localized: "about.export_csv", bundle: appState.localizedBundle))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(String(localized: "about.section.more", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if thaiWordLoader.loadProgress < 1.0 {
                        HStack(spacing: 8) {
                            ProgressView(value: thaiWordLoader.loadProgress)
                                .frame(maxWidth: 120)
                            Text(String(format: String(localized: "about.loading_thai", bundle: appState.localizedBundle), Int(thaiWordLoader.loadProgress * 100)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text(String(localized: "about.thai_credit", bundle: appState.localizedBundle))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("© 2025 PimPid · MIT License")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Made with ❤️ for Thai and English keyboard switchers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "about.nav_title", bundle: appState.localizedBundle))
    }

    private func copyDiagnosticInfo() {
        let version = Bundle.main.appVersion
        let build = Bundle.main.buildNumber
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let accessibility = AccessibilityHelper.isAccessibilityTrusted ? "yes" : "no"
        let text = """
        PimPid \(version) (\(build))
        macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)
        Accessibility: \(accessibility)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func exportStatsAsJSON() {
        let stats = ConversionStats.shared
        let payload: [String: Any] = [
            "totalConversions": stats.totalConversions,
            "todayConversions": stats.todayConversions,
            "recentConversions": stats.recentConversions.map { r in
                [
                    "original": r.original,
                    "converted": r.converted,
                    "direction": r.direction.rawValue,
                    "timestamp": ISO8601DateFormatter().string(from: r.timestamp)
                ] as [String: Any]
            }
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "pimpid-stats.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? data.write(to: url)
        }
    }

    private func exportStatsAsCSV() {
        let stats = ConversionStats.shared
        var lines: [String] = [
            "totalConversions,\(stats.totalConversions)",
            "todayConversions,\(stats.todayConversions)",
            "",
            "original,converted,direction,timestamp"
        ]
        let formatter = ISO8601DateFormatter()
        for r in stats.recentConversions {
            let escaped = { (s: String) in s.contains(",") || s.contains("\"") ? "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" : s }
            lines.append("\(escaped(r.original)),\(escaped(r.converted)),\(r.direction.rawValue),\(formatter.string(from: r.timestamp))")
        }
        let csv = lines.joined(separator: "\n")
        guard let data = csv.data(using: .utf8) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "pimpid-stats.csv"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? data.write(to: url)
        }
    }
}

/// Quick start step component
struct QuickStartStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// About link component
struct AboutLink: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 12, weight: .medium))

            Spacer()

            Text(value)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AboutView()
        .environmentObject(AppState())
}
