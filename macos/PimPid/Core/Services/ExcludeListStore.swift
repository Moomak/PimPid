import Foundation

/// เก็บรายการคำที่ไม่ต้องการให้โปรแกรมแก้ไข (exclude list). ใช้จาก Main Actor เท่านั้น (ตาม modern-concurrency)
@MainActor
final class ExcludeListStore: ObservableObject {
    static let shared = ExcludeListStore()
    private let defaults = UserDefaults.standard

    @Published private(set) var words: Set<String> = []

    init() {
        load()
    }

    func load() {
        if let array = defaults.stringArray(forKey: PimPidKeys.excludeWords) {
            words = Set(array.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        } else {
            words = []
        }
    }

    func add(_ word: String) {
        let w = word.trimmingCharacters(in: .whitespaces).lowercased()
        guard !w.isEmpty else { return }
        words.insert(w)
        save()
    }

    func remove(_ word: String) {
        words.remove(word.lowercased())
        save()
    }

    func contains(_ word: String) -> Bool {
        words.contains(word.trimmingCharacters(in: .whitespaces).lowercased())
    }

    /// ตรวจว่าข้อความที่ให้มาควรข้ามการแปลงหรือไม่ (ถ้ามีคำใน exclude อยู่ทั้งหมดหรือเป็นคำเดียวที่อยู่ในรายการ)
    func shouldExclude(text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let lower = trimmed.lowercased()
        if words.contains(lower) { return true }
        let tokens = lower.split(separator: " ").map(String.init)
        if tokens.isEmpty { return true }
        return tokens.allSatisfy { words.contains($0) }
    }

    private func save() {
        defaults.set(Array(words).sorted(), forKey: PimPidKeys.excludeWords)
    }
}
