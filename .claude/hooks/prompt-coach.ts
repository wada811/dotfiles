#!/usr/bin/env -S node
/**
 * prompt-coach — Claude Code の UserPromptSubmit hook（Tier A 注入 ＋ Tier C 計測）
 *
 * 目的:
 *   人間のプロンプトが best practice（成功条件 / 検証手段 / 対象ファイル）を満たすかを
 *   安価なヒューリスティクス（正規表現のみ・LLM 不使用）で検証し、欠けていれば
 *   Claude 側に「着手前の補完指示」を additionalContext として注入する。
 *   人間の記憶に依存せず、雑なプロンプトでも Claude が標準フロー（探索→計画→検証）に乗る。
 *
 * 設計方針:
 *   - ブロックしない（プロンプト消去は摩擦が高く、過剰だと無視される）。文脈注入のみ。
 *   - 「検証手段が無い非自明タスク」に絞って発火（過剰ナグ＝無視を防ぐ）。
 *   - いかなる例外でもセッションを壊さない（必ず exit 0・例外時は無出力）。
 *   - Tier C: 生プロンプトは記録せず「特徴フラグのみ」を JSONL に追記（プライバシー / 容量）。
 *
 * 実行: Node の型ストリップで .ts を直接実行（Node >= 23.6）。
 * 参照: workspace/claude-quality-flow.md §3・§5・§10 / Claude Code Best Practices / Hooks docs
 */
import { readFileSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const LOG_PATH = join(homedir(), ".claude", "prompt-coach.log.jsonl");

// --- 検出パターン -----------------------------------------------------------
const CHANGE = /(implement|add|fix|refactor|build|create|change|write|migrat|rewrite|optimi[sz]e|実装|修正|追加|リファクタ|直し|直して|作っ|作って|変更|書い|書いて|移行|対応|置き換え|リネーム)/;
const QUESTION = /^(what|why|how|where|when|which|does|can|is|are|should i|なぜ|どう|どこ|どれ|何|教えて|調べて|説明|とは)/;
const TRIVIAL = /(typo|誤字|rename|リネーム|ログ(行|を)?追加|コメント|import 文|フォーマット|format)/;
const VERIFY = /(test|spec|verif|検証|テスト|ビルド|build|lint|確認|スクショ|screenshot|通る|pass|green|再現|repro)/;
const SUCCESS = /(成功条件|完了条件|受け入れ|acceptance|期待される|という状態|を満たす|rubric|定義は)/;
const FILEREF = /[\w/.\-]+\.(ts|tsx|js|jsx|py|go|rs|java|kt|md|json|ya?ml|sql|sh|rb|php|css|html)\b/;
const BUG = /(fix|bug|バグ|失敗|fail|error|エラー|落ちる|直)/;
const BIG = /(refactor|リファクタ|設計|アーキ|architecture|design|大規模|全(て|部)|across|複数ファイル|migrat|移行)/;
// Tier C 用: 後続プロンプトが「訂正」かの言語シグナル（集計側で初回以外に適用）
const CORRECTION = /(no[,. ]|not |instead|actually|still |again|違う|ちがう|そうじゃ|やり直|まだ|やっぱり|間違|直して|戻して|undo|revert)/;

type Features = {
  len: number; slash: boolean; is_task: boolean; question: boolean; trivial: boolean;
  has_verify: boolean; has_success: boolean; has_fileref: boolean;
  bug: boolean; big: boolean; corr_lang: boolean;
};

function classify(prompt: string): Features {
  const low = prompt.toLowerCase();
  return {
    len: prompt.length,
    slash: prompt.startsWith("/"),
    is_task: CHANGE.test(low),
    question: QUESTION.test(low),
    trivial: TRIVIAL.test(low) && prompt.length < 160,
    has_verify: VERIFY.test(low),
    has_success: SUCCESS.test(low),
    has_fileref: prompt.includes("@") || FILEREF.test(low),
    bug: BUG.test(low),
    big: BIG.test(low),
    corr_lang: CORRECTION.test(low),
  };
}

function buildNote(f: Features): string | null {
  // 除外: slash コマンド / 質問・探索 / 非タスク / 自明な小修正
  if (f.slash || f.question || !f.is_task || f.trivial) return null;
  // 主トリガ: 検証手段が無い非自明タスク
  if (f.has_verify) return null;

  const missing = ["検証手段"];
  if (!f.has_success) missing.push("成功条件");
  if (!f.has_fileref) missing.push("対象ファイル");

  let tip: string;
  if (f.bug) {
    tip = "着手前に:(1)「直った」の定義を1文で確認し(2)まず失敗するテストで再現してから根本原因を直す（症状の握りつぶし禁止）。";
  } else if (f.big) {
    tip = "着手前に plan mode で探索→計画を出し approach を確認してから実装する。対象が広いなら対象ファイルを列挙し各々に検証(OK/FAIL)を付ける。";
  } else {
    tip = "着手前に:(1)成功条件を1文で再述し(2)自分で回せる検証(テスト/ビルド/スクリプト/スクショ)を提案して実装後に実行する。";
  }

  return `[prompt-coach] この依頼は best practice 要素（${missing.join(", ")}）が未指定です。${tip} ` +
    "approach が不確実なら AskUserQuestion で blocking な点だけ1回確認する。" +
    "スコープが明確で小さいならこの注意は無視して直接実行してよい。";
}

// Tier C: 特徴フラグのみ追記。生プロンプトは記録しない。失敗してもセッションに影響させない。
// eligible=コーチ対象だった / coached=実際に注入した / held_out=対象だが A/B 比較のため意図的に抑止
function logFeatures(data: any, f: Features, flags: { eligible: boolean; coached: boolean; held_out: boolean }): void {
  try {
    const rec = {
      ts: Math.floor(Date.now() / 1000),
      session: data.session_id ?? "",
      cwd: data.cwd ?? "",
      len: f.len, is_task: f.is_task, trivial: f.trivial,
      has_verify: f.has_verify, has_success: f.has_success, has_fileref: f.has_fileref,
      bug: f.bug, big: f.big, corr_lang: f.corr_lang,
      eligible: flags.eligible, coached: flags.coached, held_out: flags.held_out,
    };
    appendFileSync(LOG_PATH, JSON.stringify(rec) + "\n");
  } catch { /* noop */ }
}

function main(): void {
  const data = JSON.parse(readFileSync(0, "utf8"));
  const prompt = (data.prompt ?? "").trim();
  if (!prompt) return;
  const f = classify(prompt);
  const note = buildNote(f);
  const eligible = note !== null;

  // 効果測定用ホールドアウト(任意): COACH_HOLDOUT=0.3 等で、対象プロンプトの一定割合を
  // 意図的に「注入しない」。同一母集団(対象)内で coached vs held_out を比較でき、
  // 「コーチ自体の効果」を交絡なく測れる(RCT)。既定 0 = 無効(常に注入)。
  const holdout = Math.max(0, Math.min(1, Number(process.env.COACH_HOLDOUT) || 0));
  const heldOut = eligible && holdout > 0 && Math.random() < holdout;
  const coached = eligible && !heldOut;

  logFeatures(data, f, { eligible, coached, held_out: heldOut }); // Tier C: 全プロンプトを計測
  if (coached && note) {
    const out = { hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: note } };
    process.stdout.write(JSON.stringify(out));
  }
}

try {
  main();
} catch {
  // セッションを絶対に壊さない
}
process.exit(0);
