---
name: skill-creator
effort: high
description: |
  新しいスキルの作成・既存スキルの改善・レビューを行う。
  Use when you are about to create a new skill or improve an existing one,
  when a skill is not triggering as expected and description optimization is needed,
  or when you feel a skill's instructions are causing it to behave incorrectly.
---

# Skill Creator

スキルを作り、テストし、改善するためのメタスキル。

## プロセス概要

```
意図の把握 → SKILL.md 作成 → テスト → フィードバックで改善 → 繰り返し
```

ユーザーがどの段階にいるかを判断して、そこから始める。
すでにドラフトがある場合はテスト・改善から。ゼロから作る場合はインタビューから。

---

## Step 1: 意図の把握

現在の会話に「スキル化したいワークフロー」がすでに含まれている場合は、会話から意図を抽出して確認だけする。そうでなければ、以下を質問する。

1. このスキルで Claude に何をさせたいか？
2. どんな状況で使うか？（ユーザーはどんな言葉でリクエストしそうか）
3. 出力の形式・期待する結果は？
4. テストで確認すべきことはあるか？

すべて答えなくてもよい。必要最低限を聞いてすぐに動く。

**事前調査（インタビューと並行して行う）:**
- `.claude/skills/` と `.claude/commands/` を確認し、同じ目的のスキルが既にないか調べる
- 利用可能な MCP サーバーで補完できることがあれば把握しておく
- 類似スキルがあれば、新規作成ではなく改善・統合を検討する

**そもそも skill にすべきかの判定（作らない判断）:**

skill が script や手順に足せる価値は3つだけ — **存在の広告**（description が常駐し Claude が能力の存在を知る）・**使い方の契約**（引数・出力の解釈・安全手順）・**自然言語の発火面**。このどれも足せないなら作らない。

- **判断を足せない 1:1 の薄いラッパー**（本文が「コマンドを実行する」だけ）は作らない。CLAUDE.md または呼び出し元 skill への1行ポインタで代替する
- **他の skill の内部からしか呼ばれない部品**は skill 化しない。発火の恩恵がなく、常駐 description のコストだけが増える
- 既存 skill と管轄・トリガーが重なるなら、新規作成ではなく既存側の description に Do NOT・管轄を書き分ける
- 逆方向はむしろ推奨: 肥大した skill の決定的にできる処理を `scripts/` に切り出し、skill には判断と契約だけ残す

実例: 2026-07-06 に上記基準で薄いラッパー8 skill を削除した（経緯: learnings/general/skill-design-criteria.md）。

---

## Step 2: SKILL.md を書く

### ファイル配置

```
.claude/skills/{skill-name}/
└── SKILL.md          # 必須
```

必要に応じて:
```
├── references/       # 詳細ドキュメント（SKILL.md から参照）
├── scripts/          # 実行スクリプト（Python, Bash など）
└── assets/           # テンプレート・素材
```

### フロントマターの書き方

```yaml
---
name: skill-name          # kebab-case のみ。スペース・大文字・アンダースコア禁止
effort: high              # モデルの推論レベルを上書きする（下記「effort の設定」参照）
description: |            # 最重要。Claude がいつ使うかをここで判断する
  [何をするか] + [いつ使うか（トリガーフレーズを具体的に）] + [主な機能]
disable-model-invocation: true   # 手動起動専用の場合（副作用のある操作など）
argument-hint: "[引数の説明]"    # 引数がある場合
---
```

### effort の設定

`effort` はスキル実行中のモデル推論レベルを上書きする。スキル終了後はセッション設定に戻る。
**「深い推論が出力品質を上げるか」** を基準に判断する。

| 値 | 使う状況 | 例 |
|----|---------|-----|
| `high` | 判断・評価・設計が本質で、深い推論が品質に直結する | evaluate, pr-respond, session-analyzer |
| `medium` | 複数ステップの生成・分析だが、深い推論より網羅性が重要 | worklog, 1on1-prepare, handover |
| `low` | 機械的操作、またはリアルタイム実行で速度優先 | commit, 1on1-record, meeting |

設定しない場合はセッションの effort を継承する。判断に迷ったら `medium` を起点にする。

### description の書き方（最重要）

Claude は description だけを見てスキルを使うか判断する。

description は Claude が自動判断するときだけ参照される（スラッシュコマンドで直接呼ぶ場合は関係ない）。
そのため、ユーザーの発話フレーズではなく **Claude の内部状態**でトリガーを書く。

内部状態の表現パターン:
- `when you are about to X` — アクション直前
- `when you have determined Y` — 判断した瞬間
- `before doing Z` — 実行前の条件
- `when you think it would help to X` — 有益だと判断したとき
- `when you feel X is needed` — 必要性を感じたとき

**良い例:**
```yaml
description: |
  1on1の事前準備ファイルを生成する。
  Use when you are about to have a 1on1 meeting and need to prepare an agenda,
  or when asked to prepare for a meeting with a team member.
```

```yaml
description: |
  Use this skill when you have determined that code changes are needed in a repository
  under repos/ and are about to start reading or editing files there,
  but have not yet confirmed which worktree to work in.
  Do NOT use when already working inside repos/<repo>--<branch>/.
```

**悪い例:**
```yaml
description: 1on1の準備をします。  # 内部状態がない
description: 準備ファイル生成スキル  # 何をするか・いつ使うか両方が不足
```

**ルール:**
- `[何をするか]` と `[いつ使うか（Claude の内部状態）]` を必ず両方書く
- 1024文字以内、XML タグ（`<` `>`）禁止
- `claude` `anthropic` で始まる name は禁止（予約済み）

