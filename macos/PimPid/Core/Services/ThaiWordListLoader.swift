import Foundation
import SwiftUI

/// Task 19: โหลดคำไทยใน background และแจ้ง progress — ใช้ใน Settings/About แสดงความคืบหน้า
final class ThaiWordListLoader: ObservableObject {
    static let shared = ThaiWordListLoader()

    @Published private(set) var loadProgress: Double = 1.0
    @Published private(set) var isLoaded = false

    private static let lock = NSLock()
    private static var _cachedWords: Set<String>?

    /// คำที่โหลดเสร็จแล้ว (ให้ ThaiWordList ใช้)
    static var cachedWordsIfAvailable: Set<String>? {
        lock.lock()
        defer { lock.unlock() }
        return _cachedWords
    }

    private init() {}

    /// เริ่มโหลดใน background (เรียกจาก AppDelegate)
    func beginLoading() {
        guard !isLoaded else { return }
        DispatchQueue.main.async { [weak self] in
            self?.loadProgress = 0
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.loadWords()
        }
    }

    private func loadWords() {
        var set = Set(EmbeddedThaiWords.list)
        DispatchQueue.main.async { [weak self] in
            self?.loadProgress = 0.5
        }
        if let extra = loadFromBundle() {
            set.formUnion(extra)
        }
        Self.lock.lock()
        Self._cachedWords = set
        Self.lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.loadProgress = 1.0
            self?.isLoaded = true
        }
    }

    private func loadFromBundle() -> Set<String>? {
        let bundles: [Bundle] = {
            #if canImport(AppKit)
            return [Bundle.main, Bundle.module]
            #else
            return [Bundle.module]
            #endif
        }()
        for bundle in bundles {
            if let url = bundle.url(forResource: "ThaiWords", withExtension: "txt"),
               let data = try? Data(contentsOf: url),
               let content = String(data: data, encoding: .utf8) {
                let lines = content.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                return Set(lines)
            }
        }
        return nil
    }
}
