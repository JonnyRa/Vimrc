"clear out previous autocmds to stop them being duplicated when resourcing
"this file
"but put them in a group to stop others being tinkered with... unclear if this
"causes issues or not
augroup myCommands
autocmd!

colorscheme evening
"improve searching to ignore case when everything is lowercase
set ignorecase
set smartcase
""

"show what is being typed
set showcmd
"line numbers
set number

""""""""""""""
"sort out tabs
""""""""""""""
"switch on filetype detection and look at how stuff should be indented for each language
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert spaces instead of tab
set expandtab
""""""""""""""

"stop prompting to force when leaving an unsaved buffer, just make it hidden
set hidden

"sort out backspace so it goes backwards and can remove line breaks
set backspace=indent,eol,start

"stop lines being wrapped when screen is not wide enough
set nowrap
set textwidth=0 "stop line breaks being inserted when lines are too long
"stop comments being added on new line - through carriage (r)eturn in insert mode
"and when using (o) to add a newline in normal mode
autocmd FileType * setlocal formatoptions-=r formatoptions-=o

"stop sessions saving all random options
set sessionoptions-=options
command! SaveSession mksession! ~/.vim/sessions/pickup.vim

"when splitting default to more natural positioning
set splitbelow
set splitright

command! FormatJson %!python -m json.tool

"////
"automatically reload file when changes detected
set autoread "this doesn't work on it's own!

"https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
"on these events, any filename... and not in command mode then check files for changes
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if !bufexists("[Command Line]") | checktime | endif
" Notification after file change
autocmd FileChangedShellPost *
  \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

"make CursorHold happen quicker - every second rather than default 4 seconds
set updatetime=1000

"/////
"error stuff

let s:root = expand('<sfile>:p:h')
function! SourceLocal(relativePath)
  let fullPath = s:root . '/'. a:relativePath
  exec 'source ' . fullPath
endfunction

call SourceLocal ("errors.vim")

nnoremap <leader>re :ReadErrors<cr>

"////

set hlsearch "highlight stuff when searching
nohlsearch "but don't highlight previous search (if resourcing this file)

command! ClearSearchHighlight nohlsearch | echo

" Press Space to turn off highlighting and clear any message already
" displayed.
nnoremap <silent> <Space> :ClearSearchHighlight<CR>
command! HighlightCurrentWord let @/ = '\<'.expand("<cword>").'\>'|set hlsearch|echo
nnoremap <leader>* :HighlightCurrentWord<cr>
nnoremap <leader># :HighlightCurrentWord<cr>

nnoremap <leader>v :vertical resize<cr>
nmap <leader>V <leader>v :resize<cr>

"ttimeoutlen speeds up esc key presses!
set timeout timeoutlen=3000 ttimeoutlen=0

"///
"Status line stuff
"status line containing 50 character max filename, modified flag, readonly
"flag, file type, buffer number, line|character percentage through file
"
set statusline=%.50F%m%r\ %y\ buffer\ %n\ %l\|%c\ [%p%%]
"better colours
highlight StatusLine ctermfg=Blue ctermbg=Yellow
"always show the statusline
set laststatus=2
"///

"///fast-tag stuff
"calls a shell script to dump in all the haskell files
augroup tags
    au BufWritePost *.hs            silent !init-tags %
    au BufWritePost *.hsc           silent !init-tags %
augroup END

if has('pythonx')
    pyx import sys, os, vim
    pyx sys.path.insert(0, os.environ['HOME'] + '/.vim/py')
    pyx import qualified_tag
    "autocmd FileType haskell nnoremap <buffer> <silent> <c-]> :pyx qualified_tag.tag_word(vim)<cr>
endif
"/////

"AUTOCOMPLETE
"change basic autocomplete to only work in current buffer and ones open in other windows
set complete=.,w,t
"unix like completion - longest substring
set completeopt+=longest
"add command to retrigger longest substring
inoremap <expr> <C-j> pumvisible() ? "\<C-e><C-n>" : "\<C-j>"
"help is confusing but this basically stops autocomplete making your completion uppercase when doing a longest match
set infercase
"/////

"black hole deletion for all modes
noremap x "_x
noremap d "_d
nnoremap dd "_dd
noremap D "_D
noremap c "_c
nnoremap cc "_cc
noremap C "_C
noremap <leader>x x
noremap <leader>d d
nnoremap <leader>dd dd
noremap <leader>D D
"this is just inconsistent does yy by default instead!
noremap Y y$

