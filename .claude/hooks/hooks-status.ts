#!/usr/bin/env -S node
/**
 * hooks-status — 3 つの Claude Code hook(prompt-coach / agency-route / coach-report)が
 * 「動いているか」を 1 コマンドで確認するためのステータス表示。
 *
 * 確認できること:
 *   - settings.json に登録されているか(コマンド文字列にスクリプト名が含まれるか)
 *   - 直近発火の相対時刻(per-fire ログを持つ hook のみ)
 *   - 直近24h の発火数 / 総発火数
 *
 * データ源:
 *   - prompt-coach : ~/.claude/prompt-coach.log.jsonl(発火ごとに 1 行)
 *   - agency-route : ~/.claude/agency-route.log.jsonl(発火ごとに 1 行)
 *   - coach-report : per-fire ログ無し(reader=週次 digest)。最終 digest の ts を
 *                    ~/.claude/.prompt-coach-last-digest から表示、無ければ "—"。
 *
 * 実行: node ~/.claude/hooks/hooks-status.ts
 */
import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const HOME = homedir();
const SETTINGS_PATH = join(HOME, ".claude", "settings.json");
const PROMPT_COACH_LOG = join(HOME, ".claude", "prompt-coach.log.jsonl");
const AGENCY_ROUTE_LOG = join(HOME, ".claude", "agency-route.log.jsonl");
const DIGEST_STAMP = join(HOME, ".claude", ".prompt-coach-last-digest");

// settings.json の全 hook コマンド文字列を集める(イベント問わず)。
function registeredCommands(): string[] {
  try {
    const settings = JSON.parse(readFileSync(SETTINGS_PATH, "utf8"));
    const cmds: string[] = [];
    for (const groups of Object.values(settings.hooks ?? {}) as any[]) {
      for (const g of groups ?? []) {
        for (const h of g.hooks ?? []) {
          if (typeof h.command === "string") cmds.push(h.command);
        }
      }
    }
    return cmds;
  } catch {
    return [];
  }
}

// JSONL の ts(秒) 一覧を読む。壊れた行は無視。
function readTimestamps(path: string): number[] {
  if (!existsSync(path)) return [];
  const ts: number[] = [];
  for (const line of readFileSync(path, "utf8").split("\n")) {
    const t = line.trim();
    if (!t) continue;
    try {
      const r = JSON.parse(t);
      if (typeof r.ts === "number") ts.push(r.ts);
    } catch { /* skip */ }
  }
  return ts;
}

function relTime(ts: number | null, now: number): string {
  if (ts == null) return "—";
  const d = now - ts;
  if (d < 0) return "未来?";
  if (d < 60) return `${d}秒前`;
  if (d < 3600) return `${Math.floor(d / 60)}分前`;
  if (d < 86400) return `${Math.floor(d / 3600)}時間前`;
  return `${Math.floor(d / 86400)}日前`;
}

function reg(cmds: string[], name: string): string {
  return cmds.some((c) => c.includes(name)) ? "✓" : "✗ 未登録";
}

function main(): void {
  const now = Math.floor(Date.now() / 1000);
  const cmds = registeredCommands();

  const pc = readTimestamps(PROMPT_COACH_LOG);
  const ar = readTimestamps(AGENCY_ROUTE_LOG);
  const cutoff = now - 86400;
  const last = (a: number[]) => (a.length ? Math.max(...a) : null);
  const last24h = (a: number[]) => a.filter((t) => t >= cutoff).length;

  // coach-report は per-fire ログ無し。最終 digest の ts を表示。
  let digestTs: number | null = null;
  try { digestTs = Number(readFileSync(DIGEST_STAMP, "utf8").trim()) || null; } catch { /* none */ }

  const rows = [
    ["prompt-coach", "UserPromptSubmit", reg(cmds, "prompt-coach.ts"), relTime(last(pc), now), String(last24h(pc)), String(pc.length), "per-fire ログ"],
    ["agency-route", "UserPromptSubmit", reg(cmds, "agency-route.ts"), relTime(last(ar), now), String(last24h(ar)), String(ar.length), "per-fire ログ"],
    ["coach-report", "SessionStart", reg(cmds, "coach-report.ts"), relTime(digestTs, now), "—", "—", "reader(週次digest)・最終digest時刻"],
  ];

  const header = ["hook", "イベント", "登録", "直近発火", "直近24h", "総数", "備考"];
  const lines = [
    `# Claude Code hooks ステータス（${new Date(now * 1000).toLocaleString("ja-JP")} 時点）`,
    "",
    `| ${header.join(" | ")} |`,
    `| ${header.map(() => "---").join(" | ")} |`,
    ...rows.map((r) => `| ${r.join(" | ")} |`),
    "",
    "注: 直近発火/直近24h/総数は per-fire ログを持つ hook のみ。coach-report は週次 digest を書く reader のため",
    "直近発火列に最終 digest の時刻を表示する(まだ一度も digest を出していなければ —)。",
  ];
  process.stdout.write(lines.join("\n") + "\n");
}

main();
