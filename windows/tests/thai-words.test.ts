/**
 * Tests for thai-words.ts — Thai word recognition and prefix matching
 */
import { describe, it, expect } from "vitest";
import { containsKnownThai, hasWordWithPrefix, isThaiCodePoint } from "../src/thai-words";

describe("isThaiCodePoint", () => {
  it("returns true for Thai characters", () => {
    expect(isThaiCodePoint(0x0e01)).toBe(true); // ก
    expect(isThaiCodePoint(0x0e5b)).toBe(true); // ๛
    expect(isThaiCodePoint(0x0e2a)).toBe(true); // ส
  });

  it("returns false for non-Thai characters", () => {
    expect(isThaiCodePoint(0x0041)).toBe(false); // A
    expect(isThaiCodePoint(0x0e00)).toBe(false); // just below Thai range
    expect(isThaiCodePoint(0x0e5c)).toBe(false); // just above Thai range
    expect(isThaiCodePoint(0)).toBe(false);
  });
});

describe("containsKnownThai", () => {
  it("returns false for empty string", () => {
    expect(containsKnownThai("")).toBe(false);
  });

  it("returns false for whitespace-only", () => {
    expect(containsKnownThai("   ")).toBe(false);
  });

  it("returns true for a known single Thai word", () => {
    expect(containsKnownThai("ครับ")).toBe(true);
    expect(containsKnownThai("ค่ะ")).toBe(true);
    expect(containsKnownThai("เป็น")).toBe(true);
    expect(containsKnownThai("ที่")).toBe(true);
    expect(containsKnownThai("และ")).toBe(true);
  });

  it("returns true for multiple known words separated by space", () => {
    expect(containsKnownThai("ครับ ค่ะ")).toBe(true);
    expect(containsKnownThai("เป็น ที่")).toBe(true);
  });

  it("returns false for unknown Thai text", () => {
    expect(containsKnownThai("zzz")).toBe(false);
    expect(containsKnownThai("xyz")).toBe(false);
  });

  it("returns true for concatenated known Thai words (no space)", () => {
    // "ไม่เป็น" = "ไม่" + "เป็น" — both are known words
    expect(containsKnownThai("ไม่เป็น")).toBe(true);
  });

  it("returns true for word with ๆ (mai yamok)", () => {
    // "ดีๆ" = "ดี" + "ๆ" — ดี is known, ๆ is repetition mark
    expect(containsKnownThai("ดีๆ")).toBe(true);
  });

  it("handles trimming", () => {
    expect(containsKnownThai("  ครับ  ")).toBe(true);
  });

  it("returns false for English text", () => {
    expect(containsKnownThai("hello")).toBe(false);
    expect(containsKnownThai("world")).toBe(false);
  });
});

describe("hasWordWithPrefix", () => {
  it("returns false for empty prefix", () => {
    expect(hasWordWithPrefix("")).toBe(false);
  });

  it("returns false for single character prefix (length < 2)", () => {
    expect(hasWordWithPrefix("ก")).toBe(false);
  });

  it("returns true for prefix of a known word", () => {
    // "ครับ" is in the word list, "คร" is a prefix
    expect(hasWordWithPrefix("คร")).toBe(true);
  });

  it("returns true when prefix is the full word", () => {
    expect(hasWordWithPrefix("ครับ")).toBe(true);
  });

  it("returns false for non-matching prefix", () => {
    // "zzzz" is unlikely to be a prefix of any Thai word
    expect(hasWordWithPrefix("zzzz")).toBe(false);
  });

  it("handles whitespace trimming", () => {
    expect(hasWordWithPrefix("  คร  ")).toBe(true);
  });
});
