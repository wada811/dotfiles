---
name: pr-setup
description: 現在のリポジトリにPRワークフローの雛形を設置する。PULL_REQUEST_TEMPLATE・Issueテンプレート・CLAUDE.mdのワークフローセクションを生成する。「このリポジトリでpr-planなどのワークフローを使いたい」「リポジトリのPR設定をしたい」「pr-workflowをセットアップしたい」時に使う。
---

# pr-setup — リポジトリへのPRワークフロー設置

`/pr-plan`, `/pr-develop`, `/commit`, `/pr-create`, `/pr-review` スキルシリーズが機能するための
リポジトリ側の雛形（テンプレート・CLAUDE.md）を一括セットアップする。

## Step 1: リポジトリ確認

```bash
git rev-parse --show-toplevel
git remote get-url origin 2>/dev/null || echo "(no remote)"
```

git リポジトリでない場合は「git リポジトリのルートで実行してください」と伝えて終了する。

## Step 2: 既存ファイルの確認

```bash
ls .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
ls .github/ISSUE_TEMPLATE/plan.md 2>/dev/null
ls CLAUDE.md 2>/dev/null
```

既存ファイルがある場合は「上書きしますか？」と確認してから進む。

## Step 3: ディレクトリ作成

```bash
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p .claude
```

## Step 4: PULL_REQUEST_TEMPLATE.md を生成

`.github/PULL_REQUEST_TEMPLATE.md` を以下の内容で作成する:

```markdown
## 課題
<!-- なぜこの変更が必要か。背景と動機を1〜2行で。 -->
<!-- /pr-plan で作成した Issue をリンク: Closes #NNN -->

Closes #

## 解決策・意図
<!-- どのアプローチを選んだか、なぜか。代替案と選ばなかった理由があれば記載。 -->

## やったこと
<!-- コミット単位のサマリー。/commit で意図別に分割したコミット一覧から引用。 -->
-

## やらなかったこと
<!-- Issue の「スコープ外」欄から引用。実装中に追加で除外したものも記載。 -->
<!-- これがあることでレビュアーが「なぜ実装されていないのか」を疑問に思わなくて済む。 -->
-

## 証跡
<!-- UI変更: スクリーンショット必須。API変更: レスポンス例またはテスト結果。 -->

## 参考
<!-- 関連 Issue・Slack スレッド・外部ドキュメント -->
-
```

## Step 5: Issue テンプレートを生成

`.github/ISSUE_TEMPLATE/plan.md` を以下の内容で作成する:

```markdown
---
name: 実装計画
about: コードを書く前に意図とスコープを記録する（/pr-plan で自動生成）
labels: ''
assignees: ''
---

## 課題
<!-- なぜやるか。背景と動機。 -->

## 解決策・意図
<!-- どのアプローチを選ぶか。代替案と選ばなかった理由も記載すると後で参照しやすい。 -->

## やること
- [ ]
- [ ]

## やらないこと（スコープ外）
<!-- 今回除外する内容と除外理由。「次回以降」「別 Issue」など明示する。 -->
-

## 完了条件
<!-- 何ができたら完了とみなすか。テスト・観察で確認可能な形で書く。 -->
- [ ]
- [ ]
```

## Step 6: CLAUDE.md にワークフローセクションを追記

`CLAUDE.md` が存在すれば末尾に追記、なければ新規作成する。

追記する内容:

```markdown
## 開発ワークフロー

### フロー（この順番で行う）

1. **計画** — `/pr-plan` で実装前に Issue を作成する（コードより意図を先に記録）
2. **開始** — `/pr-develop #<番号>` でスコープを確認し feature ブランチを切る
3. **実装** — コミットは意図単位で。`/commit` が複数意図を検出して分割を提案する
4. **PR作成** — `/pr-create` で Issue と紐付けた PR body を自動生成する
5. **レビュー** — `/pr-review #<番号>` でセルフレビューする

### ルール

- `main`/`master` への直接 commit/push は禁止（hook でブロックされる）
- Issue なしでのコード実装は禁止
- ブランチ名: `feature/#<issue番号>-<kebab-case>`
- コミット形式: Conventional Commits（`feat(scope): subject`）
- スコープ外の作業が必要になったら実装を止め、新しい Issue を `/pr-plan` で作成する
```

## Step 7: .claude/settings.json にプロジェクト固有 hook を提案

lint・型チェックのコマンドをユーザーに確認し、`.claude/settings.json` を生成する。

ユーザーへの確認:

> プロジェクトの lint/型チェックコマンドを教えてください。
> 例: `./gradlew lint`（Android）、`npm run lint`（Node）、`python -m ruff check .`（Python）
> 不要な場合はスキップします。

入力があれば `.claude/settings.json` を生成:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "<lint-command> 2>&1 | head -20 || true",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Step 8: セットアップ完了の報告

```
セットアップ完了:

✓ .github/PULL_REQUEST_TEMPLATE.md
✓ .github/ISSUE_TEMPLATE/plan.md
✓ CLAUDE.md（ワークフローセクション追記）
[✓ .claude/settings.json（lint hook）]

使い方:
  /pr-plan          — 実装前に Issue を作成
  /pr-develop #<N>  — 開発セッション開始
  /commit           — 意図単位でコミット
  /pr-create        — PR を作成
  /pr-review #<N>   — PR をレビュー
```

作成したファイルを git に追加するか確認する:

```bash
git add .github/PULL_REQUEST_TEMPLATE.md \
        .github/ISSUE_TEMPLATE/plan.md \
        CLAUDE.md \
        .claude/settings.json 2>/dev/null || true
```
