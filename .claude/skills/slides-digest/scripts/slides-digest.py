#!/usr/bin/env python3
"""登壇資料 PDF を headless claude に読ませて、メッセージ単位の記事を書かせる。

サブプロセスに投げるのは、資料と記事本文を呼び出し側のコンテキストに載せないため。
ただし**使用量の枠は同じアカウントで共有される**ので、サブプロセスにしても
使う量は減らない。減らせるのは読むページ数だけ。

そこで、テキストが取り出せる資料は pdftotext の結果を「目次」として渡し、
画像として読むのは裏づけスライドだけに絞る。129 ページの資料で全ページを
画像で読ませて枠を使い切った実測があり、その対策。

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
# 実測: 完全画像 PDF は 0、図中文字が画像の資料でも 137、通常は 250〜900。
TEXT_YIELD_THRESHOLD = 60


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
