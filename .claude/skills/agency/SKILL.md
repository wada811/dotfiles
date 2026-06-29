---
name: agency
description: claude-iterm2-agency の agent tab を起動・操作する。新しい agent tab を立てる(new=worktree 隔離あり)、worktree なしの対話/チャット用途で立てる(chat)、既存 tab へ作業を委譲する(send)、稼働中 tab を一覧する(list)。Human Tab(principal)から実作業を agent tab へ委譲したいときに使う。
---

# agency — agent tab を起動・操作する

`~/Documents/claude-iterm2-agency`(以下 ENS)の agent tab を扱うスキル。principal(Human Tab)から実作業を agent tab へ委譲するための入口。

ENS は TypeScript 化済み。単一 CLI `node agency.ts <sub>` で操作する(state dir は `STATE` =
`$CLAUDE_AGENCY_STATE_TS` 既定 `~/Documents/.agency-ts-state`):
- `node agency.ts run <id> <repo> <prompt...>` — 新規 agent tab を inbox 経由で立てる(**要 git repo**。base は `detectBase` が repo ごとに自動判定。<repo> は最新 milestone。worktree 隔離あり)。
- `node agency.ts open "<prompt>" [--repo PATH] [--name NAME] [--id ID]` — **worktree なしの対話/チャットセッション(kind:"chat")** を inbox 経由で立てる。`--repo` 省略時は principal の作業 dir(既定 `~/Documents`)で起動。git repo でない dir でも可。別タブ・RC-first・dashboard 追跡(`chats[]`/`💬`)・label 解決(focus/close 可)は run と同じ。
- `node agency.ts send <id|session> -- <message...>` / `--file PATH` / `--stdin` — 稼働中 tab へ指示を送り Enter 確定。busy なら取りこぼし防止で見送る(`--force` で無視)。
- `node agency.ts focus <id>` / `close <id>` — 稼働中 tab に focus / を閉じる。
- `$STATE/window.json` の `agents[]` = 稼働中 tab、`$STATE/dashboard.txt` = 現況。

## 引数の形

- `/agency new <repo> <指示...>` — repo は basename(`<repo>` 等、`~/Documents/<name>` に解決)か絶対パス。id は repo basename を既定にし、衝突する場合だけ連番。**worktree 隔離ありの実作業向け**。
- `/agency chat [dir|--repo PATH] [指示...]` — **worktree なしの対話/チャットセッション**。dir 省略時は `~/Documents`。git repo でない dir(横断作業・調査・素の対話)でも起動できる。`agency open` に委譲する。
- `/agency send <id> <指示...>` — 既存 tab(window.json の agents[].id / chats[].id)へ委譲する。
- `/agency list` — 稼働中 tab と状態を表示。
- 引数なし — まず `window.json` の agents[]/chats[] を読み、`AskUserQuestion` でセッションを選ばせる。選択肢は **`新規 tab を立てる`(先頭)** + 稼働中タブを `id [kind] state` 形式で列挙(最大3件)。新規を選んだら new 手順のステップ 0(repo 選択)へ進む。既存タブを選んだら続けて `AskUserQuestion` で `send` / `close` / `focus` を選ばせ実行する。**操作が完了したらそこで終了。次の操作が必要なら再度 `/agency` を呼ぶ。**

### 委譲先の選び方(自分で判断、既定は新規作成)
「agent tab へ委譲する」と判断したら、**new / chat / 既存かは自分で判断する**。
- **実作業(コード変更・ビルド・PR)で git repo がある** → **new**(worktree 隔離)。
- **対話・調査・横断作業、または対象が git repo でない dir(例 `~/Documents`)** → **chat**(`agency open`、worktree なし)。
  - 重要: git repo でない dir に対して new(`run`)を使うと worktree が切れず SKIP する。素の iterm2-cli でタブを手作りしない(命名/RC/dashboard 追跡が漏れる)。**worktree 不要なら必ず chat を使う**。
- 同じ repo・同じ文脈の続きで明らかに合う既存 tab があれば、そこへ send。
- **本当に迷うときだけ** AskUserQuestion で確認する(`1. 新規 / 2. 既存(agents[]/chats[] を state 付きで列挙) / 3. ここで続ける`)。迷わないなら確認なしで委譲してよい。

## 手順

