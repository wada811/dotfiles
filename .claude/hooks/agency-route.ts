#!/usr/bin/env -S node
/**
 * agency-route — Claude Code の UserPromptSubmit hook（principal 専用・委譲判断の注入）
 *
 * 目的:
 *   Human Tab(principal pane)で実作業を頼まれたとき、principal がそのまま実装を
 *   始めてしまうのを防ぐ。「principal でやるか / agent tab へ委譲するか」を着手前に判断させ、
 *   委譲時の new/既存 も判断させる decision protocol を additionalContext として注入する。
 *
 * principal の同定(堅牢・再起動不要):
 *   iTerm2 が各 pane に持たせる ITERM_SESSION_ID("wNtNpN:<UUID>") の <UUID> を、
 *   agency の .state/window.json の principal_id と照合する。一致すれば principal。
 *   agents[].session_id と一致すれば agent pane(=委譲先なので注入しない)。
 *   どちらでもない(他 repo の素 claude 等)・window.json 無しは対象外。
 *   env CLAUDE_AGENCY_ROLE==="principal" も保険のフォールバックとして見る。
 *
 * 設計方針:
 *   - ブロックしない。文脈注入のみ(強制でなく判断支援。Andy 方針)。
 *   - slash コマンド / 純粋な質問・会話には出さない(実作業っぽいプロンプトに絞る)。
 *   - いかなる例外でもセッションを壊さない(必ず exit 0・例外時は無出力)。
 *
 * 実行: Node の型ストリップで .ts を直接実行(Node >= 23.6)。出力形式は prompt-coach と同型。
 */
import { readFileSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// 可観測性ログ(副作用のみ・注入挙動には一切影響しない)。prompt-coach.ts と同方式:
// 1 起動 1 レコードを JSONL 追記。失敗は握りつぶしセッションを壊さない。
const LOG_PATH = join(homedir(), ".claude", "agency-route.log.jsonl");

const CHANGE = /(implement|add|fix|refactor|build|create|change|write|migrat|rewrite|optimi[sz]e|run |実装|修正|追加|リファクタ|直し|直して|作っ|作って|変更|書い|書いて|移行|対応|置き換え|リネーム|ビルド|テスト|調べ|調査|実行|委譲|やって)/;
const QUESTION = /^(what|why|how|where|when|which|does|can|is|are|should i|なぜ|どう|どこ|どれ|何|教えて|説明|とは|だっけ|？|\?)/;

function stateDir(): string {
  // ライブ TS daemon と同一の state を読む(lib/daemon.ts: CLAUDE_AGENCY_STATE_TS ?? ~/Documents/.agency-ts-state)。
  // 旧 CLAUDE_AGENCY_STATE は principal pane(ECC28821)の env に退役済みの .state を指したまま残るため
  // 信頼しない(env 名の不整合解消)。これでフックはライブ window.json の principal_id を正しく読む。
  return process.env.CLAUDE_AGENCY_STATE_TS || join(homedir(), "Documents/.agency-ts-state");
}

function myPaneUUID(): string | null {
  // ITERM_SESSION_ID = "w1t0p1:ECC28821-..." → UUID 部分
  const v = process.env.ITERM_SESSION_ID || "";
  const i = v.indexOf(":");
  return i >= 0 ? v.slice(i + 1) : null;
}

type AgentInfo = { id: string; name: string; session_id?: string; state?: string };

function readWindow(): { principal_id?: string; agents: AgentInfo[] } | null {
  try {
    const win = JSON.parse(readFileSync(join(stateDir(), "window.json"), "utf8"));
    const agents: AgentInfo[] = (win.agents ?? []).map((a: any) => {
      let state: string | undefined;
      try {
        state = JSON.parse(readFileSync(join(stateDir(), `${a.id}.json`), "utf8")).state;
      } catch { /* state 不明は省略 */ }
      return { id: a.id, name: a.name, session_id: a.session_id, state };
    });
    return { principal_id: win.principal_id, agents };
  } catch {
    return null;
  }
}

/** principal pane のときだけ agent 一覧を返す。それ以外(agent pane / 対象外 / 不明)は null。 */
function principalAgents(): AgentInfo[] | null {
  const win = readWindow();
  if (!win) return null; // agency 窓が無い → 対象外
  const uuid = myPaneUUID();
  const isPrincipal =
    (uuid && win.principal_id && uuid === win.principal_id) ||
    (process.env.CLAUDE_AGENCY_ROLE === "principal");
  if (!isPrincipal) return null; // agent pane や他 repo の素 claude
  return win.agents;
}

function buildNote(prompt: string, agents: AgentInfo[]): string | null {
  const low = prompt.toLowerCase();
  if (prompt.startsWith("/")) return null;
  if (QUESTION.test(low) && !CHANGE.test(low)) return null;
  if (!CHANGE.test(low)) return null;

  const candidates = agents.length
    ? agents.map((a) => `${a.id}${a.state ? `(${a.state})` : ""}`).join(" / ")
    : "(なし)";
  const needsYou = agents.filter((a) => a.state === "needs_input").map((a) => a.id);

  const lines = [
    "[agency-route] このペインは principal(Human Tab)。実作業(ファイル変更・ビルド/テスト実行・長い調査)は",
    "principal で直接やらず agent tab へ委譲するのが原則。まず自分で判断する:",
    "- (a) 会話・計画・軽い確認・要約・1ファイルの即答 → principal(ここ)で対応。",
    "- (b) 実作業 → agent tab へ委譲する。new/既存 も自分で判断する:",
    '    既定は【新規 tab に委譲】(/agency new <repo> "<指示>"。worktree 不要な対話/調査や非 repo dir は /agency chat)。',
    '    同じ repo・文脈の続きで明らかに合う既存 tab があればそこへ委譲(/agency send <id> "<指示>")。',
    "本当に迷う(a/b が曖昧、委譲先が決められない)ときだけ AskUserQuestion で確認。",
    "黙って principal で実装を始めない。迷わなければ確認なしで委譲してよい。",
    `現在の agent tab: ${candidates}(一覧 /agency list)。`,
  ];
  if (needsYou.length) {
    lines.push(`⚠ 介入待ち(needs_input): ${needsYou.join(", ")} — 先に応答が要るかも。`);
  }
  return lines.join("\n");
}

/**
 * ログ用の非注入理由。buildNote の早期 return 条件をそのまま鏡写しにしただけで、
 * 判定の source of truth は常に buildNote 側(注入挙動はこの関数に依存しない)。
 */
function noteReason(prompt: string): string {
  const low = prompt.toLowerCase();
  if (prompt.startsWith("/")) return "slash";
  if (QUESTION.test(low) && !CHANGE.test(low)) return "pure-question";
  if (!CHANGE.test(low)) return "not-task";
  return "injected";
}

function logRecord(rec: Record<string, unknown>): void {
  try {
    appendFileSync(LOG_PATH, JSON.stringify({ ts: Math.floor(Date.now() / 1000), hook: "agency-route", ...rec }) + "\n");
  } catch { /* noop */ }
}

try {
  const agents = principalAgents();
  if (agents === null) {
    // principal pane 以外では何もしない(従来どおり)。ログだけ残す。
    let session = "";
    try { session = JSON.parse(readFileSync(0, "utf8") || "{}").session_id ?? ""; } catch { /* stdin 無し等 */ }
    logRecord({ session, is_principal: false, injected: false, reason: "not-principal" });
    process.exit(0);
  }
  const input = JSON.parse(readFileSync(0, "utf8") || "{}");
  const prompt = input.prompt ?? "";
  const note = buildNote(prompt, agents);
  const injected = note !== null;
  logRecord({
    session: input.session_id ?? "",
    is_principal: true,
    injected,
    reason: injected ? "injected" : noteReason(prompt),
  });
  if (note) {
    process.stdout.write(
      JSON.stringify({ hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: note } }),
    );
  }
} catch {
  /* セッションは壊さない */
}
process.exit(0);
