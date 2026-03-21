import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openSettings) private var openSettings

    private var fontScale: CGFloat {
        switch appState.appearanceFontSize {
        case "small": return 0.9
        case "large": return 1.15
        case "xl": return 1.35
        default: return 1.0
        }
    }

    private var colorScheme: ColorScheme? {
        switch appState.appearanceTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        menuContent
        .preferredColorScheme(colorScheme)
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with gradient
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 20 * fontScale, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)
                    Text("PimPid")
                        .font(.system(size: 16 * fontScale, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.autoCorrectEnabled ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(appState.autoCorrectEnabled
                             ? String(localized: "menu.status.on", bundle: appState.localizedBundle)
                             : String(localized: "menu.status.off", bundle: appState.localizedBundle))
                            .font(.system(size: 10 * fontScale, weight: .medium))
                            .foregroundStyle(appState.autoCorrectEnabled ? .green : .secondary)
                    }
                    .accessibilityElement(children: .combine)
                }

                Text(String(localized: "app.tagline", bundle: appState.localizedBundle))
                    .font(.system(size: 11 * fontScale))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)

            Divider()
                .padding(.vertical, 2)

            // Quick toggles
            VStack(spacing: 10) {
                Toggle(isOn: $appState.autoCorrectEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(appState.autoCorrectEnabled ? .orange : .gray)
                        Text(String(localized: "a11y.autocorrect_label", bundle: appState.localizedBundle))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
                .toggleStyle(.switch)
                .disabled(!AccessibilityHelper.isAccessibilityTrusted)
                .accessibilityLabel(String(localized: "a11y.autocorrect_label", bundle: appState.localizedBundle))
                .accessibilityHint(String(localized: "a11y.autocorrect_hint", bundle: appState.localizedBundle))
            }

            // Accessibility warning
            if !AccessibilityHelper.isAccessibilityTrusted {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text(String(localized: "accessibility.warning", bundle: appState.localizedBundle))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    Button(String(localized: "accessibility.open_settings", bundle: appState.localizedBundle)) {
                        AccessibilityHelper.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.system(size: 11))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            Divider()
                .padding(.vertical, 2)

            // Convert Selected Text
            Button(action: {
                Task { @MainActor in
                    await TextReplacementService.convertSelectedText(
                        excludeStore: ExcludeListStore.shared,
                        enabled: appState.autoCorrectEnabled,
                        direction: nil
                    )
                }
            }) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                    Text(String(localized: "menu.convert_selected", bundle: appState.localizedBundle))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(KeyboardShortcutManager.shortcutDisplayString())
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.12))
                        )
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .disabled(!appState.autoCorrectEnabled)
            .accessibilityLabel("\(String(localized: "menu.convert_selected", bundle: appState.localizedBundle)), \(KeyboardShortcutManager.shortcutDisplayString())")

            Divider()
                .padding(.vertical, 2)

            // Statistics
            ConversionStatsView()

            // Recent conversions
            RecentConversionsView()

            Divider()
                .padding(.vertical, 2)

            // Action buttons
            VStack(spacing: 6) {
                Button(action: { openSettings() }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                        Text(String(localized: "menu.settings", bundle: appState.localizedBundle))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 5)

                Divider()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                        Text(String(localized: "menu.quit", bundle: appState.localizedBundle))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 5)
            }
        }
        .padding(16)
        .frame(minWidth: menuWidth, maxWidth: menuWidth)
    }

    private var menuWidth: CGFloat {
        let base: CGFloat = 320
        switch appState.appearanceFontSize {
        case "small": return base * 0.95
        case "large": return base * 1.1
        case "xl": return base * 1.25
        default: return base
        }
    }
}