### 共通: 事前チェック
1. ENS の daemon 稼働を確認: `~/Documents/.agency-ts-state/agency-ts.pid` の PID が生きているか(`ps -p`)。
2. 死んでいれば `cd ~/Documents/claude-iterm2-agency && ./restart.sh`(reconnect-only)で起こしてから続ける。理由を一言添える。

### new(新規 tab を立てる)
0. **repo が引数に含まれていない場合**は、まず `ls ~/Documents` で候補を列挙し、`AskUserQuestion` で repo だけを選ばせる(選択肢は **`~/Documents` を先頭(デフォルト)** に置き、続けて `~/Documents` 直下の git repo を最大 3 件 + Other。`~/Documents` を選んだ場合は `chat` として扱う(worktree 不要)。**初期プロンプトはここでは聞かない** — 起動後にタブで直接やり取りする)。
1. repo を解決(basename → `~/Documents/<name>`。存在しなければユーザーに確認)。
2. id を決める(既定=repo basename。window.json に同 id があれば `-2` 等で回避)。
3. `cd ~/Documents/claude-iterm2-agency && node agency.ts run <id> <repo解決パス> "待機してください"` を実行(初期プロンプトは固定の「待機してください」)。
4. 立ち上がりは RC-first で数十秒かかる。`dashboard.txt` に `<id>` が現れるまでポーリング(最大 ~90s)。ポーリングは `grep -q "<id>" dashboard.txt` で判定し、見つかったら即 `cat dashboard.txt` で状態を表示する(kind フィルタは使わない)。
5. spawn 失敗(`launch.out` に `SKIP`/`fatal`)なら原因を読んで報告(base 解決失敗なら `repo-base.json` か `detect_base` を疑う)。
6. 完了後、tab の id・base ブランチ・worktree パスを 1〜2 行で報告。

### chat(worktree なしの対話/チャットを立てる)
1. 対象 dir を解決(指定なし → `~/Documents`。`--repo` か位置引数で上書き可。git repo でなくてよい)。
2. `cd ~/Documents/claude-iterm2-agency && node agency.ts open "待機してください" --repo <dir> [--name <名前>]` を実行(初期プロンプトは固定の「待機してください」)。
3. 立ち上がりは RC-first で数十秒。`dashboard.txt` に `<id>` が現れるまでポーリング(最大 ~90s)。`grep -q "<id>" dashboard.txt` で判定し、見つかったら `cat dashboard.txt` で状態を表示する。
4. 完了後、chat の id・cwd を 1〜2 行で報告。以後の指示は `send <id|session>` で送れる(chat も label 解決可)。

### close(tab を閉じる)
1. `cd ~/Documents/claude-iterm2-agency && node agency.ts close <session_id>` を実行。
2. worktree が残っていれば自動で削除する。対象 repo を特定し `git -C <repo> worktree list` で確認、`~/.agency-worktrees/<id>` があれば `git -C <repo> worktree remove <path>` で削除する。
3. 削除完了を `git -C <repo> worktree list` で確認して報告。

### send(既存 tab へ委譲する)
1. 対象 id が window.json の agents/chats に居るか確認。居なければ list を見せて確認。send コマンドには `session_id` を渡す(`id` では解決されない場合がある)。
2. 長文・複数行・バッククォートを含む指示は一時ファイルに書いて `--file` で送る(`-- <message>` は短い 1 行のみ)。
3. `cd ~/Documents/claude-iterm2-agency && node agency.ts send <id> --file /tmp/<id>-msg.txt` を実行。
4. busy で見送られたら(その旨が出る)、ユーザーに「いま busy。`--force` で割り込む?」と確認。勝手に force しない。

### list
1. `cat ~/Documents/.agency-ts-state/dashboard.txt` を見せ、`agents[]` の id・state(running/needs_input/done 等)を要約。
2. `needs_input` があれば先に応答が要る旨を強調。
3. 表示後、`AskUserQuestion` で次の操作を選ばせる(選択肢: `send — tab へ指示を送る` / `close — tab を閉じる` / `focus — tab に移動する` / `そのまま終わる`)。選択後、対応する手順へ進む(send/close/focus は対象 tab の id も聞く)。

## 注意
- 出力・報告はすべて日本語。
- 1-way door(push/PR/外部公開/不可逆)は agent 側が停止して principal へ報告する運用。principal から send で「push して」と委譲する前に、その規約に沿うか確認する。
- agent tab の base ブランチ規約は `repo-base.json`(例 `<repo>` = 最新 milestone)で管理。新 repo で base を変えたいときはそこに追記。
