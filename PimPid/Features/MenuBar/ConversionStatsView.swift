import SwiftUI

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
                    label: "วันนี้",
                    value: "\(stats.todayConversions) ครั้ง"
                )

                StatRow(
                    icon: "sum",
                    label: "ทั้งหมด",
                    value: "\(stats.totalConversions) ครั้ง"
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
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
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
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

                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)

                Text(record.converted)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
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
