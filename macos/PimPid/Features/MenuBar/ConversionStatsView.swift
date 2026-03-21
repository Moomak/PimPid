import SwiftUI
import CoreGraphics

/// แสดงสถิติการแปลงใน menu bar
struct ConversionStatsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var stats = ConversionStats.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                Text(String(localized: "stats.header", bundle: appState.localizedBundle))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            // Stats grid
            HStack(spacing: 12) {
                StatBadge(
                    icon: "calendar",
                    label: String(localized: "stats.today", bundle: appState.localizedBundle),
                    value: "\(stats.todayConversions)",
                    unit: String(localized: "stats.times", bundle: appState.localizedBundle)
                )

                StatBadge(
                    icon: "sum",
                    label: String(localized: "stats.total", bundle: appState.localizedBundle),
                    value: "\(stats.totalConversions)",
                    unit: String(localized: "stats.times", bundle: appState.localizedBundle)
                )
            }

            // Task 66: กราฟ 7 วันล่าสุด
            let days = stats.last7DaysCounts()
            let allZero = days.isEmpty || days.allSatisfy({ $0.count == 0 })
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "stats.last7days", bundle: appState.localizedBundle))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                if allZero {
                    Text(String(localized: "stats.empty_graph", bundle: appState.localizedBundle))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                } else {
                    let maxCount = max(days.map(\.count).max() ?? 1, 1)
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, item in
                            VStack(spacing: 3) {
                                if item.count > 0 {
                                    Text("\(item.count)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.4)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 24, height: max(3, CGFloat(item.count) / CGFloat(maxCount) * 32))
                                Text(shortDayLabel(item.date))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(shortDayLabel(item.date)): \(item.count)")
                        }
                    }
                    .frame(height: 52)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(String(localized: "stats.last7days", bundle: appState.localizedBundle))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
}

private func shortDayLabel(_ dateKey: String) -> String {
    guard dateKey.count >= 10 else { return dateKey }
    return String(dateKey.suffix(2))
}

/// แถวแสดงสถิติแต่ละรายการ (legacy — kept for backward compat)
struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

/// Compact stat badge showing value prominently
struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}

/// แสดงรายการแปลงล่าสุด
struct RecentConversionsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var stats = ConversionStats.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                Text(String(localized: "recent.header", bundle: appState.localizedBundle))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if !stats.recentConversions.isEmpty {
                    Text("\(min(stats.recentConversions.count, 5))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.12))
                        )
                }
            }

            // Recent conversions list
            if stats.recentConversions.isEmpty {
                Text(String(localized: "recent.no_history", bundle: appState.localizedBundle))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(stats.recentConversions.prefix(5)) { record in
                        RecentConversionRow(record: record)
                    }
                }
            }

            if !stats.recentConversions.isEmpty {
                Divider()
                    .padding(.vertical, 2)

                HStack(spacing: 12) {
                    Button(String(localized: "button.clear_recent", bundle: appState.localizedBundle)) {
                        ConversionStats.shared.clearRecentConversions()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)

                    Button(String(localized: "button.undo_last", bundle: appState.localizedBundle)) {
                        if ConversionStats.shared.undoLastConversion() != nil {
                            UndoHelper.sendUndoKeyPress()
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
}

/// Task 67: ส่ง Cmd+Z เพื่อ undo การ paste ล่าสุดในแอปที่โฟกัส
enum UndoHelper {
    static func sendUndoKeyPress() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCode: UInt16 = 0x06
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
    }
}

/// แถวแสดงการแปลงแต่ละรายการ
struct RecentConversionRow: View {
    @EnvironmentObject var appState: AppState
    let record: ConversionRecord
    @StateObject private var excludeStore = ExcludeListStore.shared

    /// คำต้นทาง (ตัวเล็ก) ที่จะ exclude — ใช้ original เพราะเป็นคำที่ user พิมพ์
    private var excludeWord: String {
        record.original.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        HStack(spacing: 8) {
            // Direction emoji
            Text(record.direction.emoji)
                .font(.system(size: 10))

            // Conversion text
            HStack(spacing: 4) {
                Text(record.original)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)

                Text(record.converted)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            // Exclude button
            if !excludeWord.isEmpty && !excludeStore.contains(excludeWord) {
                Button {
                    excludeStore.add(excludeWord)
                } label: {
                    Text(String(localized: "recent.exclude_button", bundle: appState.localizedBundle))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
                .buttonStyle(.plain)
                .help(String(localized: "recent.add_exclude", bundle: appState.localizedBundle))
            } else if !excludeWord.isEmpty {
                Text(String(localized: "recent.excluded_label", bundle: appState.localizedBundle))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            // Time ago
            Text(timeAgo(from: record.timestamp))
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return String(localized: "time.just_now", bundle: appState.localizedBundle)
        } else if interval < 3600 {
            return String(format: String(localized: "time.minutes_ago", bundle: appState.localizedBundle), Int(interval / 60))
        } else if interval < 86400 {
            return String(format: String(localized: "time.hours_ago", bundle: appState.localizedBundle), Int(interval / 3600))
        } else {
            return String(format: String(localized: "time.days_ago", bundle: appState.localizedBundle), Int(interval / 86400))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ConversionStatsView()
        RecentConversionsView()
    }
    .padding()
    .frame(width: 300)
}
