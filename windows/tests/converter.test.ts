/**
 * Tests for converter.ts — keyboard layout conversion between Thai and English
 */
import { describe, it, expect } from "vitest";
import {
  ConversionDirection,
  dominantLanguage,
  convertThaiToEnglish,
  convertEnglishToThai,
  convertAuto,
  THAI_TO_ENGLISH_OVERRIDES,
} from "../src/converter";

// ─── dominantLanguage ────────────────────────────────────────────────────────

describe("dominantLanguage", () => {
  it("returns None for empty string", () => {
    expect(dominantLanguage("")).toBe(ConversionDirection.None);
  });

  it("returns None for whitespace-only string", () => {
    expect(dominantLanguage("   ")).toBe(ConversionDirection.None);
    expect(dominantLanguage("\t\n")).toBe(ConversionDirection.None);
  });

  it("returns ThaiToEnglish for Thai-dominant text", () => {
    expect(dominantLanguage("สวัสดีครับ")).toBe(ConversionDirection.ThaiToEnglish);
    // "ไทย test" has 3 Thai chars (ไ,ท,ย) + vowel mark and 4 English chars (t,e,s,t) = English dominant
    // Actually ไ(0E44) ท(0E17) ย(0E22) = 3 Thai, test = 4 English → English dominant
    // Let's use a clearly Thai-dominant example instead
    expect(dominantLanguage("สวัสดี a")).toBe(ConversionDirection.ThaiToEnglish);
  });

  it("returns EnglishToThai for English-dominant text", () => {
    expect(dominantLanguage("hello world")).toBe(ConversionDirection.EnglishToThai);
    expect(dominantLanguage("test ก")).toBe(ConversionDirection.EnglishToThai);
  });

  it("returns None when Thai and English count are equal", () => {
    // 2 Thai chars, 2 English chars
    expect(dominantLanguage("กข ab")).toBe(ConversionDirection.None);
  });

  it("ignores spaces when counting English characters", () => {
    // spaces should not be counted as English
    expect(dominantLanguage("ก    ")).toBe(ConversionDirection.ThaiToEnglish);
  });

  it("handles numbers as ASCII (English count)", () => {
    // Numbers are ASCII, so counted as English
    expect(dominantLanguage("123")).toBe(ConversionDirection.EnglishToThai);
  });

  it("handles special characters as ASCII", () => {
    // Punctuation like @#$ are ASCII < 128, non-space
    expect(dominantLanguage("@#$")).toBe(ConversionDirection.EnglishToThai);
  });

  it("handles Unicode outside Thai and ASCII", () => {
    // Japanese chars are neither Thai nor ASCII, so counts stay 0
    expect(dominantLanguage("\u3042\u3044")).toBe(ConversionDirection.None);
  });

  it("handles mixed with non-BMP characters", () => {
    // Emoji is not Thai and not ASCII < 128
    expect(dominantLanguage("hello \u{1F600}")).toBe(ConversionDirection.EnglishToThai);
  });
});

// ─── convertThaiToEnglish ────────────────────────────────────────────────────

describe("convertThaiToEnglish", () => {
  it("converts basic Thai chars to English by key position", () => {
    // ฟ → a, ห → s, ก → d, ด → f
    expect(convertThaiToEnglish("ฟหกด")).toBe("asdf");
  });

  it("converts shifted Thai chars to English", () => {
    // ฤ → A (shifted a)
    expect(convertThaiToEnglish("ฤ")).toBe("A");
  });

  it("preserves characters with no mapping", () => {
    expect(convertThaiToEnglish("abc")).toBe("abc");
    expect(convertThaiToEnglish("123")).toBe("123");
  });

  it("applies override for exact match: สนพก → lord", () => {
    expect(convertThaiToEnglish("สนพก")).toBe("lord");
  });

  it("does not apply override for partial match — converts char-by-char", () => {
    // Partial match of override key "สนพก" → char-by-char: ส→l, น→o, พ→r
    expect(convertThaiToEnglish("สนพ")).toBe("lor");
    // Full match triggers override: สนพก → "lord" (not char-by-char "lord")
    expect(convertThaiToEnglish("สนพก")).toBe("lord");
  });

  it("handles empty string", () => {
    expect(convertThaiToEnglish("")).toBe("");
  });

  it("handles space", () => {
    expect(convertThaiToEnglish(" ")).toBe(" ");
  });

  it("converts Thai number row", () => {
    // ๆ → q or 1 (ๆ maps back via thaiToEnglish)
    // From the map: 1 → ๆ and q → ๆ, so ๆ → one of them
    // Since thaiToEnglish is built by iterating englishToThai,
    // q is after 1 in the spread, so ๆ → q (last write wins)
    const result = convertThaiToEnglish("ๆ");
    expect(result).toBe("q"); // q overwrites 1 because it comes later in spread
  });
});

