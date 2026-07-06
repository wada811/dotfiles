#!/usr/bin/env npx tsx
/**
 * Extract user messages from all Claude session JSONL files.
 * Output: JSON array of { sessionId, project, date, messages: string[] }
 */

import fs from "fs";
import path from "path";
import os from "os";

const CLAUDE_DIR = path.join(os.homedir(), ".claude", "projects");
const MAX_MSG_LENGTH = 500; // truncate very long messages
const MAX_SESSIONS = 200; // safety limit

interface SessionEntry {
  type?: string;
  isMeta?: boolean;
  sessionId?: string;
  timestamp?: string;
  message?: {
    role?: string;
    content?: unknown;
  };
  slug?: string;
}

interface SessionSummary {
  sessionId: string;
  project: string;
  date: string;
  slug: string;
  messages: string[];
}

// 抽出ログに API トークン等が平文で残るのを防ぐ（issue #371）。
// プレフィックスが既知のトークンと、KEY=値 / TOKEN: 値 形式の代入を伏字化する。
function maskSecrets(text: string): string {
  return text
    .replace(/xox[baprs]-[A-Za-z0-9-]{10,}/g, "[REDACTED_SLACK_TOKEN]")
    .replace(/xapp-[A-Za-z0-9-]{10,}/g, "[REDACTED_SLACK_TOKEN]")
    .replace(
      /(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}/g,
      "[REDACTED_GITHUB_TOKEN]",
    )
    .replace(/github_pat_[A-Za-z0-9_]{20,}/g, "[REDACTED_GITHUB_TOKEN]")
    .replace(/(?:ntn_|secret_)[A-Za-z0-9]{20,}/g, "[REDACTED_NOTION_TOKEN]")
    .replace(/AIza[0-9A-Za-z_-]{35}/g, "[REDACTED_GOOGLE_API_KEY]")
    .replace(/bitpat_[A-Za-z0-9-]{10,}/gi, "[REDACTED_BITRISE_TOKEN]")
    .replace(
      /\b([A-Za-z0-9_]*(?:TOKEN|SECRET|API_?KEY|PASSWORD|CREDENTIALS?))\b(\s*[=:]\s*)(["']?)[^\s"']{8,}\3/gi,
      "$1$2[REDACTED]",
    );
}

function extractTextFromContent(content: unknown): string | null {
  if (typeof content === "string") {
    // Skip tool results, command invocations, and system tags
    if (
      content.includes("<local-command-caveat>") ||
      content.includes("<local-command-stdout>") ||
      content.includes("<command-name>/clear</command-name>") ||
      content.includes("<tool_result") ||
      content.trim().length === 0
    ) {
      return null;
    }
    // Strip XML-like tags but keep the text
    const stripped = content
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    return stripped.length > 10 ? stripped : null;
  }
  if (Array.isArray(content)) {
    const texts = content
      .map((c) => {
        if (typeof c === "object" && c !== null && "type" in c) {
          const item = c as { type: string; text?: string };
          if (item.type === "text" && item.text) return item.text.trim();
        }
        return null;
      })
      .filter(Boolean);
    return texts.length > 0 ? texts.join(" ") : null;
  }
  return null;
}

function processSessionFile(
  filePath: string,
  project: string
): SessionSummary | null {
  const lines = fs.readFileSync(filePath, "utf-8").split("\n").filter(Boolean);
  const messages: string[] = [];
  let sessionId = "";
  let firstTimestamp = "";
  let slug = "";

  for (const line of lines) {
    let entry: SessionEntry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }

    if (entry.type !== "user" || entry.isMeta) continue;
    if (!entry.message || entry.message.role !== "user") continue;

    if (!sessionId && entry.sessionId) sessionId = entry.sessionId;
    if (!firstTimestamp && entry.timestamp) firstTimestamp = entry.timestamp;
    if (!slug && entry.slug) slug = entry.slug;

    const text = extractTextFromContent(entry.message.content);
    if (!text) continue;

    // Skip very short/boring messages
    if (text.length < 15) continue;

    // トークンが途中で切れて伏字化漏れするのを防ぐため、truncate 前にマスキングする
    const masked = maskSecrets(text);
    const truncated =
      masked.length > MAX_MSG_LENGTH
        ? masked.slice(0, MAX_MSG_LENGTH) + "…"
        : masked;
    messages.push(truncated);
  }

  if (messages.length === 0) return null;

  return {
    sessionId,
    project,
    date: firstTimestamp ? firstTimestamp.slice(0, 10) : "unknown",
    slug,
    messages,
  };
}

function main() {
  if (!fs.existsSync(CLAUDE_DIR)) {
    console.error(`Claude projects dir not found: ${CLAUDE_DIR}`);
    process.exit(1);
  }

  const projects = fs.readdirSync(CLAUDE_DIR);
  const allSessions: SessionSummary[] = [];

  for (const project of projects) {
    const projectDir = path.join(CLAUDE_DIR, project);
    if (!fs.statSync(projectDir).isDirectory()) continue;

    const files = fs
      .readdirSync(projectDir)
      .filter((f) => f.endsWith(".jsonl"))
      .map((f) => path.join(projectDir, f))
      .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs) // newest first
      .slice(0, MAX_SESSIONS);

    for (const file of files) {
      const session = processSessionFile(file, project);
      if (session) allSessions.push(session);
    }
  }

  // Sort by date desc
  allSessions.sort((a, b) => b.date.localeCompare(a.date));

  // Output stats + condensed view
  const stats = {
    totalSessions: allSessions.length,
    projects: [...new Set(allSessions.map((s) => s.project))],
    dateRange: {
      from: allSessions[allSessions.length - 1]?.date,
      to: allSessions[0]?.date,
    },
  };

  console.log("=== STATS ===");
  console.log(JSON.stringify(stats, null, 2));

  console.log("\n=== SESSIONS (newest first) ===");
  for (const session of allSessions) {
    console.log(`\n[${session.date}] ${session.project} / ${session.slug || session.sessionId.slice(0, 8)}`);
    for (const msg of session.messages) {
      console.log(`  - ${msg}`);
    }
  }
}

main();
