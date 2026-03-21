import Foundation

/// Logic การตัดสินใจว่าจะแทนที่คำที่พิมพ์ด้วยอะไร — ใช้ร่วมได้ทั้ง engine จริงและ simulation (ไม่มี app/window)
/// สำหรับจำลองบทความ: รับ word + excludeWords แล้วคืน (converted, direction) หรือ nil
enum AutoCorrectionLogic {

    struct ReplacementResult {
        let converted: String
        let direction: KeyboardLayoutConverter.ConversionDirection
    }

    /// Override บางคำไทยที่พิมพ์ผิด layout → คำอังกฤษที่ต้องการ (สนพก = lord ตามปุ่ม)
    private static let thaiToEnglishOverrides: [String: String] = [
        "สนพก": "lord",
    ]

    /// คำอังกฤษที่ไม่อยากให้แปลงเป็นไทย (เช่น com สำหรับ domain) — ใช้ใน ConversionValidator
    static let englishKeepAsIs: Set<String> = [
        "com", "cloud",
        "881", "ano", "avo", "cla", "cri", "dao", "idor", "ios",
        "lot", "mcp", "mem", "opt", "req", "ski", "soko", "vec",
    ]

    /// Default technical terms ที่ไม่ควรถูก auto-correct (case-insensitive)
    /// ใช้ตรวจก่อน exclude list ของ user เพื่อลด false positive จากคำ tech ทั่วไป
    static let defaultExcludedTechTerms: Set<String> = [
        // Version control
        "git", "svn", "hg",
        // Package managers / build tools
        "npm", "npx", "yarn", "pnpm", "pip", "brew", "apt", "cargo", "make", "cmake",
        // Web / protocols
        "api", "url", "uri", "http", "https", "ftp", "ssh", "ssl", "tls", "tcp", "udp", "dns",
        "cors", "rest", "grpc", "graphql", "oauth", "jwt", "smtp", "imap",
        // Languages / markup
        "html", "css", "scss", "sass", "less", "json", "xml", "yaml", "yml", "toml",
        "sql", "jsx", "tsx", "vue", "php", "perl", "ruby", "rust", "golang",
        // Frameworks / tools
        "node", "deno", "bun", "react", "next", "nuxt", "vite", "webpack", "babel",
        "docker", "nginx", "redis", "mongo", "mysql", "postgres",
        "laravel", "django", "flask", "rails", "express", "fastapi",
        "swift", "xcode", "cocoa", "swiftui",
        // Common dev terms
        "localhost", "stdin", "stdout", "stderr", "argv", "argc", "async", "await",
        "null", "nil", "void", "bool", "enum", "struct", "class", "func", "impl",
        "sudo", "chmod", "chown", "grep", "awk", "sed", "curl", "wget",
        // Cloud / services
        "aws", "gcp", "azure", "vercel", "heroku", "netlify",
        // File extensions often typed
        "pdf", "png", "jpg", "jpeg", "gif", "svg", "mp3", "mp4", "mov", "zip", "tar",
        // Misc tech
        "cli", "gui", "ide", "sdk", "cdn", "ci", "cd", "devops", "saas", "paas",
        "regex", "cron", "env", "config", "init", "login", "admin", "root",
    ]

    /// คืนผลลัพธ์ที่ engine จะใช้แทนที่สำหรับ "คำที่ user พิมพ์" (ผิด layout)
    /// ไม่เช็ค app/window — ใช้สำหรับ simulation หรือเมื่อ caller ตรวจแล้ว
    static func replacement(
        for word: String,
        excludeWords: Set<String>
    ) -> ReplacementResult? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Minimum word length: ต้องมีอย่างน้อย 2 ตัวอักษรจึงจะแปลง
        guard trimmed.count >= 2 else { return nil }

        let lower = trimmed.lowercased()
        if excludeWords.contains(lower) { return nil }

        // ตรวจ default tech terms (case-insensitive)
        if defaultExcludedTechTerms.contains(lower) { return nil }

        // Mixed language ratio check: ถ้ามีทั้ง Thai + English > 30% ของแต่ละภาษา → skip
        if hasMixedLanguageAboveThreshold(trimmed, threshold: 0.3) { return nil }

        let direction = KeyboardLayoutConverter.dominantLanguage(trimmed)
        var converted = KeyboardLayoutConverter.convertAuto(trimmed)
        if direction == .thaiToEnglish, let override = Self.thaiToEnglishOverrides[trimmed] {
            converted = override
        }

        // กรณี mixed (เช่น "20" พิมพ์ผิดเป็น "/จ") ได้ direction .none — ลอง Thai→English ถ้าผลเป็นตัวเลขให้ใช้
        if direction == .none {
            let asEnglish = KeyboardLayoutConverter.convertThaiToEnglish(trimmed)
            if asEnglish != trimmed,
               Self.looksLikeNumber(asEnglish),
               ConversionValidator.shouldReplace(converted: asEnglish, direction: .thaiToEnglish, original: trimmed) {
                return ReplacementResult(converted: asEnglish, direction: .thaiToEnglish)
            }
            return nil
        }

        guard converted != trimmed else { return nil }

        guard ConversionValidator.shouldReplace(converted: converted, direction: direction, original: trimmed) else {
            return nil
        }

        return ReplacementResult(converted: converted, direction: direction)
    }

    private static func looksLikeNumber(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return false }
        let dots = t.filter { $0 == "." }.count
        return t.allSatisfy { $0.isNumber || $0 == "." } && dots <= 1
    }

    /// ตรวจว่าข้อความมี mixed language (ทั้ง Thai + English) เกิน threshold หรือไม่
    /// เช่น threshold 0.3 หมายความว่าถ้าทั้ง Thai ratio >= 30% และ English ratio >= 30% → ถือว่า mixed
    /// ข้อความ mixed มักเป็นการพิมพ์ตั้งใจ ไม่ควร auto-correct
    private static func hasMixedLanguageAboveThreshold(_ text: String, threshold: Double) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        var thaiCount = 0
        var engCount = 0
        for scalar in trimmed.unicodeScalars {
            let v = scalar.value
            if v >= 0x0E01 && v <= 0x0E5B { thaiCount += 1 }
            else if scalar.isASCII && (Character(scalar).isLetter || Character(scalar).isNumber) { engCount += 1 }
        }
        let total = thaiCount + engCount
        guard total > 0 else { return false }
        let thaiRatio = Double(thaiCount) / Double(total)
        let engRatio = Double(engCount) / Double(total)
        return thaiRatio >= threshold && engRatio >= threshold
    }
}
