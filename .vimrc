" 基本的な Vim の設定(必ず最初に読み込む)
if filereadable(expand('~/.vim/.vimrc.ex'))
  source ~/.vim/.vimrc.ex
endif

" vimdiff の差分の背景色を変更する
hi DiffAdd    ctermfg=black ctermbg=2
hi DiffChange ctermfg=black ctermbg=3
hi DiffDelete ctermfg=black ctermbg=6
hi DiffText   ctermfg=black ctermbg=7
