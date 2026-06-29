---
name: se-proc-date-verification
description: "作成手順「date-verification」（self-evolving-agent から自動同期）: 日付・締切検証手順（date-verification）"
---

<!-- auto-generated from self-evolving-agent/agent-config/procedures/date-verification @ genome 1.28.0, synced 2026-06-29T00:07:39.323Z. Do NOT hand-edit; re-sync overwrites. -->

## 日付・締切検証手順（date-verification）

**用途:** 成果物（会議要約・ADR・worklog・kaizen レポート・手順書・提案文書）を出力する直前に、日付・曜日・締切表現を機械的に検証するとき。他のすべての procedure の「出力前チェック」に差し込む必須ゲート。

> **なぜ教訓追加でなく procedure 化か**
>
> Lesson C・O・P は 3 世代連続で「何を検証すべきか」を正しく記述してきた。にもかかわらず再発が止まらない根本原因は、**「いつ・どうやって検証するか」の実行ステップが既存 procedure に組み込まれていないこと**。
> 教訓をまた追加しても「知っているが実行されない」状態が続く。Lesson が宣言的ルールなら、Procedure は強制的な実行ステップ。この手順を各 procedure の「出力前チェック」に挿入することで、「知識があっても手を抜く」という認知バイアスを構造で封じる。

> **この procedure で次回以降どう良くなるか**
>
> 日付を含む成果物を出力するたびにこの手順を走らせることで、「会議要約に土曜の締切が残る」「例示の曜日が間違っている」「before Thursday を木曜当日にしてしまう」といったクラスの誤りが出力前に機械的にブロックされる。教訓を読み返す必要なく、コマンドを実行するだけで検証が完了する。

---

### 適用タイミング

**成果物に日付・曜日・締切・期限のいずれかが 1 件でもある場合、出力前に必ずこの手順を実行する。**

他の procedure（meeting-summary / worklog-reflection / kaizen-report / tech-decision-adr / sprint-review-document / 1on1-prep 等）の「出力前チェック」では、以下の文言を追加して本手順へのゲートを明示する:

```
- [ ] date-verification 手順を実行したか（日付・曜日・締切表現が 1 件でもある場合は必須）
```

---

### Step 1：成果物中の全日付・曜日・締切表現を抽出する

成果物のドラフトを最初から最後まで走査し、以下のパターンをすべてリストアップする。**見落としを防ぐため、目視に加えて grep を使う。**

抽出対象パターン:

| パターン | 例 |
|---|---|
| 絶対日付（YYYY-MM-DD） | `2026-07-01` |
| 曜日表記（単独または日付付き） | `火曜日`、`Wed`、`木 2026-06-26` |
| 相対締切表現 | `来週月曜`、`next Friday`、`今週中` |
| before / by / until 系 | `by Thursday`、`before Mon`、`木曜前に`、`〜までに` |
| 例示に使われた日付 | 手順書・テンプレート内の「例: 2026-06-25（水）」等 |

```bash
# ドラフトファイルから日付・曜日パターンを一括検索する例
grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}|月|火|水|木|金|土|日|Mon|Tue|Wed|Thu|Fri|Sat|Sun|before|until|by [A-Z]' draft.md
```

---

### Step 2：python3 で各絶対日・曜日を検証する（暗算禁止）

抽出した日付・曜日ペアをすべて以下のコマンドで確認する。**1 件でも暗算で済ませない。**

```bash
# 特定日付の曜日を確認
python3 -c "from datetime import date; d=date(YYYY,M,D); print(d, d.strftime('%A'))"

# 今週の特定曜日（例: 木曜）の絶対日付を取得
python3 -c "
from datetime import date, timedelta
today = date.today()
target_weekday = 3  # 0=Mon 1=Tue 2=Wed 3=Thu 4=Fri 5=Sat 6=Sun
days_ahead = (target_weekday - today.weekday()) % 7
d = today + timedelta(days=days_ahead)
print(d, d.strftime('%A'))
"

# 締切が平日（月〜金）か確認
python3 -c "
from datetime import date
d = date(YYYY,M,D)
weekday = d.weekday()  # 0=Mon ... 4=Fri 5=Sat 6=Sun
print(d, d.strftime('%A'), 'WEEKDAY' if weekday < 5 else 'WEEKEND - MOVE IT')
"
```

検証結果が土日であれば、文脈に応じて「直前の金曜」または「翌週の月曜」に移動し、インライン注記を付ける:

```
（金曜 2026-07-03 中 — 土曜 7/4 からの繰り上げ）
```

---

### Step 3：before / by / 〜までに / 〜前に の解釈を python3 で確定し、インライン明示する

「before X」「X 前に」は X 当日でなく **X の前日が期限**になりうる。ただし機械的に −1 日と断定すると新たな誤りを生む。以下の手順で「解釈を明示した上で渡す」。

```bash
# X の絶対日付を確定する
python3 -c "
from datetime import date, timedelta
# X = 例: 次の木曜
today = date.today()
target_weekday = 3  # 木曜
days_ahead = (target_weekday - today.weekday()) % 7
x = today + timedelta(days=days_ahead)
day_before = x - timedelta(days=1)
print(f'X ({x.strftime(\"%A\")}): {x}')
print(f'X-1 ({day_before.strftime(\"%A\")}): {day_before}')
"
```

成果物への記載:

```
（例）「before Thursday」→ 木 2026-07-02 の前日＝水 2026-07-01 中と解釈。意図が木曜当日なら指摘を。
（例）「by Thursday」→ 木 2026-07-02 中と解釈。意図が前日なら指摘を。
```

**解釈を文書にインライン明示することで、読み手が即訂正できる。断定して埋め込まない。**

---

### Step 4：例示の日付・曜日も Step 2 と同じコマンドで検証する

手順書・テンプレート・提案文書に「例: 金曜 2026-06-05 中」のような具体例を書く場合、本文の日付と同じ検証を必ず実施する。

```bash
# 例示に使う日付ペアを検証
python3 -c "from datetime import date; d=date(2026,6,5); print(d, d.strftime('%A'))"
# → 2026-06-05 Friday  ✅
```

- 具体日付を使う必然性がない場合は `[曜日 YYYY-MM-DD]` のような抽象プレースホルダで書く（誤りようのない形にする）。
- 「本文は正しいが例が間違っている」は、読み手が例を真似るため本文の誤りと同等以上に有害。

---

### チェックリスト（出力直前に実行）

```
- [ ] Step 1: 成果物から全日付・曜日・締切表現を抽出した（grep を使った）
- [ ] Step 2: 各絶対日・曜日ペアを python3 で確認した（暗算なし）
- [ ] Step 2: 締切日が土日に当たる場合、平日へ移動してインライン注記を付けた
- [ ] Step 3: before/by/〜前に 表現について python3 で X の絶対日を確定し、解釈をインライン明示した（断定しない）
- [ ] Step 4: 例示に使った日付・曜日ペアも python3 で検証した
```

---

**取り込み経緯:** Lesson C・O・P が 3 世代にわたり日付規律を宣言的に記述してきたにもかかわらず再発が止まらないことを受け、2026-06-26 に「宣言ルールでなく強制実行ステップ」として procedure 化。既存 Lesson の散文を増やさず、他の procedure の出力前チェックに差し込む必須ゲートとして設計。