// ─── BUG: thaiToEnglish mapping collision for ๆ ─────────────────────────────
describe("thaiToEnglish mapping collisions", () => {
  it("key '1' and 'q' both map to ๆ — last one wins in reverse map", () => {
    // englishToThaiUnshifted: "1" → "ๆ", then q → "ๆ"
    // When building thaiToEnglish, q overwrites 1 for ๆ
    // This means if user typed ๆ on Thai layout meaning "1", it converts to "q"
    // This is a known limitation but could be a BUG for number row
    const result = convertThaiToEnglish("ๆ");
    // The reverse mapping will give "q" not "1"
    expect(result).toBe("q");
  });
});

// ─── convertEnglishToThai ────────────────────────────────────────────────────

describe("convertEnglishToThai", () => {
  it("converts basic English to Thai by key position", () => {
    expect(convertEnglishToThai("a")).toBe("ฟ");
    expect(convertEnglishToThai("s")).toBe("ห");
    expect(convertEnglishToThai("d")).toBe("ก");
    expect(convertEnglishToThai("f")).toBe("ด");
  });

  it("converts shifted English to Thai", () => {
    expect(convertEnglishToThai("A")).toBe("ฤ");
    expect(convertEnglishToThai("S")).toBe("ฆ");
  });

  it("preserves unmapped characters", () => {
    // Thai characters have no English→Thai mapping
    expect(convertEnglishToThai("ก")).toBe("ก");
  });

  it("converts full words", () => {
    // h→้, e→ำ, l→ส, l→ส, o→น
    const result = convertEnglishToThai("hello");
    expect(result).toBe("้ำสสน");
  });

  it("handles empty string", () => {
    expect(convertEnglishToThai("")).toBe("");
  });

  it("handles space", () => {
    expect(convertEnglishToThai(" ")).toBe(" ");
  });

  it("handles number row", () => {
    expect(convertEnglishToThai("1")).toBe("ๆ");
    expect(convertEnglishToThai("0")).toBe("จ");
  });

  it("handles punctuation", () => {
    expect(convertEnglishToThai("[")).toBe("บ");
    expect(convertEnglishToThai("]")).toBe("ล");
  });
});

// ─── convertAuto ─────────────────────────────────────────────────────────────

describe("convertAuto", () => {
  it("converts Thai text to English", () => {
    const result = convertAuto("ฟหกด");
    expect(result).toBe("asdf");
  });

  it("converts English text to Thai", () => {
    const result = convertAuto("asdf");
    expect(result).toBe("ฟหกด");
  });

  it("returns original text when direction is None", () => {
    expect(convertAuto("")).toBe("");
    expect(convertAuto("   ")).toBe("   ");
  });

  it("returns original text when Thai and English count are equal", () => {
    expect(convertAuto("กข ab")).toBe("กข ab");
  });

  it("converts long Thai sentences", () => {
    const thai = "สวัสดี";
    const result = convertAuto(thai);
    // Should convert to English key positions
    expect(result).not.toBe(thai);
    expect(typeof result).toBe("string");
  });
});

// ─── THAI_TO_ENGLISH_OVERRIDES ──────────────────────────────────────────────

describe("THAI_TO_ENGLISH_OVERRIDES", () => {
  it("contains สนพก → lord", () => {
    expect(THAI_TO_ENGLISH_OVERRIDES["สนพก"]).toBe("lord");
  });

  it("is used by convertThaiToEnglish for exact matches", () => {
    expect(convertThaiToEnglish("สนพก")).toBe("lord");
  });
});