"newlines without insert mode
nnoremap <leader>o moo<esc>`o
nnoremap <leader>O moO<esc>`o

"sort out end of file crazyness
autocmd FileType * set nofixendofline


"""""""""""""""""
"vim-plug section
"""""""""""""""""
"note this does:
"syntax enable
"filetype plugin indent on

" Specify a directory for plugins
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

"shorthand for installing plugins
command! InstallPlugins update <bar> so % <bar> PlugInstall

"change surrounding stuff 
Plug 'https://github.com/tpope/vim-surround'
"repeat motions from plugins - they have to use this plugin for it to work
Plug 'tpope/vim-repeat'

"/////
"Asynchronous linting engine!
"fast syntax checking
Plug 'w0rp/ale'
"this disables some linters that don't work
let g:ale_linters = {
\   'haskell': ['stack-build','stack-build!!', 'hlint', 'hdevtools', 'hfmt' ],
\}
let g:ale_haskell_stack_build_options = '--fast --work-dir .stack-work-ale --test --no-run-tests'
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
nnoremap <C-h> :ALEDetail <cr>
nnoremap <C-l> :ALELint <cr>
"/////

"haskell autocomplete
Plug 'eagletmt/neco-ghc'

"haskell automatic imports
Plug 'dan-t/vim-hsimport'
autocmd FileType haskell nnoremap <buffer> <silent> <leader>hm :silent update <bar> HsimportSymbol<CR>

"change w etc to work on camelcase
Plug 'chaoren/vim-wordmotion'
let g:wordmotion_spaces = ''

"/////
"ag file searching integration
":Ack [options] {pattern} [{directories}]
Plug 'mileszs/ack.vim'
"get ack to run ag!
let g:ackprg = 'ag --nogroup --nocolor --column'

"Ack shortcuts
nnoremap <silent> <Leader>ff :Ack! '\b<cword>\b'<CR>
"note type gets both newtype and type
autocmd FileType haskell,hamlet nnoremap <buffer> <silent> <Leader>fd :Ack! '\b<cword>\s*::<bar>data\s+<cword>\b<bar>type\s+<cword>\b'<CR>

"///
"not Ack but related

"find local definition
"note dot here is concatenation. need double escaping for some reason. single quotes need less escaping!
nnoremap <Leader>l :let @/ = '\(^\\|data\s\+\\|type\s\+\)'.expand("<cword>").'\>'<cr>n

"next/previous definition
nnoremap <Leader>n /^\w<cr>
nnoremap <Leader>N ?^\w<cr>
"go to imports
nnoremap <Leader>i ?^import<cr>
"///
"/////

"fuzzy find
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

"type information
Plug 'bitc/vim-hdevtools', {'for': 'haskell'}

"setup shortcuts. these are only set in haskell buffers
autocmd FileType haskell nnoremap <buffer> <Leader>ht :HdevtoolsType<CR>
"need execute here as for some reason HdevtoolsClear is trying to read '|' as an argument
autocmd FileType haskell nnoremap <buffer> <silent> <space> :execute ":HdevtoolsClear"<bar>:ClearSearchHighlight<CR>
autocmd FileType haskell nnoremap <buffer> <Leader>hi :HdevtoolsInfo<CR>

"nice filebrowsing
Plug 'scrooloose/nerdtree'

"automatically apply hlint suggestions
Plug 'mpickering/hlint-refactor-vim'
"stop it setting up own keybindings (overwrites t(ill) motion)
let g:hlintRefactor#disableDefaultKeybindings = 1
nnoremap <leader>r :call ApplyOneSuggestion()<cr>

"better syntax highlighting for haskell + cabal 
Plug 'neovimhaskell/haskell-vim'
"switch indenting off - looks like it ignores context 
let g:haskell_indent_disable=1

"yesod template syntax highlighting
Plug 'pbrisbin/vim-syntax-shakespeare'

"sorts out the quickfix window (used by Ack)
Plug 'yssl/QFEnter'

"numbers on tab line 
Plug 'mkitt/tabline.vim'
"do some colouring:
highlight TabLine      ctermfg=Black  ctermbg=White       cterm=NONE
highlight TabLineFill  ctermfg=Black  ctermbg=LightYellow cterm=NONE
highlight TabLineSel   ctermfg=White  ctermbg=DarkBlue    cterm=NONE

"make uuids with <leader-u>
Plug 'kburdett/vim-nuuid'

"n of m searching + also quicker than native
Plug 'google/vim-searchindex'

" Initialize plugin system
call plug#end()

"finish the command augroup
augroup END
