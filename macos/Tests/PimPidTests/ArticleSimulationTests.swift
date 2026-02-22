import XCTest
@testable import PimPid

/// จำลองบทความ: โหลดบทความที่ถูกต้อง → จำลองการพิมพ์แบบลืมเปลี่ยนภาษา → เช็คว่าคำไหนไม่ถูกเปลี่ยน
/// ใช้แก้จุดบกพร่องเรื่องการเปลี่ยนภาษา
final class ArticleSimulationTests: XCTestCase {

    private let minWordLength = 2
    private let maxWordLen = 20

    /// แยกข้อความไทยติดกันเป็นคำ (greedy longest-match จาก ThaiWordList) เพื่อให้ simulation ได้คำระดับคำ ไม่ใช่ทั้งวลี
    private func segmentThaiIntoWords(_ segment: String, wordSet: Set<String>) -> [String] {
        var result: [String] = []
        var i = segment.startIndex
        let end = segment.endIndex
        while i < end {
            let remaining = segment.distance(from: i, to: end)
            guard remaining >= minWordLength else { break }
            var found = false
            let tryLen = min(maxWordLen, remaining)
            for len in (minWordLength...tryLen).reversed() {
                guard let j = segment.index(i, offsetBy: len, limitedBy: end) else { continue }
                let sub = String(segment[i..<j])
                if wordSet.contains(sub) {
                    result.append(sub)
                    i = j
                    found = true
                    break
                }
            }
            if !found {
                let rest = String(segment[i...])
                if rest.count >= minWordLength {
                    result.append(rest)
                }
                break
            }
        }
        return result
    }

