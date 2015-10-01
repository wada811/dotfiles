" :read $VIMRUNTIME/vimrc_example.vim

" When started as "evim", evim.vim will already have done these settings.
" "evim" コマンドで開始した場合は設定済みとして読み込まずに終了する。
if v:progname =~? "evim"
  finish
endif

" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
" Vi の設定よりも Vim の設定を使用する。
" これは副作用として他のオプションを変更するため最初に記述する。
set nocompatible

" allow backspacing over everything in insert mode
" 挿入モードの全てにおいてバックスペースを許可する
set backspace=indent,eol,start

set nobackup      " do not keep a backup file
                  " バックアップファイルを作らない
set history=50    " keep 50 lines of command line history
                  " コマンドライン履歴を50行保持する
set ruler         " show the cursor position all the time
                  " 常にカーソルのポジションを表示する
set showcmd       " display incomplete commands
                  " 不完全なコマンドを表示する
set incsearch     " do incremental searching
                  " インクリメンタルサーチをする

" Don't use Ex mode, use Q for formatting
" フォーマットに Q を使用する Ex モードを使用しない。
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
" 挿入モードでの CTRL-U で たくさん削除する。
" 改行を入れた後の CTRL-U で元に戻せるようにするために、
" まず CTRL-G u を使ってアンドゥを中断してください。
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
" 多くのターミナルエミュレータでマウスは良い働きをするので有効化する。
if has('mouse')
  set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
" ターミナルに色がある場合、シンタックスハイライトを ON に変更する。
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

" Only do this part when compiled with support for autocommands.
" autocommands のサポートが有効な場合のみこの部分を実行する
if has("autocmd")

  " Enable file type detection.
  " ファイルタイプ検出を有効にする。
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  " デフォルトのファイルタイプ設定を使用する。
  " また、言語ごとのインデントを自動実行するためのインデントファイルを読み込む。
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  " 削除しやすいように autocmd グループにこれらを記述する。
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  " すべてのテキストファイルについてテキスト幅は 78 文字にセットする。
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " ファイルの編集中に常に最後のカーソルポジションにファンプできるようにする。
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END

else

  set autoindent    " always set autoindenting on
                    " 常にオートインデントを ON にする。

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" 変更前と変更後の diff を確認する便利コマンド
" Only define it when not defined already.
" すでに定義されていない場合のみ定義する。
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
    \ | wincmd p | diffthis
endif
