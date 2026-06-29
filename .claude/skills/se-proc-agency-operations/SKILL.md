---
name: se-proc-agency-operations
description: 作成手順「agency-operations」（self-evolving-agent から自動同期）: 並列 agent を agency で安全に運用する手順(agency 運用知見)
---

<!-- auto-generated from self-evolving-agent/agent-config/procedures/agency-operations @ genome 1.28.0, synced 2026-06-29T00:07:39.323Z. Do NOT hand-edit; re-sync overwrites. -->

## 並列 agent を agency で安全に運用する手順(agency 運用知見)

**用途:** agency(claude-iterm2-agency)で複数の agent pane を並列に走らせて作業を回すとき。worktree 隔離・端末表示・pane ライフサイクル・focus 管理に起因する事故を避けるための playbook。

---

### 並列運用の代表的な落とし穴と回避策（運用設計の土台）

複数 agent を同時に走らせると、単体運用では起きない 4 種の事故が構造的に発生する。下記は claude-iterm2-agency の実運用で繰り返し効いた回避策を一般化したもので、以降の番号付き項目(#1〜)はこの 4 軸を具体運用に落としたもの。**新しく並列運用を始めるチームには、まずこの 4 軸を押さえさせる。**

| 落とし穴 | なぜ起きるか | 回避策(実行可能な具体策) |
| --- | --- | --- |
| **A. 同一ファイル/ブランチへの同時書き込み競合** | 2 つの agent が同じ作業ツリーを共有すると、互いの未コミット変更を上書き・破壊し、片方の差分が消える。同一ブランチへの並行 push も非 fast-forward で衝突する。 | **agent ごとに git worktree を分離**(各 worktree は main のクリーンチェックアウト＝物理的に別ディレクトリ)。**担当範囲をファイル/モジュール単位で重ならないよう分割**して割り当てる(例: agent1=`core-rx`、agent2=`features-x`)。**ブランチも 1 agent 1 ブランチ**にし、共有ブランチへの同時 push をしない。 |
| **B. busy な agent への指示取りこぼし** | agent が生成中(busy)のときにキー入力を流し込むと、入力途中のプロンプトに混入したり丸ごと欠落する。「送ったのに動いていない」が起きる。 | **pane の状態を確認し idle のときだけ送る**(送信前に `node agency.ts busy <id|session>` で検知)。busy なら**キューに積んで idle 復帰後に流す**。重要指示は**「了解」等の確認応答(ack)を取る**まで届いた前提にしない。長い指示は 1 メッセージで送り、途中で割り込まない。 |
| **C. ウィンドウ/ペインの増殖と状態管理の煩雑化** | タスクごとに pane を作りっぱなしにすると窓が増殖し、どの pane が何用か分からなくなる。状態ファイルと実 pane がずれて誤操作・幽霊 pane を生む。 | **役割で pane を固定し命名規約を敷く**(左=dashboard / 中=human / 右=agent、session_id を一意命名)。**用済み pane は閉じるだけで監視ループが自動 prune**(tasks・状態ファイル・window.json から自動除去)。**既存 pane を再利用**し、毎回 spawn/close で churn させない。 |
| **D. 成果のレビュー/統合のボトルネック** | 複数 agent の成果が同時に上がってくると、レビュー/統合が 1 人に集中し、無秩序に取り込むと衝突・品質劣化を招く。 | **取り込みは 1 件ずつゲートを通す**(eval/CI/レビューを通った成果だけ main へ)。**統合担当(integrator)を生成担当から分離**し、生成 agent は成果を出すだけ・取り込み判断はしない。**マージ順を直列化**して並行マージの衝突を避ける。 |

---

### 1. プロンプトは self-contained に書く
agency の各 agent worktree は **main のクリーンチェックアウト**であり、未追跡ファイル・`.gitignore` 対象ファイルは入らない。

- 前提・rubric・対象資料は**プロンプト本文に埋め込む**。「リポ内のあのファイルを見て」式のファイル依存にしない。
- リポ外のグローバルファイルを触らせるときは**絶対パス**で渡す(例: `/Users/andy/Documents/.../HANDOVER.md`)。
- **なぜ:** worktree に存在しないファイルを参照させると agent はそれを読めず、暗黙の前提が欠落したまま作業して成果物がずれる。実際に作業用の `tasks.json` / `tasks.eval.json` はリポ直下の未追跡ファイルで、worktree には入らない。

### 2. 出力は ASCII + emoji のみ
丸数字・全角記号・East Asian Ambiguous 幅の文字は、端末/フォントの幅解釈に依存して桁ズレや文字重なりを起こす。

- 番号は `1.`、区切りは `- = |`、状態表現は emoji(✅ ⚠️ ❌ 🔴 等)を使う。
- **なぜ:** dashboard や pane 内のテキストはユーザーの端末で表示される。iTerm2 の "ambiguous double width" 設定はローカルの保険に過ぎず、相手の環境では崩れる。送り手側で曖昧幅文字を出さないのが唯一の確実な対策。

### 3. pane の後始末は prune に任せ、agency を再起動しない
agent pane は**閉じれば dashboard 監視ループが自動 prune** する(tasks / 状態ファイル / window.json から自動除去)。

- 用済みの pane は `node agency.ts close <id|session>` で閉じるだけでよい。**毎回 agency を再起動しない**。
- 再起動が必要なときも `.state/window.json` 経由の**ウィンドウ引き継ぎ(adopt)** で行い、既存 pane を開閉(churn)させない。プロセスが死んでも窓が生きていれば同一 window へ churn なしで再接続できる(実証済み: window_id 同一・窓数は増えない)。
- **なぜ:** 不要な再起動・pane churn は表示を乱し、状態ファイルと実 pane の不整合を生む。特に直前に追加した agent を閉じたまま再 spawn すると、死んだ session を anchor(`prev_sess`)にして `SESSION_NOT_FOUND` で失敗しうる。prune 時に生存中の最後の agent へ積み先を張り直す実装でこれを回避している。

### 4. 副作用後は文脈(focus)を元の pane へ戻す
新しい agent pane を生成すると iTerm2 が focus をそちらへ奪う。

- pane 生成・UI フォーカスを奪う操作の直後は、**focus を human pane(無ければ left)へ明示的に戻す**(agent spawn の直後に daemon が human pane を focus し直す)。
- 起動時の一括 spawn・inbox 動的追加の両経路ともこの戻し処理を通す。
- **なぜ:** focus を戻さないと、人間が次に打鍵した内容が意図しない agent pane に入る。対話の連続性が壊れ、誤操作の原因になる。

### 5. 復旧用の状態をこまめに保存する
外部復旧に使う状態ファイル(`.state/window.json` など)は**頻繁に更新**し、クラッシュ時の取りこぼし窓を最小化する。

- pane 追加・削除・引き継ぎのたびに window.json を書き直し、実態と一致させる。
- **なぜ:** プロセスが死んでも window.json が最新なら既存窓・pane へ churn なしで再接続できる。更新が遅れると、その間に起きた変更が復旧時に失われる。

### 6. human pane と agent pane の役割を分離する
- **human pane(中央)= 人間との対話。agent pane(右)= 実装・作業。**
- 人間への質問・確認は human pane、実コードや成果物の生成は agent pane に投げる。
- **なぜ:** 対話と実作業を同じ pane に混ぜると、長い作業ログで対話が流れて見失う。役割を固定すると、どこを見れば何が分かるかが安定する(左=dashboard / 中=human / 右=agent)。

---

**取り込み経緯:** 本 procedure は agency の前身 claude-pane-orch の運用(2026-06-05 セッション)で得た転用可能な運用教訓を、Phase 1「教訓ブリッジ」として KNOWLEDGE チャネル相当で self-evolving-agent に取り込んだもの。出典は同(前身)の `HANDOVER.md`(失敗モード・focus 維持・自動 prune・prev_sess 張り直しの各節)。eval スイート(文書作成系)では測れない運用ノウハウのため、eval / evolve ループは起動せず、人間レビュー後の手動 merge を前提とする。

---

## agency agent が実リポに PR を出す手順(<repo> PR 分割作業の知見)

**用途:** agency の agent pane が実リポ(例 <repo>)で元 PR を分割し、cherry-pick → 専用 worktree → draft PR → レビュー/CI 対応 → 人間承認後 merge まで回すとき。下記は 2026-06-10 の PR-1(LifecycleDisposable を core-rx へ移動)セッションで得た教訓。失敗も含む。

### 7. push 済みブランチへの修正は「追加コミット」で。force push しない
CI 指摘(spotless 等)やレビュー対応でコミットを直したくなっても、`git commit --amend` + `git push --force-with-lease` は**禁止**。

- 修正は必ず**新規コミットを積んで通常 push**する。自分専用の draft ブランチでも同じ。
- **なぜ:** force push は履歴を書き換え、レビュー進行・他者のローカル ref・レビューコメントのアンカーを壊す。チーム規約違反。実際にこのセッションで amend+force-push をして明確に叱られた。「自分のブランチだから安全」という判断が誤り。

### 8. PR を出しても worktree はすぐ畳まない
push / PR 作成の直後に worktree を撤去しない。**merge 完了後・セッションクローズ時**に撤去する。

- PR 後は CI 指摘対応・レビュー修正・追加コミットが続くのが常態。すぐ畳むと都度 `git worktree add` で全ファイル(数千)を再チェックアウトする無駄が出る。
- 共有 worktree(検証用など)は元から触らない。撤去時の未追跡ファイル(`tmp/` 等)は `--force` が要る。
- **なぜ:** PR 作成は作業の終点ではなく、レビュー往復の起点。最初の指示に「push 後撤去可」とあっても、実運用ではユーザーは merge までの残置を期待する。

### 9. ホスト固有の壊れた CLI は REST API で迂回する
<repo> では `gh pr edit`(assignee / reviewer / body の編集)が **Projects classic 廃止由来の `projectCards` GraphQL エラー**で失敗する。

- assignee: `gh api -X POST /repos/<owner>/<repo>/issues/<n>/assignees -f "assignees[]=<user>"`
- team reviewer: `gh api -X POST /repos/<owner>/<repo>/pulls/<n>/requested_reviewers -f "team_reviewers[]=<team>"`
- 本文更新: `gh api -X PATCH /repos/<owner>/<repo>/pulls/<n> -F body=@<file>`
- **なぜ:** 高レベル CLI が環境固有の理由で壊れていても、REST の素のエンドポイントは通ることが多い。同じ操作を別ツールで達成する手を即座に持つ。`merge` は別 mutation のため `gh pr merge` は通る。

### 10. 取り返しのつかない外向き操作は実行前に確認する
merge・共有チャンネルへの投稿・リモートブランチ削除など、外部に波及し巻き戻しにくい操作は、明示の指示があっても**前提が変わっていないか一拍置いて確認**する。

- 例: 「merge して」と言われても、実機ビルド(Bitrise 等の per-PR CI)が pending なら「待つ/今すぐ」を選択肢で確認してから実行した(ユーザーが「今すぐ」を選択)。これは妥当だった。
- 逆に worktree 撤去のついでにリモートブランチ削除まで踏み込もうとして権限ガードに弾かれた。**依頼された範囲(worktree 片付け)を超える破壊的操作を勝手に足さない**。
- **なぜ:** 指示の「merge」と現在の安全状態(CI 未完)は別問題。範囲外の破壊操作は、良かれと思っても越権になる。

### 11. チーム連携の宛先・形式は推測せず、実例で裏取りする
Slack #team-android のレビュー依頼で、似た投稿を真似て `ms-android` サブチームをメンションしたが、正しくは `@android-engineers`(`<!subteam^S0LPR2G8H>`)だった。

- 宛先(サブチーム ID・チャンネル)や定型文は、チャンネルの**直近の同種投稿を読んで確認**してから送る。複数の似たグループがあるときは特に。
- **なぜ:** 「レビュー依頼っぽい投稿」を 1 件だけ真似ると、用途違いの狭いグループを誤って叩く。送信は外向きで、間違えるとユーザーが手で直す手間を生む。

**取り込み経緯(第2ブロック):** 2026-06-10 の <repo> PR-1 分割セッション(agency agent 視点)で得た転用可能な運用教訓。force push 叱責・projectCards 迂回・Slack 宛先誤り等の実体験が出典。文書作成系 eval では測れないため eval/evolve ループは起動せず、`ingest`(eval ゲート)→ 人間 merge を前提とする。

---

## agency agent の移設 PR — 検証と cherry-pick の落とし穴(PR-3 知見)

**用途:** agency の agent pane が実リポでクラス/レイアウトを別モジュールへ移設する PR を出すとき。2026-06-10 の PR-3(CalendarPurposeSelectFragment を :features-calendar-purpose-select へ移設)で、ローカル検証は緑なのに CI が落ちた。第2ブロック(#7-#11)を補完する。

### 12. 移設は「クラス名」だけでなく「移動したリソース名」でも全呼出し元を grep する
クラス名 grep で呼出し元を洗っても、レイアウト内の **view id**(例 `next_button`)を参照するコードは見つからない。レイアウトを別モジュールへ移すと、その id は non-transitive R により**元モジュールの R から消え**、`R.id.xxx` を使うテストが `Unresolved reference` で壊れる。

- 移設時は「クラス名」に加え、**移動した R リソース名(id / layout / menu / string / drawable)**と**生成 databinding クラス名**でも全 repo grep する。
- アプリモジュールが複数ある場合(例 `:app` と `:app-<product>`)、片方だけ見て他方のテストを見落とさない。壊れた参照は別モジュールの test 配下にいることがある。
- 直し方: 壊れたテストの R import を移設先モジュールの R に向ける(依存が既に通っていれば追加 build.gradle 不要)。
- **なぜ:** 移設の破壊は「参照の名前」が多様(クラス名・リソース id・レイアウト名・databinding 名)で、1 種類の grep では取りこぼす。compile が通っても run 時/別モジュールで露見する。

### 13. 「ビルド成功」を鵜呑みにせず、キャッシュ無効化で裏取りする
Gradle のビルドキャッシュヒットで `compileDebugKotlin` が exit 0 を返し、実際のコンパイル破綻を隠していた。`--rerun-tasks` で実コンパイルすると FAILED。

- 「緑だから OK」と報告する前に、**重要な検証はクリーン再実行(`--rerun-tasks` 等)で裏取り**する。特に直前に状態を変えた直後の最初の成功は疑う。
- ローカルで再現できない領域(secrets 必須のアプリモジュール等。例 `:app-<product>` は `secrets.properties` 必須でローカル config 不可)は**最初から「CI に委ねる」と宣言**し、緑を断定しない。
- **なぜ:** キャッシュは入力ハッシュ一致で過去の成功を返すため、未検証の変更でも見かけ上 success になる。偽の安心は「直したつもり」を生む。

### 14. cherry-pick で「移動」を再現するときは、指定コミットの後ろの修正コミットまで確認する
指定の2コミットだけ pick したら、namespace と databinding パッケージが不一致の**壊れた中間状態**を再現した(上流はその後の3つ目のコミットで修正済みだった)。

- 多段リファクタの一部を pick するときは、対象コミットの**後続に修正/follow-up コミットがないか** `git log <file>` で確認し、最終的に整合する状態まで取り込む。
- 移設先が規約と食い違う中間生成物(例: 中間レイヤ由来の `component_` プレフィックス、不要な明示 namespace)を**そのまま運ばず**、移設先モジュールの規約に揃える(同種モジュールの実例で確認)。
- **なぜ:** 中間コミットは一時的に壊れていることがあり、pick 範囲が修正前で止まると壊れた状態を本流に持ち込む。

### 15. 「レビュー依頼」の既定は GitHub team の reviewer 追加。Slack は明示時のみ
PR-1 の #11 を更新。「android team にレビュー依頼」と言われたら、既定は **GitHub team を PR の reviewer に追加**すること(REST `POST /pulls/<n>/requested_reviewers -f "team_reviewers[]=android"`)。

- **Slack へのレビュー依頼投稿は、明示的に「Slack で」と言われた時だけ**行う。勝手に #team-android へメンションしない(PR-3 で Slack に投稿したが、望まれていたのは GitHub team reviewer だった)。
- **なぜ:** 依頼の宛先は「どの面で追跡したいか」の運用判断。既定面(GitHub)を外して別チャネル(Slack)に出すと、二重依頼・追跡漏れになる。送信は外向きで巻き戻しにくい。

**取り込み経緯(第3ブロック):** 2026-06-10 の <repo> PR-3 分割セッション(agency agent 視点)。ローカル緑なのに CI 赤(別モジュール `:app-<product>` のテストが移動した layout の id を参照)・キャッシュヒットによる偽の compile 成功・cherry-pick が壊れた中間状態を再現・レビュー依頼先の誤り(Slack→GitHub team)が出典。文書作成系 eval では測れないため `ingest`(eval ゲート)→ 人間 merge を前提とする。