    private func tokenize(_ article: String) -> [String] {
        let wordSet = ThaiWordList.words
        let punctuation = CharacterSet(charactersIn: ".,!?;:\"\"''()[]–—")
        return article
            .split(whereSeparator: \.isWhitespace)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.trimmingCharacters(in: punctuation) }
            .filter { !$0.isEmpty }
            .flatMap { segment -> [String] in
                guard segment.count >= minWordLength else { return [] }
                if KeyboardLayoutConverter.dominantLanguage(segment) == .thaiToEnglish {
                    return segmentThaiIntoWords(segment, wordSet: wordSet)
                }
                return [segment]
            }
            .filter { $0.count >= minWordLength }
    }

    private func isThaiWord(_ word: String) -> Bool {
        KeyboardLayoutConverter.dominantLanguage(word) == .thaiToEnglish
    }

    private func isEnglishWord(_ word: String) -> Bool {
        KeyboardLayoutConverter.dominantLanguage(word) == .englishToThai
    }

    /// จำลองคำที่พิมพ์ผิด layout: คำถูกต้อง → สิ่งที่ user พิมพ์ (ผิดภาษา)
    private func simulateTypedWord(correctWord: String) -> String? {
        if isThaiWord(correctWord) {
            return KeyboardLayoutConverter.convertThaiToEnglish(correctWord)
        }
        if isEnglishWord(correctWord) {
            return KeyboardLayoutConverter.convertEnglishToThai(correctWord)
        }
        return nil
    }

    struct Failure {
        let correctWord: String
        let typed: String
        let expected: String
        let actual: String?
        let kind: FailureKind
        enum FailureKind {
            case noCorrection
            case wrongCorrection
        }
    }

    private func runSimulation(article: String) -> (total: Int, passed: Int, failures: [Failure]) {
        let words = tokenize(article)
        var seen = Set<String>()
        var failures = [Failure]()
        var passed = 0

        for correctWord in words {
            let key = correctWord.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)

            guard let typed = simulateTypedWord(correctWord: correctWord) else { continue }

            let result = AutoCorrectionLogic.replacement(for: typed, excludeWords: [])

            if result == nil {
                failures.append(Failure(
                    correctWord: correctWord,
                    typed: typed,
                    expected: correctWord,
                    actual: nil,
                    kind: .noCorrection
                ))
            } else if result!.converted != correctWord {
                failures.append(Failure(
                    correctWord: correctWord,
                    typed: typed,
                    expected: correctWord,
                    actual: result!.converted,
                    kind: .wrongCorrection
                ))
            } else {
                passed += 1
            }
        }

        let total = passed + failures.count
        return (total, passed, failures)
    }

    /// รายชื่อบทความใน Resources ที่ใช้ทดสอบ simulation (หลายเคส)
    private static let articleResourceNames = [
        "article-01", "article-02", "article-03", "article-04", "article-05",
        "article-06", "article-07", "article-08", "article-09", "article-10",
        "article-11", "article-12", "article-13", "article-14", "article-15",
        "article-16", "article-17", "article-18", "article-19", "article-20",
        "article-21", "article-22", "article-23", "article-24", "article-25",
        "article-26", "article-27", "article-28", "article-29", "article-30",
    ]

    func testArticleSimulationFromResource() throws {
        guard let url = Bundle.module.url(forResource: "article-01", withExtension: "txt"),
              let article = try? String(contentsOf: url, encoding: .utf8) else {
            XCTFail("Could not load article-01.txt from test resources")
            return
        }

        let (total, passed, failures) = runSimulation(article: article)

        XCTAssertGreaterThan(total, 0, "Should have at least one word to check")

        // บทความที่แยกคำด้วย space อย่างเดียว จะได้ "คำ" เป็นกลุ่มข้อความระหว่างช่องว่าง
        // (อาจยาวเป็นวลี/ประโยค) — engine ออกแบบมาแก้ทีละคำสั้น ๆ และคำที่รู้จัก
        // จึงมักได้ "ไม่แก้" เยอะเมื่อใช้บทความไทยยาว
        // ใช้ failures เป็นข้อมูลเพื่อปรับปรุง logic/คำใน list ไม่ได้หมายความว่าเทสต้องผ่านทุกคำ
        if !failures.isEmpty {
            // พิมพ์สรุปใน console เวลารันเทส (เห็นใน Xcode / swift test)
            print("--- Article simulation report (article-01) ---")
            print("Total: \(total), Passed: \(passed), Failures: \(failures.count)")
            let noCorrection = failures.filter { $0.kind == .noCorrection }.count
            let wrongCorrection = failures.filter { $0.kind == .wrongCorrection }.count
            print("  No correction: \(noCorrection), Wrong correction: \(wrongCorrection)")
            print("--- Sample failures (first 10) ---")
            for f in failures.prefix(10) {
                switch f.kind {
                case .noCorrection:
                    print("  [ไม่แก้] \"\(f.correctWord.prefix(40))\(f.correctWord.count > 40 ? "…" : "")\" (typed: \(f.typed.prefix(20))…)")
                case .wrongCorrection:
                    print("  [แก้ผิด] expected \"\(f.expected.prefix(30))…\", got \"\(f.actual ?? "")\"")
                }
            }
            print("--------------------------------")
        }

        // เทสผ่านเสมอเมื่อมีคำให้เช็ค — จำนวน failure ใช้เป็นข้อมูล ไม่ fail build
        XCTAssertTrue(total > 0, "Should have at least one word to check")
    }

    /// รัน simulation กับบทความทุกไฟล์ใน Resources แล้วรวมผล — ใช้ดูภาพรวมและรวบรวม failure words
    func testArticleSimulationAllArticles() throws {
        var grandTotal = 0, grandPassed = 0
        var allFailures: [Failure] = []
        var reports: [String] = []

        for name in Self.articleResourceNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "txt"),
                  let article = try? String(contentsOf: url, encoding: .utf8) else { continue }

            let (total, passed, failures) = runSimulation(article: article)
            grandTotal += total
            grandPassed += passed
            allFailures.append(contentsOf: failures)
            let pct = total > 0 ? Int(100 * passed / total) : 0
            reports.append("  \(name): \(passed)/\(total) (\(pct)%)")
        }

        XCTAssertGreaterThan(grandTotal, 0, "Should have at least one article and word to check")

        let uniqueFailureWords = Set(allFailures.map(\.correctWord))
        let wrongCount = allFailures.filter { $0.kind == .wrongCorrection }.count

        print("--- Article simulation (all \(Self.articleResourceNames.count) articles) ---")
        for line in reports { print(line) }
        print("Total: \(grandPassed)/\(grandTotal) passed (\(grandTotal > 0 ? Int(100 * grandPassed / grandTotal) : 0)%), \(allFailures.count) failures (\(uniqueFailureWords.count) unique), \(wrongCount) wrong correction")
        print("--- Unique failure words (first 100, by length) ---")
        for w in uniqueFailureWords.sorted(by: { $0.count < $1.count || ($0.count == $1.count && $0 < $1) }).prefix(100) {
            print("  \(w)")
        }
        if uniqueFailureWords.count > 100 {
            print("  … and \(uniqueFailureWords.count - 100) more")
        }
        print("--------------------------------")
        // เขียนรายการ failure words ลงไฟล์เพื่อให้ loop อ่านและเพิ่มคำ (optional)
        let sortedWords = uniqueFailureWords.sorted(by: { $0.count < $1.count || ($0.count == $1.count && $0 < $1) })
        if let dir = ProcessInfo.processInfo.environment["PIMPID_FAILURES_DIR"],
           !dir.isEmpty {
            let outDir = (dir as NSString)
            try? sortedWords.joined(separator: "\n").write(toFile: outDir.appendingPathComponent("failure-words.txt"), atomically: true, encoding: .utf8)
            let summary = "total=\(grandTotal)\npassed=\(grandPassed)\nfailures=\(allFailures.count)\nunique=\(uniqueFailureWords.count)\n"
            try? summary.write(toFile: outDir.appendingPathComponent("summary.txt"), atomically: true, encoding: .utf8)
        }
    }

    /// ยืนยันว่า engine แก้ QWERTY ที่ map กับคำไทยใน list กลับเป็นคำไทยได้
    func testReplacementForKnownThaiWord() {
        XCTAssertEqual(
            AutoCorrectionLogic.replacement(for: "rd", excludeWords: [])?.converted,
            "พก",
            "rd (typed with Thai layout) should correct to พก"
        )
    }
}