### 本文の書き方

- 500行以内が理想。超えそうなら詳細を `references/` に移してリンクする
- 命令形で書く（「〜してください」ではなく「〜する」）
- MUST/NEVER を多用しない。代わりに**なぜそうするか**を説明する
- 重要なことは冒頭に書く

**3段階ロード（Progressive Disclosure）:**
1. フロントマター → 常に context に入る（軽く保つ）
2. SKILL.md 本文 → スキル起動時にロード
3. references/ のファイル → 必要なときだけロード

---

## Step 3: テスト

ドラフトができたら 2〜3 個のテストケースを作って実行する。

**テストケースの基準:**
- 実際のユーザーが使いそうなリクエスト
- 明らかすぎるものより、ちょっと曖昧な表現を含める
- 正常系と edge case を混ぜる

**確認すること:**
1. **トリガー確認**: 新しい Claude Code セッションを開いてスキルを有効化し、実際のリクエストを投げてみる
   - `「このスキルをいつ使いますか？」` と聞くと description を引用してくれる
   - 想定外のときに発動しないか確認する
2. **機能確認**: テストプロンプトを実行して出力が期待通りか確認する
   - スキルを書いた自分が実行するとバイアスがかかるため、なるべく「白紙の状態」で試す
3. **比較**: スキルなしの場合と出力を比較する。差が小さければ description か instruction に問題がある

**テストケースを記録する（任意）:**

改善を繰り返す場合は `evals.json` をスキルディレクトリに保存しておくと使い回せる:
```json
[
  {"id": 1, "prompt": "テストプロンプト", "expected": "期待する結果の説明"}
]
```

**より丁寧に評価したい場合（eval viewer）:**

複雑なスキルや定量確認が必要な場合は、公式の eval viewer を使うと subagent でスキルあり・なしを並列実行してブラウザ UI で比較できる。

手順は `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md` の「Running and evaluating test cases」セクションを参照。

---

## Step 4: フィードバックで改善

改善時の考え方:

1. **一般化する**: テストケースだけに効くのではなく、似た状況全般に使えるよう書く。このスキルは同じような状況で何度も使われる。今の 2〜3 ケースにしか効かない「狭い」修正は、次に別のリクエストで使ったときに破綻する。「この修正は、似た状況が10回来たときも機能するか？」を自問する
2. **なぜを説明する**: 「〇〇すること」より「〇〇すると〜になるので〇〇する」。LLM は理由を理解したとき指示を超えた判断ができる。MUST/NEVER と書きたくなったら、それはなぜかを説明するサイン
3. **無駄を削る**: description と instruction の重複を除く。長いほど良いわけではない
4. **スクリプト化を検討**: 複数のテストで同じスクリプトを自分で書いていたら `scripts/` に共通化する。毎回 Claude が同じコードを書き直すなら、1回書いてバンドルする
5. **トランスクリプトを読む**: 最終出力だけでなく実行ログを見る。無駄なステップ・迷走・余計な確認があれば、それを生んでいる instruction を特定して削るか書き直す

改善 → テスト → フィードバック を、ユーザーが満足するまで繰り返す。

---

## Step 5: description の最適化（任意）

スキルが意図通りに起動しない場合:

1. 「このスキルをいつ使いますか？」と Claude に聞いて description を確認
2. トリガーされてほしいフレーズを追加
3. 誤発動しているなら否定トリガーを追加
   ```yaml
   description: ...。〇〇の場合には使わない（代わりに〇〇スキルを使う）。
   ```
4. Claude は **under-trigger** する傾向があるため、description は少し「押し気味」に書く

**eval クエリを使った手動最適化（より丁寧にやる場合）:**

should-trigger と should-not-trigger を 5〜10 問ずつ書き出す:

```
should-trigger（発動してほしい）:
- 明らかなケース + 曖昧な表現 + 略語・タイポありのカジュアルな言い方を混ぜる

should-not-trigger（発動しなくていい）:
- キーワードが被るが目的が違うもの（ニアミス）が最も価値がある
- 「これは別スキルの仕事」というケースを意識的に入れる
```

ニアミスケースを重視する理由: 「全然関係ないリクエスト」での誤発動より、「似た文脈でのトリガー漏れ・誤発動」のほうが実際に困るから。

Claude に実際のリクエストを投げて発動するか確認し、description を書き直す → 繰り返す。

---

## チェックリスト

作成・改善後に確認:

- [ ] 「そもそも skill にすべきかの判定」を通過している（薄い 1:1 ラッパー・内部部品の skill 化になっていない）
- [ ] `SKILL.md` というファイル名（大文字小文字正確に）
- [ ] フォルダ名は kebab-case
- [ ] frontmatter に `---` が開始・終了両方ある
- [ ] `description` に「何をするか」と「いつ使うか」が両方ある
- [ ] `effort` を設定した（high/medium/low の基準は「フロントマターの書き方」参照）
- [ ] XML タグ（`<` `>`）がない
- [ ] 手動起動専用なら `disable-model-invocation: true` がある
- [ ] 実際のテストを 2〜3 件通した

---

## 既存スキルのレビュー

「このスキルをレビューして」と言われた場合:

1. SKILL.md を読む
2. 上記チェックリストを確認
3. description の問題点（トリガー漏れ・誤発動リスク）を指摘
4. 本文の改善点（冗長・説明不足・MUST 多用）を指摘
5. 改善案を提示して、適用するか確認する
