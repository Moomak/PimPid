import SwiftUI
import CoreGraphics

/// แสดงสถิติการแปลงใน menu bar
struct ConversionStatsView: View {
    @ObservedObject var stats = ConversionStats.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text("สถิติ")
                    .font(.system(size: 13, weight: .semibold))
            }

            // Stats grid
            VStack(alignment: .leading, spacing: 8) {
                StatRow(
                    icon: "calendar",
                    label: String(localized: "stats.today"),
                    value: "\(stats.todayConversions) " + String(localized: "stats.times")
                )

                StatRow(
                    icon: "sum",
                    label: String(localized: "stats.total"),
                    value: "\(stats.totalConversions) " + String(localized: "stats.times")
                )
            }

            // Task 66: กราฟ 7 วันล่าสุด
            let days = stats.last7DaysCounts()
            if !days.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "stats.last7days"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    let maxCount = max(days.map(\.count).max() ?? 1, 1)
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, item in
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.blue.opacity(0.6))
                                    .frame(width: 20, height: max(2, CGFloat(item.count) / CGFloat(maxCount) * 24))
                                Text(shortDayLabel(item.date))
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 36)
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

/// แถวแสดงสถิติแต่ละรายการ
struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

/// แสดงรายการแปลงล่าสุด
struct RecentConversionsView: View {
    @ObservedObject var stats = ConversionStats.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                Text("แปลงล่าสุด")
                    .font(.system(size: 13, weight: .semibold))
            }

            // Recent conversions list
            if stats.recentConversions.isEmpty {
                Text("ยังไม่มีประวัติ")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(stats.recentConversions.prefix(5)) { record in
                        RecentConversionRow(record: record)
                    }
                }
            }

            HStack(spacing: 8) {
                if !stats.recentConversions.isEmpty {
                    Button(String(localized: "button.clear_recent")) {
                        ConversionStats.shared.clearRecentConversions()
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)

                    Button(String(localized: "button.undo_last")) {
                        if ConversionStats.shared.undoLastConversion() != nil {
                            UndoHelper.sendUndoKeyPress()
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
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
    let record: ConversionRecord

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
            return "เมื่อสักครู่"
        } else if interval < 3600 {
            return "\(Int(interval / 60))น. ที่แล้ว"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))ชม. ที่แล้ว"
        } else {
            return "\(Int(interval / 86400))วัน ที่แล้ว"
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
