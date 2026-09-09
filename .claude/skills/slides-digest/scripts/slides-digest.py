#!/usr/bin/env python3
"""登壇資料 PDF を headless claude に読ませて、メッセージ単位の記事を書かせる。

サブプロセスに投げるのは、資料と記事本文を呼び出し側のコンテキストに載せないため。
ただし**使用量の枠は同じアカウントで共有される**ので、サブプロセスにしても
使う量は減らない。減らせるのは読むページ数だけ。

減らし方は2つある。テキストが取り出せる資料は pdftotext の結果を「目次」として渡し、
画像として読むのは裏づけスライドだけに絞る（129 ページの資料で全ページを画像で読ませて
枠を使い切った実測があり、その対策）。もう1つは1ページあたりの単価で、画像のトークン数は
画素数に比例するため、横幅を固定して描画すると全ページ読んでも安くなる。

    python3 slides-digest.py --pdf tmp/slides/x.pdf --slides-id <32hex> \\
        --pages 129 --slides-url <url> --out tmp/digest/x.md

複数本を同時に走らせると枠を食い合うので、長い資料は 1 本ずつ流す。
"""
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent / "assets"

# 1ページあたりこれだけ文字が取れれば、テキストを目次として使える。
# 実測 20 本（文字数。バイト数ではない）の分布は 0 が 2 本、次が 47、
# あとは 78〜321 に固まる。0 と 47 の間で切れているのでその中間に置く。
# 目的は内容の再現ではなく「どのページに何があるか」の把握なので、
# スライド見出しが拾える程度で足りる。
TEXT_YIELD_THRESHOLD = 30


def claude_bin():
    """headless claude の実体。PATH に無い環境（launchd 等）向けにフォールバックする。"""
    found = shutil.which("claude")
    if found:
        return found
    fallback = Path.home() / ".local" / "bin" / "claude"
    if fallback.exists():
        return str(fallback)
    sys.exit("claude が見つからない")


