---
name: mockk-testing
description: |
  Kotlin の MockK ライブラリ（every/verify/spyk/slot 等）の各機能が何を検証しているかと、
  正しい記法のリファレンス。
  Use when you are about to write or review Kotlin test code that uses MockK
  (every, verify, coEvery, coVerify, spyk, mockk, slot/capture), or when you need to
  reason about what a mock/stub/spy actually verifies.
  Triggers on: "MockK", "every", "verify", "mockk", "spyk", "モックのテスト".
  Do NOT use for general test design/coverage review (use pr-review's Layer 1) or for
  non-Kotlin mocking libraries.
---

# mockk-testing — MockK の機能と記法

## 1. MockK の各機能の役割

| MockK 機能 | 位置づけ | 実際の役割 |
|---|---|---|
| `mockk()`（型引数で対象クラスを指定、デフォルト strict） | 空のモック | スタブしていない呼び出しは例外になる |
| `mockk(relaxed = true)` | Dummy 相当 | スタブなしでも型のデフォルト値/空値を自動で返す。何も検証しない |
| `every { mock.foo() } returns x` | Stub | 呼ばれたら `x` を返すと決め打つだけで、`foo()` の本来の実装は一切実行されない |
| `spyk(real)` | Spy | 本物の実装を実行しつつ呼び出しも記録するので `verify` できる |
| `verify { mock.foo(args) }` | Mock（振る舞い検証） | `mock` の**呼び出し元**が期待通りの引数で呼んだかを検証する。`foo()` 自身の実装の正しさは検証しない |
| `slot()`/`capture()` | — | 呼び出し時に渡された実引数そのものを取り出して後で検証する |

- MockK は1つのモックオブジェクトで `every`（スタブ）と `verify`（振る舞い検証）の両方を扱える
- `every` でスタブした関数の内部ロジックは実行されない。その関数自体の正しさは別のテスト
  （本体のテスト、または `spyk`）で担保する
- `verify` が検証しているのは「呼び出し元の委譲が正しいか」であって「呼ばれた側の実装が正しいか」ではない
- `verify { mock.foo(expected) }` の `expected` は、テストコード側で**独立に評価されるただの
  Kotlin 式**であり、実行時に実装側の値を参照しに行くわけではない。実装コードと見た目上
  同じ式（同じ計算式・同じ書き方のリテラル）が書かれていても、実装の private 関数や
  共有定数を明示的に呼び出していない限り「実装を参照している」のではなく「テスト側で
  別々に書かれた値」であり、実装側の値だけが変われば正しく食い違って失敗する
- `any()` は「この引数は何でもよい」という意味であり「この引数はテストしていない」では
  ない。同じ呼び出しの他の引数は具体値で厳密に検証されている

## 2. 記法: MockK API リファレンス

### モック生成

- `mockk()` — 型引数で対象クラスのモックを作る（デフォルト strict）
- `mockk(relaxed = true)` — スタブしていない呼び出しでもデフォルト値を返す
- `spyk()` — 本物のインスタンスをラップし、呼んだ分だけ実装が実際に動く

```kotlin
val car = mockk<Car>()                  // strict: スタブしていない呼び出しは例外
val car = mockk<Car>(relaxed = true)    // relaxed: スタブなしでもデフォルト値を返す
val car = spyk(Car())                   // spy: 本物をラップ
```

### スタブ（状態）

- `every { ... } returns x` — 「この呼び出しがあったら `x` を返す」という決め打ち
- `answers { callOriginal() }` — 本物の実装をそのまま呼ぶ（`spyk` を使わず一部だけ本物を通したいときに使う）
- `any()`/`more()` 等 — 引数に渡せるマッチャー

```kotlin
every { car.drive(Direction.NORTH) } returns Outcome.OK
every { car.recordTelemetry(speed = more(50), direction = Direction.NORTH) } returns Outcome.RECORDED
every { adder.addOne(3) } answers { callOriginal() }   // 部分的に本物を呼ぶ
```

### 検証（振る舞い）

- `verify { ... }` — 「その呼び出しが実際にあったか」を確認する（回数指定なしは「少なくとも1回」）
- `verify(exactly = n)` / `verify(atLeast = n)` / `verify(atMost = n)` — 呼び出し回数を絞って確認する
- `verifyOrder { ... }` — 指定した呼び出しがその順番で起きたか（間に他の呼び出しがあってもよい）
- `verifySequence { ... }` — 指定した呼び出し**だけ**がその順番ちょうどに起きたか（より厳格）
- `confirmVerified(mock)` — スタブした呼び出しのうち verify し忘れているものがないか検出する
- `checkUnnecessaryStub(mock)` — 一度も呼ばれていない無駄なスタブがないか検出する

```kotlin
verify { car.drive(Direction.NORTH) }                     // 少なくとも1回呼ばれたか
verify(exactly = 4) { car.drive(Direction.NORTH) }         // ちょうど4回
verify(atLeast = 2) { car.drive(Direction.NORTH) }         // 2回以上
verify(atMost = 3) { car.drive(Direction.NORTH) }          // 3回以下
verifyOrder { car.start(); car.drive(Direction.NORTH) }    // この順で起きたか（間の呼び出しは許容）
verifySequence { car.start(); car.drive(Direction.NORTH) } // この呼び出しだけがこの順で起きたか
confirmVerified(car)        // verify し忘れているスタブがないか
checkUnnecessaryStub(car)   // 使われていないスタブがないか
```

### 引数のキャプチャ

- `slot()` — 呼び出し時に渡された実引数そのものを保存する箱を作る
- `capture(slot)` — マッチャーとして渡すと、呼ばれた瞬間の実引数を slot に保存する
- `slot.captured` — 保存された実引数を取り出す（引数の値そのものを別の検証に使いたいときに使う）

```kotlin
val speedSlot = slot<Double>()
every { car.recordTelemetry(speed = capture(speedSlot), any()) } answers { }
// speedSlot.captured で実引数を取り出せる
```

### suspend 関数

- `coEvery { ... } returns x` — `suspend fun` をスタブするときの `every` 相当
- `coVerify { ... }` — `suspend fun` を検証するときの `verify` 相当
  （コルーチンのスコープ内で評価する必要があるため専用の関数になっている）

```kotlin
coEvery { car.drive(Direction.NORTH) } returns Outcome.OK
coVerify { car.drive(Direction.NORTH) }
```

### static / object

- `mockkObject(obj)` — Kotlin の `object`（シングルトン）をモック化する
- `mockkStatic(::fn)` — トップレベル関数や Java の static メソッドをモック化する
- どちらも通常のインスタンスでなくグローバルな呼び出し先を差し替える点が異質なので注意
  （グローバル状態を書き換えるため、テスト後に `unmockkObject`/`unmockkStatic` で必ず後始末する）

```kotlin
mockkObject(ObjBeingMocked)
every { ObjBeingMocked.add(1, 2) } returns 55

mockkStatic(::buildCar)
every { buildCar() } returns testCar
```

## 参考

- [MockK 公式サイト](https://mockk.io/)
- 一般的なテストレビュー（存在確認・エッジケース等）: `pr-review` skill の Layer 1
