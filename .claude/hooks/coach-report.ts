#!/usr/bin/env -S node
/**
 * coach-report — Tier C 集計。prompt-coach.log.jsonl を読み、prompt-coach が
 * 「効いているか」を測る。self-evolving の eval ゲートと同じ「客観信号で守る」発想で、
 * nag ではなく測定で閉じ、効かなければ緩める/外す判断材料にする。
 *
 * 3 つの観点（信頼度の高い順）:
 *   1. 運用テレメトリ … 発火率・対象率。過剰ナグ(=無視され逆効果)になっていないか。最も確実。
 *   2. 因果(ホールドアウト A/B) … COACH_HOLDOUT>0 のとき、対象プロンプトの一部を意図的に
 *      未注入にし、coached vs held_out で「直後の訂正率」を比較。同一母集団なので交絡が小さい。
 *   3. 相関(参考) … 検証手段ありのセッション vs なしの平均訂正数。交絡(タスク難度)あり=参考値。
 *
 * 使い方:
 *   node coach-report.ts                 # 全期間を集計し markdown を標準出力
 *   node coach-report.ts --days 7        # 直近7日
 *   node coach-report.ts --out report.md
 *   node coach-report.ts --session-start # SessionStart hook 用: 週1回だけ digest を JSON で返す
 * 参照: workspace/claude-quality-flow.md §10
 */