def extract_text(pdf, dest):
    """pdftotext -layout で本文を抜く。取れた量（1ページあたり文字数）を返す。"""
    try:
        subprocess.run(
            ["pdftotext", "-layout", str(pdf), str(dest)],
            capture_output=True, timeout=120, check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return 0
    if not dest.exists():
        return 0
    return len("".join(dest.read_text(errors="ignore").split()))


def render_pages(pdf, dest, width):
    """ページを横幅固定の JPEG にする。画像のトークン数は画素数にほぼ比例し、
    Read に PDF を直接渡すと長辺 1568px まで描画されて 1ページ 1,840 トークン前後になる。
    横 960px なら 16:9 で 691 トークンで、読めるかは実機で確認済み（コード中心のスライドも可）。
    生成できなければ None を返し、呼び出し側は PDF を直接読む経路に落ちる。"""
    dest.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(
            ["pdftoppm", "-jpeg", "-scale-to-x", str(width), "-scale-to-y", "-1",
             str(pdf), str(dest / "p")],
            capture_output=True, timeout=600, check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None
    # pdftoppm のゼロ埋め桁数はページ数で変わるので 3 桁に揃える
    files = sorted(dest.glob("p-*.jpg"))
    for f in files:
        n = f.stem.split("-")[-1]
        if len(n) != 3:
            f.rename(dest / f"p-{int(n):03d}.jpg")
    return dest if files else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", required=True)
    ap.add_argument("--slides-id", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--pages", type=int, required=True)
    ap.add_argument("--title", default="")
    ap.add_argument("--slides-url", default="", help="資料の公開 URL。記事の冒頭リンクに使う")
    ap.add_argument(
        "--max-visual-pages",
        type=int,
        default=30,
        help="画像として読んでよいページ数の上限。使用量はここにほぼ比例する",
    )
    ap.add_argument(
        "--image-width",
        type=int,
        default=960,
        help="ページ画像の横幅ピクセル。トークン数はこれの2乗にほぼ比例する",
    )
    ap.add_argument("--model", help="サブプロセスのモデル（省略時は既定）")
    ap.add_argument(
        "--context",
        help="補助資料のパス（実況の引用元・イベント概要など）。中身は claude が読む",
    )
    ap.add_argument(
        "--extra-sections",
        default="",
        help="出力に足したい節の指示（例: 会場の反応を引用元からそのまま貼る）",
    )
    ap.add_argument("--force", action="store_true", help="出力が既にあっても上書きする")
    args = ap.parse_args()

    out = Path(args.out)
    if out.exists() and out.stat().st_size > 0 and not args.force:
        print("SKIP " + args.out)
        return
    out.parent.mkdir(parents=True, exist_ok=True)

    txt = out.with_suffix(".txt")
    chars = extract_text(args.pdf, txt)
    per_page = chars // max(args.pages, 1)
    text_first = per_page >= TEXT_YIELD_THRESHOLD

    plan_file = "reading-plan-text-first.md" if text_first else "reading-plan-visual.md"
    plan = (ASSETS / plan_file).read_text()
    budget = min(args.max_visual_pages, args.pages)
    print(
        f"抽出 {per_page} 字/ページ → "
        f"{'テキスト先読み' if text_first else '全ページ画像読み'}"
        f"（画像で読む上限 {budget} ページ / 全 {args.pages}）"
    )

    img_dir = render_pages(Path(args.pdf), out.parent / f"{out.stem}-pages", args.image_width)
    if img_dir:
        n = len(list(img_dir.glob("p-*.jpg")))
        print(f"ページ画像 {n} 枚を横 {args.image_width}px で生成: {img_dir}")
        read_how = (
            f"`{img_dir}/p-<3桁ゼロ埋めのページ番号>.jpg` を Read する"
            "（例: 12 ページ目は `p-012.jpg`）。複数ページ見るときは Read を1ターンで並べて呼ぶ"
        )
    else:
        print("pdftoppm が使えないので PDF を直接読ませる（1ページあたり約2.7倍かかる）")
        read_how = "Read ツールの `pages` 引数で 20 ページ以内に区切って PDF を読む"

    context_block = (
        f"- 補助資料（引用元・文脈）: {args.context}" if args.context else ""
    )
    prompt = (ASSETS / "digest-prompt.md").read_text()
    prompt = prompt.replace("{{READING_PLAN}}", plan)
    for k, v in {
        "{{PDF}}": args.pdf,
        "{{TXT}}": str(txt),
        "{{SLIDES_ID}}": args.slides_id,
        "{{OUT}}": args.out,
        "{{PAGES}}": str(args.pages),
        "{{MAX_VISUAL}}": str(budget),
        "{{READ_INSTRUCTION}}": read_how,
        "{{TITLE}}": args.title or "(PDF から読み取る)",
        "{{SLIDES_URL}}": args.slides_url or "(不明。資料リンクの行は省く)",
        "{{CONTEXT_BLOCK}}": context_block,
        "{{EXTRA_SECTIONS}}": args.extra_sections,
    }.items():
        prompt = prompt.replace(k, v)

    # Keychain 認証のため HOME/USER/LOGNAME を明示する（launchd 経由でも動くように）
    env = dict(os.environ)
    env.setdefault("HOME", str(Path.home()))
    env.setdefault("USER", Path.home().name)
    env.setdefault("LOGNAME", Path.home().name)
    # 使い捨て実行なので 1 時間 TTL は要らない。書き込み単価が 1.6 倍高いだけで
    # 保つ先がない（実測: この経路の実行は 3〜4 分、リクエスト間隔は 1 分未満）。
    env["CLAUDE_CODE_PROMPT_CACHE_TTL"] = "5m"

    cmd = [claude_bin(), "-p", prompt, "--permission-mode", "auto"]
    if args.model:
        cmd += ["--model", args.model]

    log = out.with_suffix(".log")
    with open(log, "w") as lf:
        subprocess.run(cmd, stdout=lf, stderr=subprocess.STDOUT, env=env)

    if out.exists() and out.stat().st_size > 0:
        print(f"OK   {args.out} ({out.stat().st_size}B)")
        return

    # サブプロセスは書かずに「できた」と報告することがあるので、
    # 完了判定はファイルの実在で行う。枠切れもここに出る。
    tail = log.read_text(errors="ignore").strip()[-300:] if log.exists() else ""
    print(f"FAIL {args.out}\n     {tail or 'ログが空。サブプロセスが起動していない可能性'}")
    sys.exit(1)


if __name__ == "__main__":
    main()
