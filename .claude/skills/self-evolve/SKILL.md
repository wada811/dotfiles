---
name: self-evolve
description: Drive the self-evolving-agent project (~/Documents/self-evolving-agent) — run a self-improvement generation, check genome status, refresh the user's profile, or gate an external proposal. Use when the user wants to evolve/improve the agent, run a loop/work/eval generation, inspect or roll back the genome (agent-config), refresh about-andy, ingest an orch branch, or manage the daily auto-loop automation.
---

# self-evolve

Operational driver for **`~/Documents/self-evolving-agent`** — a general agent that self-evolves its own prompt/procedures/skills/lessons, every change gated by an objective fitness suite and persisted as a git commit (1 commit = 1 generation). All user-facing output in **Japanese** (ユーザーのポリシー).

## Hard rules (read first)

- **Run everything from the project dir via the pinned Node.** The project pins a dedicated `node 24.16.0` (mise) that is separate from the global node 25.x and holds Full Disk Access. Always:
  ```bash
  cd ~/Documents/self-evolving-agent && mise exec -- npm run <cmd> -- ...
  ```
  Plain `npm`/`node` may use the wrong node and lack FDA.
- **Never edit `src/` (the loop body) or `evals/cases/` (the tests).** These are sacred — the agent self-evolves *only* `agent-config/` (markdown genome). `src/restrict.ts` enforces this at runtime. If asked to change loop behavior or eval cases, surface it as a human decision, don't just do it.
- **Auth:** no `ANTHROPIC_API_KEY` needed — it falls back to the existing Claude Code login (プロダクト Teams plan). A run that needs the LLM (`work`/`loop`/`eval`/`ingest`) consumes that quota; `status`/`evolve` (dry-run) do not.
- **Cost/latency:** a full `loop` generation runs the work agent + the 10-case golden eval suite → **several minutes + LLM cost**. Don't fire it casually; confirm with the user first unless they clearly asked for a generation.

## Figure out where the user is, then act

| User intent | Command |
|---|---|
| 「今どんな状態?」ゲノム版・baseline・世代ログ | `mise exec -- npm run status` |
| 1 タスク実行して採点だけ（進化なし・安全） | `mise exec -- npm run work -- "<task>"` |
| **1 世代まるごと自己進化**（work→eval→reflect→evolve→guard→commit/revert） | `mise exec -- npm run loop -- "<task>" [--count N]` |
| 直近 run の進化プランを見るだけ（LLM コストなし） | `mise exec -- npm run evolve` |
| golden スイート実行 / baseline 更新 | `mise exec -- npm run eval [-- --set-baseline]` |
| ユーザー プロフィール（知識）を work の最新から再生成 | `mise exec -- npm run refresh-profile` |
| orch の `orch/<id>` ブランチ提案を eval ゲートで採否判定（merge はしない） | `mise exec -- npm run ingest -- orch/<id> [--dry-run]` |
| node パスのズレ点検（FDA 要付け替え検知） | `mise exec -- npm run doctor` |

- **`<task>`** is a concrete work item the agent performs (e.g. "この議事録を要約して workspace/x.md に出せ"). Multi-line tasks must be quoted. `loop` reflects on the result and proposes genome edits; the fitness gate keeps the change only if `post + 3 >= baseline`, else auto-reverts.
- After a `loop`, report: accepted or reverted, the post score vs baseline, and the new genome version (from `status`). Inspect diffs with `git -C ~/Documents/self-evolving-agent log/show`. Roll back a bad generation with `git revert`.

## Daily auto-loop (already wired)

A LaunchAgent (`com.wada811.self-evolving-agent.autoloop`) runs **one gated generation every day at 08:35**, but **only if Claude Code was used since the last run** (a global SessionEnd hook touches `runs/.active`; `scripts/auto-loop.ts` gates on it). Idle days cost nothing; never more than once per activity period.

- Standing task: `goals/auto-loop-task.md` if present, else a built-in kaizen default. Edit that file to retune what the autonomous generation works on.
- Did it run? `tail runs/auto-loop.history.log` — 1 line per fire (skip reason or run outcome: behavior evolved vX→vY / reverted / error). Full detail in `runs/autoloop.out.log` / `runs/autoloop.err.log`. Stamps: `runs/.active`, `runs/.last-auto-loop`.
- Manage: `launchctl list | grep autoloop`, `launchctl bootout gui/$(id -u)/com.wada811.self-evolving-agent.autoloop` to disable, re-`bootstrap` the plist to re-enable. Force a run now: `mise exec -- node --import tsx scripts/auto-loop.ts` (still respects the activity gate). See `docs/auto-loop.md`.

## genome → Claude Code bridge (already wired)

The genome compounds inside the SDK agent; ordinary Claude Code sessions don't read `agent-config/` on their own. `scripts/sync-to-claude.ts` mirrors it across (idempotent, marker-bounded / `se-` namespaced — never clobbers hand-written content):

- `lessons.md` → managed block in `~/.claude/CLAUDE.md`
- `about-andy.md` → `memory/se-about-andy.md` (+ MEMORY.md index line)
- `agent-config/skills/<name>` → `~/.claude/skills/se-skill-<name>/` (prunes removed ones)
- `agent-config/procedures/<name>` → `~/.claude/skills/se-proc-<name>/` (on-demand, avoids context bloat)

It runs automatically at the end of every `auto-loop` (skip or run). **After any manual genome change** (manual `loop`, `ingest` merge, `refresh-profile`), re-sync:
```bash
cd ~/Documents/self-evolving-agent && mise exec -- node --import tsx scripts/sync-to-claude.ts
```
See `docs/claude-code-bridge.md`. Check `SYNC` lines in `runs/auto-loop.history.log`.

## After the work

Per ユーザーのポリシー, when you've completed a step, propose ranked next actions with the AskUserQuestion tool rather than ending flatly.
