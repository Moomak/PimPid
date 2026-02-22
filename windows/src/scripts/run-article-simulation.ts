/**
 * จำลองบทความ: อ่านบทความที่ถูกต้อง → จำลองการพิมพ์แบบลืมเปลี่ยนภาษา → เช็คว่าคำไหนไม่ถูกเปลี่ยน
 * รันด้วย: electron dist/scripts/run-article-simulation.js [path/to/article.txt]
 * หรือ pipe: type article.txt | electron dist/scripts/run-article-simulation.js
 * (เมื่อไม่มีอาร์กิวเมนต์ จะอ่านจาก stdin)
 */

import * as fs from "fs";
import * as path from "path";
import {
  getReplacementForTypedWord,
} from "../auto-correction";
import {
  convertThaiToEnglish,
  convertEnglishToThai,
  dominantLanguage,
  ConversionDirection,
} from "../converter";

const MIN_WORD_LEN = 2;

function tokenize(article: string): string[] {
  return article
    .split(/\s+/)
    .map((w) => w.replace(/^\s+|\s+$/g, "").replace(/^[\s.,!?;:""''()\[\]–—]+|[\s.,!?;:""''()\[\]–—]+$/g, ""))
    .filter((w) => w.length >= MIN_WORD_LEN);
}

function isThaiWord(word: string): boolean {
  return dominantLanguage(word) === ConversionDirection.ThaiToEnglish;
}

function isEnglishWord(word: string): boolean {
  return dominantLanguage(word) === ConversionDirection.EnglishToThai;
}

/** จำลองคำที่พิมพ์ผิด layout: คำถูกต้อง → สิ่งที่ user พิมพ์ (ผิดภาษา) */
function simulateTypedWord(correctWord: string): string | null {
  if (isThaiWord(correctWord)) {
    return convertThaiToEnglish(correctWord);
  }
  if (isEnglishWord(correctWord)) {
    return convertEnglishToThai(correctWord);
  }
  return null; // mixed or none — skip
}

interface Failure {
  correctWord: string;
  typed: string;
  expected: string;
  actual: string | null;
  kind: "no_correction" | "wrong_correction";
}

function runSimulation(article: string): { total: number; passed: number; failures: Failure[] } {
  const words = tokenize(article);
  const seen = new Set<string>();
  const failures: Failure[] = [];
  let passed = 0;

  for (const correctWord of words) {
    const key = correctWord.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);

    const typed = simulateTypedWord(correctWord);
    if (typed === null) continue; // skip mixed/unknown

    const result = getReplacementForTypedWord(typed, { excludeWords: [] });

    if (result === null) {
      failures.push({
        correctWord,
        typed,
        expected: correctWord,
        actual: null,
        kind: "no_correction",
      });
    } else if (result.converted !== correctWord) {
      failures.push({
        correctWord,
        typed,
        expected: correctWord,
        actual: result.converted,
        kind: "wrong_correction",
      });
    } else {
      passed++;
    }
  }

  const total = passed + failures.length;
  return { total, passed, failures };
}

let outputJsonPath: string | undefined;

function main(): void {
  const rawArgs = process.argv.slice(2);
  const args: string[] = [];
  for (let i = 0; i < rawArgs.length; i++) {
    if (rawArgs[i] === "--output" && rawArgs[i + 1]) {
      outputJsonPath = path.resolve(process.cwd(), rawArgs[i + 1]);
      i++;
      continue;
    }
    args.push(rawArgs[i]);
  }
  let article: string;

  if (args.length > 0) {
    const filePath = path.resolve(process.cwd(), args[0]);
    if (!fs.existsSync(filePath)) {
      console.error("File not found:", filePath);
      process.exit(1);
    }
    article = fs.readFileSync(filePath, "utf-8");
    runAndReport(article);
  } else {
    const chunks: Buffer[] = [];
    const stdin = process.stdin;
    stdin.setEncoding("utf8");
    stdin.on("data", (chunk: string) => chunks.push(Buffer.from(chunk, "utf8")));
    stdin.on("end", () => {
      const articleFromStdin = Buffer.concat(chunks).toString("utf-8");
      runAndReport(articleFromStdin);
    });
  }
}

function runAndReport(article: string): void {
  const { total, passed, failures } = runSimulation(article);

  console.log("=== PimPid Article Simulation ===\n");
  console.log(`Total words checked: ${total}`);
  console.log(`Passed (corrected as expected): ${passed}`);
  console.log(`Failures: ${failures.length}\n`);

  if (failures.length > 0) {
    console.log("--- Words not corrected or wrong correction ---\n");
    for (const f of failures) {
      if (f.kind === "no_correction") {
        console.log(`  [ไม่แก้] "${f.correctWord}" (typed: "${f.typed}") → expected "${f.expected}", got no correction`);
      } else {
        console.log(`  [แก้ผิด] "${f.correctWord}" (typed: "${f.typed}") → expected "${f.expected}", got "${f.actual}"`);
      }
    }
    if (outputJsonPath) {
      fs.writeFileSync(
        outputJsonPath,
        JSON.stringify({ total, passed, failures }, null, 2),
        "utf-8"
      );
      console.log("\nReport written to:", outputJsonPath);
    }
  }

  process.exit(failures.length > 0 ? 1 : 0);
}

main();