import { readFileSync, existsSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const HOME = homedir();
const LOG_PATH = join(HOME, ".claude", "prompt-coach.log.jsonl");
const REPORT_PATH = join(HOME, ".claude", "prompt-coach-report.md");
const STAMP_PATH = join(HOME, ".claude", ".prompt-coach-last-digest");

type Row = {
  ts: number; session: string; is_task?: boolean; trivial?: boolean;
  has_verify?: boolean; corr_lang?: boolean;
  eligible?: boolean; coached?: boolean; held_out?: boolean;
};

function load(days: number | null): Row[] {
  const cutoff = days ? Date.now() / 1000 - days * 86400 : 0;
  if (!existsSync(LOG_PATH)) return [];
  const rows: Row[] = [];
  for (const line of readFileSync(LOG_PATH, "utf8").split("\n")) {
    const t = line.trim();
    if (!t) continue;
    try {
      const r = JSON.parse(t) as Row;
      if ((r.ts ?? 0) >= cutoff) rows.push(r);
    } catch { /* skip */ }
  }
  return rows;
}

function bySession(rows: Row[]): Row[][] {
  const m = new Map<string, Row[]>();
  for (const r of rows) {
    const k = r.session ?? "";
    if (!m.has(k)) m.set(k, []);
    m.get(k)!.push(r);
  }
  const out = [...m.values()];
  for (const s of out) s.sort((a, b) => (a.ts ?? 0) - (b.ts ?? 0));
  return out;
}

function summarize(rows: Row[]) {
  const sessions = bySession(rows);

  // 1. 運用テレメトリ
  const total = rows.length;
  const eligible = rows.filter((r) => r.eligible).length;
  const coached = rows.filter((r) => r.coached).length;
  const heldOut = rows.filter((r) => r.held_out).length;

  // 2. 因果(ホールドアウト): 対象プロンプトの「直後プロンプトが訂正か」を coached/held_out で比較
  const ab = { coached: { n: 0, corr: 0 }, held: { n: 0, corr: 0 } };
  for (const s of sessions) {
    for (let i = 0; i < s.length; i++) {
      const r = s[i];
      if (!r.eligible) continue;
      const next = s[i + 1];
      const followCorr = next && next.corr_lang ? 1 : 0;
      if (r.coached) { ab.coached.n++; ab.coached.corr += followCorr; }
      else if (r.held_out) { ab.held.n++; ab.held.corr += followCorr; }
    }
  }

  // 3. 相関(参考): 初回タスクプロンプトの検証手段有無 × セッション平均訂正数
  const corr = { withV: { sessions: 0, c: 0 }, noV: { sessions: 0, c: 0 } };
  let taskSessions = 0;
  for (const s of sessions) {
    const idx = s.findIndex((r) => r.is_task && !r.trivial);
    if (idx < 0) continue;
    taskSessions++;
    const g = s[idx].has_verify ? corr.withV : corr.noV;
    g.sessions++;
    g.c += s.slice(idx + 1).filter((r) => r.corr_lang).length;
  }

  return { total, eligible, coached, heldOut, taskSessions, ab, corr };
}

type Summary = ReturnType<typeof summarize>;
const pct = (x: number) => `${Math.round(x * 100)}%`;
const rate = (g: { n: number; corr: number }) => (g.n ? g.corr / g.n : 0);

function render(m: Summary): string {
  const L: string[] = [
    "# prompt-coach レポート（Tier C: 効いているかの測定）",
    "",
    "## 1. 運用テレメトリ（最も確実）",
    `- 集計プロンプト数: ${m.total}`,
    `- コーチ対象(eligible): ${m.eligible}（全体の ${pct(m.total ? m.eligible / m.total : 0)}）`,
    `- 実際に注入(coached): ${m.coached} / ホールドアウト(held_out): ${m.heldOut}`,
    `- タスク・セッション数: ${m.taskSessions}`,
  ];
  if (m.total && m.eligible / m.total > 0.5) {
    L.push("- ⚠️ 対象率が高すぎる兆候。過剰ナグ＝無視のリスク → 分類を厳しめに。");
  }

  L.push("", "## 2. 因果（ホールドアウト A/B・交絡小）", "");
  if (m.ab.coached.n && m.ab.held.n) {
    const c = rate(m.ab.coached), h = rate(m.ab.held);
    L.push("| 群 | 対象数 | 直後訂正率 |", "|---|---|---|",
      `| coached(注入) | ${m.ab.coached.n} | ${pct(c)} |`,
      `| held_out(未注入) | ${m.ab.held.n} | ${pct(h)} |`, "");
    if (h - c >= 0.1) L.push(`**所見:** 注入で直後訂正率が ${pct(h - c)} 低い → コーチは効いている。`);
    else if (c - h >= 0.1) L.push(`**所見:** 注入の方が訂正率が高い → 逆効果の可能性。文面/分類を見直す。`);
    else L.push("**所見:** 有意差なし。サンプル不足の可能性大（個人利用は N が小さく検出力が低い点に注意）。");
  } else {
    L.push("ホールドアウト未収集。`COACH_HOLDOUT=0.3` を 2 週間ほど設定すると、コーチ自体の効果を",
      "交絡なく測れる（対象の 30% を意図的に未注入にし比較）。既定 0 では常に注入＝因果測定なし。");
  }

  L.push("", "## 3. 相関（参考・交絡あり）", "",
    "| 初回プロンプトに検証手段 | セッション数 | 平均訂正数 |", "|---|---|---|",
    `| あり | ${m.corr.withV.sessions} | ${(m.corr.withV.sessions ? m.corr.withV.c / m.corr.withV.sessions : 0).toFixed(2)} |`,
    `| なし | ${m.corr.noV.sessions} | ${(m.corr.noV.sessions ? m.corr.noV.c / m.corr.noV.sessions : 0).toFixed(2)} |`,
    "", "*タスク難度の交絡を含むため因果の証拠にはならない（方向性の参考のみ）。*");

  return L.join("\n") + "\n";
}

// SessionStart 用: 週1回だけ digest を返す（毎回は出さない＝context を汚さない）
function sessionStartDigest(): void {
  const now = Date.now() / 1000;
  let last = 0;
  try { last = Number(readFileSync(STAMP_PATH, "utf8").trim()) || 0; } catch { /* none */ }
  if (now - last < 7 * 86400) return; // 7日未満なら無言
  const m = summarize(load(30));
  try { writeFileSync(REPORT_PATH, render(m)); } catch { /* noop */ }
  try { writeFileSync(STAMP_PATH, String(Math.floor(now))); } catch { /* noop */ }
  const ctx = `[prompt-coach 週次] 過去30日: 対象 ${m.eligible}/${m.total} 件・注入 ${m.coached} 件。` +
    `詳細は ${REPORT_PATH}。セッション冒頭でこの1行を ユーザーに伝え、必要なら測定結果を要約して。`;
  process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: ctx } }));
}

function main(): void {
  const argv = process.argv.slice(2);
  if (argv.includes("--session-start")) { try { sessionStartDigest(); } catch { /* セッションを壊さない */ } return; }
  let days: number | null = null;
  let out: string | null = null;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--days") days = Number(argv[++i]);
    else if (argv[i] === "--out") out = argv[++i];
  }
  const text = render(summarize(load(days)));
  if (out) { writeFileSync(out, text); console.log(`wrote ${out}`); }
  else process.stdout.write(text);
}

main();
