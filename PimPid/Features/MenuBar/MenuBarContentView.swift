import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with gradient
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("PimPid")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Circle()
                        .fill(appState.isEnabled ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }

                Text("ไทย ⇄ English Converter")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            Divider()

            // Quick toggles
            VStack(spacing: 10) {
                Toggle(isOn: $appState.isEnabled) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundColor(appState.isEnabled ? .green : .gray)
                        Text("เปิดใช้งาน")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .toggleStyle(.switch)

                Toggle(isOn: $appState.autoCorrectEnabled) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(appState.autoCorrectEnabled ? .orange : .gray)
                        Text("Auto-Correct")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .toggleStyle(.switch)
                .disabled(!KeyboardShortcutManager.isAccessibilityTrusted)
            }

            // Shortcut info
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("Shortcut:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(ShortcutPreference.displayString(keyCode: ShortcutPreference.keyCode, modifierFlags: ShortcutPreference.modifierFlags))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 4)

            // Accessibility warning
            if !KeyboardShortcutManager.isAccessibilityTrusted {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("ต้องการสิทธิ์ Accessibility")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    Button("เปิดการตั้งค่า") {
                        KeyboardShortcutManager.openAccessibilitySettings()
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

            // Statistics
            ConversionStatsView()

            // Recent conversions
            RecentConversionsView()

            Divider()

            // Action buttons
            VStack(spacing: 8) {
                Button(action: { openSettings() }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                        Text("ตั้งค่า")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text("Quit PimPid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .frame(minWidth: 320, maxWidth: 320)
    }
}
