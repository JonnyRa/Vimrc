"clear out previous autocmds to stop them being duplicated when resourcing
"this file
"but put them in a group to stop others being tinkered with... unclear if this
"causes issues or not
augroup myCommands
autocmd!

augroup vue
  au!
  autocmd BufNewFile,BufRead *.vue   set syntax=html
augroup END

colorscheme evening
"improve searching to ignore case when everything is lowercase
set ignorecase
set smartcase
""

"show what is being typed
set showcmd
"line numbers
set number
set relativenumber

set grepprg=ag\ --vimgrep\ $* 
set grepformat=%f:%l:%c:%m

"sort out copy + paste
set clipboard=unnamedplus

command! Wall silent! wa

""""""""""""""
"sort out tabs
""""""""""""""
"switch on filetype detection and look at how stuff should be indented for each language
filetype plugin indent on
" show existing tab with 2 spaces width
set tabstop=2
" when indenting with '>', use 2 spaces width
set shiftwidth=2
" On pressing tab, insert spaces instead of tab
set expandtab
""""""""""""""
"last tab
if !exists('g:lastTabVisited')
  let g:lastTabVisited = 1
endif 

nnoremap \tp  :call <SID>swapToLastTab()<CR>
autocmd TabLeave * let g:lastTabVisited = tabpagenr()

function! s:swapToLastTab()
  :exe 'tabn' g:lastTabVisited 
endfunction

""""""""""""""

" this automatically resizes windows upon selection to 5
set winheight=5
"get rid of win only command (right next to previous window!). replace with moving the preview back/forwards
"ctrl-w_i is also by default mapped the same as <c-w>] (but more hacky than tags!)
nnoremap <silent> <C-w>o :call SwapToPreviewAndRun(function('<SID>GoBack'))<cr>
nnoremap <silent> <C-w>i :call SwapToPreviewAndRun(function('<SID>GoForward'))<cr>

nmap <silent> <C-w>= :call ResizeAllWindows()<cr>
nnoremap <silent> <leader>zz :call SwapToPreviewAndRun(function('<SID>RunNormal', ['zz']))<cr>
nnoremap <silent> <leader>zt :call SwapToPreviewAndRun(function('<SID>RunNormal', ['zt']))<cr>
nnoremap <silent> <leader>zb :call SwapToPreviewAndRun(function('<SID>RunNormal', ['zb']))<cr>

function! ResizeAllWindows()
  call RestorePreviewWindowHeight()
  wincmd = "set all equal after restore
endfunction

function! s:SetPreviewHeight()
  let windowNumber = winnr() 
  let position = win_screenpos(windowNumber)
  let positionOfPrevious = win_screenpos(windowNumber -1) 
  let positionOfNext = win_screenpos(windowNumber +1) 
  let column = position[1]
  let previousColumn = positionOfPrevious[1]
  let nextColumn = positionOfNext[1]

  let isInColumnOnItsOwn = column != previousColumn && column != nextColumn
  let isInFirstColumnButSpansTheWholeWidth = column == 1 && positionOfNext == [0,0]

  if !isInColumnOnItsOwn || isInFirstColumnButSpansTheWholeWidth
    exec 'resize' &previewheight 
  endif
endfunction 

function! RestorePreviewWindowHeight()
  silent call SwapToPreviewAndRun (function('<SID>SetPreviewHeight'))
endfunction

function! s:RunNormal(command)
  exec 'normal!' a:command 
endfunction 

function! s:GoBack()
  execute "normal! \<C-o>"
endfunction 

function! s:GoForward()
  "bizzarely need 1 prefixed here because ctrl-i makes a tab character
  "and tab counts as space so normal! doesn't think we've input anything!
  execute "normal! 1\<C-i>"
endfunction 

function! SwapToPreviewAndRun(funk)
  let oldWindowId = win_getid()
  silent! wincmd P "jump to preview, but don't show error
  if &previewwindow
    silent call a:funk()
    let previewWindowId = win_getid()
    if previewWindowId != oldWindowId
      wincmd p "jump back
    endif
  endif

endfunction

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
set sessionoptions-=buffers
command! SaveSession mksession! ~/.vim/sessions/pickup.vim

"when splitting default to more natural positioning
set splitbelow
set splitright

command! FormatJson %!python -m json.tool
command! FormatHaskell %!pretty-simple | ansifilter
command! HTMLToXML %!xmllint --format --recover - 2>/dev/null
command! -nargs=1 RunXPath :w !xmllint --xpath <args> -
autocmd FileType haskell :set cindent

"when you type a hash as the first character stop it triggering reindent
set cinkeys -=0#

"////
"automatically reload file when changes detected
set autoread "this doesn't work on it's own!
augroup reload
  au!
  "https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
  "on these events, any filename... and not in command mode then check files for changes
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if !bufexists("[Command Line]") && filereadable(expand('%')) | silent! checktime % | endif
  " Notification after file change
  autocmd FileChangedShellPost *
    \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
augroup END

let g:markTimer = -1

"set a mark when we hang around for a while - this means it gets added to the jump list
"autocmd CursorHold * call <SID>StartTimer()

function! s:StartTimer()
  let g:markTimer = timer_start (10 * 1000, function('<SID>SetMark', [expand('<afile>')]))
  "echo 'started timer' g:markTimer
endfunction

function! s:SetMark(filename, id)
  if a:filename !~? 'nerd_tree' 
   "echo 'set mark'
   exec ':normal m`<cr>'
  endif
endfunction 

let stopCalled = 'never'

autocmd CursorMoved,InsertEnter * 
\if g:markTimer != -1
\|  "echo 'calledStop' g:markTimer
\|  call timer_stop(g:markTimer)
\|  let stopCalled = g:markTimer . " " . strftime("%X")
\|  let g:markTimer = -1
\|endif


"make CursorHold happen quicker - every second rather than default 4 seconds
set updatetime=1000

"/////
"error stuff

let s:root = expand('<sfile>:p:h')
function! SourceLocal(relativePath)
  let fullPath = s:root . '/'. a:relativePath
  exec 'source ' . fullPath
endfunction

"<expr> lets you use <cword> and expand in a mapping
nnoremap <expr> <leader>rw ':%s/\<'.expand('<cword>').'\>/'

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

autocmd FileType vim set tabstop=2|set shiftwidth=2

"///
"Status line stuff
"status line containing 50 character max filename, modified flag, readonly
"flag, file type, buffer number, line|character percentage through file
"
set statusline=%.50F%m%r\ %y\%w\ buffer\ %n\ %l\|%c\ [%p%%]
"better colours
highlight StatusLine ctermfg=DarkBlue ctermbg=Yellow
"always show the statusline
set laststatus=2
"///

"///fast-tag stuff
"calls a shell script to dump in all the haskell files
autocmd BufWritePost *.hs            silent !init-tags %
autocmd BufWritePost *.hsc           silent !init-tags %

if has('pythonx')
    pyx import sys, os, vim
    pyx sys.path.insert(0, os.environ['HOME'] + '/.vim/py')
    pyx import qualified_tag
    "autocmd FileType haskell nnoremap <buffer> <silent> <c-]> :pyx qualified_tag.tag_word(vim)<cr>
endif
"/////

"AUTOCOMPLETE
"change basic autocomplete to only work in current buffer and ones open in other windows 
"use C-x C-] for tags or add t to this list
set complete=.,w
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
noremap <leader>c c
nnoremap <leader>dd dd
noremap <leader>D D
noremap <leader>C C
"this is just inconsistent does yy by default instead!
noremap Y y$

"newlines without insert mode
nnoremap <leader>o moo<esc>`o
nnoremap <leader>O moO<esc>`o

nnoremap <leader>l a <esc>
nnoremap <leader>L i <esc>l

"sort out end of file crazyness
autocmd FileType * set nofixendofline

nnoremap <silent> <leader>mh :silent call MoveWindow('h')<cr>
nnoremap <silent> <leader>ml :silent call MoveWindow('l')<cr>

"direction is either 'h' for left or 'l' for right
function! MoveWindow(direction)
  "note when debugging in here might need to put in multiple echos as last one tends to get overwritten by confusing window info!
  let currentBuffer = winbufnr(0)
  let oldWindowId = win_getid()

  echom 'oldWindowId' oldWindowId
  echom 'currentBuffer' currentBuffer
  echom 'winnr' winnr()

  "set mark
  normal! mM

  "move focus
  execute "normal \<c-w>".a:direction

  echom 'splitting window'
  "add new window with the correct buffer
  split
  execute 'buffer' currentBuffer

  "close old window
  let windowNumber = win_id2win(oldWindowId)
  echom 'window to close' windowNumber
  "need to get hold of this here as otherwise gets screwed up
  echom 'previous window after split' winnr('#')
  execute "normal \<c-w>".windowNumber.'w'
  echom 'previous window after swapping to window to close' winnr('#')
  let previousWindowBeforeClose = winnr('#')
  quit
  echom 'closed window' windowNumber

  "swap back to the new one and load the mark
  echom 'previous window after close' winnr('#')
  echo 'swapping to previous before close'
  execute "normal \<c-w>".previousWindowBeforeClose.'w'
  normal! `M

endfunction

function! ClearBlankLines()
  let viewInfo = winsaveview()
  %s/^\s\+$//e
  call winrestview(viewInfo)
endfunction

command! ClearBlankLines call ClearBlankLines()

function! RemoveSwapFileIfExists()
  let path = expand('%:p:h')
  let filename = expand ('%:t')

  let extraCharacter = ''
  if filename[0] !=# '.'
    let extraCharacter = '.'
  endif

  let swapFilenameWithoutLast = path. '/' . extraCharacter . filename . '.sw'

  "ends up with a newline at the start
  let currentSwapName = split(execute ('swapname'), "\n")[0]

  let absoluteSwapName = fnamemodify(currentSwapName, ':p')

  let endCharacters = ['p','o','n']
  for character in endCharacters
    let fullSwapFilename = swapFilenameWithoutLast . character
    if fullSwapFilename == absoluteSwapName
      continue
    endif 

    "this is almost a file exists check
    if filereadable(fullSwapFilename)
      "this is zero when it worked negative otherwise
      let worked = delete(fullSwapFilename)
      let workedText = "WARNING couldn't delete"
      if worked==0
        let workedText = 'successfully deleted'
      endif

      echo workedText fullSwapFilename 
    endif

  endfor 
endfunction


"//////
"make a way of going from lcd to cd
au VimEnter * let g:my_project_dir = getcwd()
command! -nargs=? -complete=dir Cd execute 'cd' <q-args> | let g:my_project_dir=getcwd()
cnoreabbrev <expr> cd getcmdtype()==':' && getcmdline()=='cd' ? 'Cd' : 'cd'

command! RestoreCwd execute 'cd' g:my_project_dir
command! ShowFilename echo expand('%')
"/////

"finding .imports file
function! OpenImportFileInSplit()
  let filename = RemoveExtension(expand('%:t')) 
  let cmd = 'findImportFile ' . filename
  silent let importFileList = systemlist(cmd)

  if len(importFileList) != 1
    echo "couldn't find file " . filename
    return
  endif

  execute 'split ' .importFileList[0]

endfunction         

function! RemoveExtension(filename)
  "need both single quotes and backslash here to make . work!
  let splitFilename = split(a:filename,'\.')

  "filenames dont always have extensions
  if splitFilename != []
    return splitFilename[0]
  endif

  return a:filename
endfunction



nnoremap <Leader>gm ?^module<cr>

nnoremap <leader>io :call OpenImportFileInSplit()<cr>

"""""""""""""""""
"vim-plug section
"""""""""""""""""
"note this does:
"syntax enable
"filetype plugin indent on

" Specify a directory for plugins
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

command! -bar ReSource update <bar> so $MYVIMRC

"shorthand for installing plugins
command! InstallPlugins ReSource | PlugInstall

"move by indent level
Plug 'jeetsukumaran/vim-indentwise'

"lets you edit things in the quick fix and delete entries
Plug 'stefandtw/quickfix-reflector.vim'

"powershell syntax
Plug 'PProvost/vim-ps1'

"delete buffers without getting rid of splits (:Bdelete - notice capital!)
Plug 'moll/vim-bbye'

"swap things! g> g< gs
Plug 'machakann/vim-swap'

"vimscript linter
Plug 'syngan/vim-vimlint'

"change surrounding stuff 
Plug 'tpope/vim-surround'
"repeat motions from plugins - they have to use this plugin for it to work
Plug 'tpope/vim-repeat'

"shorthand for bracketing to the end
nmap <leader>) ys$)
nmap <leader>2) ys2w)

"/////
"Asynchronous linting engine!
"fast syntax checking
Plug 'w0rp/ale'
"this disables some linters that don't work
"also vim one is not turned on by default
let g:ale_linters = {
\   'haskell': ['stack-ghc', 'hlint', 'hdevtools', 'hfmt' ]
\,  'cs': []
\,  'vim': ['vint']
\}
let g:ale_haskell_stack_build_options = '--fast --work-dir .stack-work-ale --test --no-run-tests'
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
nnoremap <C-h> :ALEDetail <cr>
"/////

"haskell autocomplete
Plug 'eagletmt/neco-ghc'

"haskell automatic imports
Plug 'dan-t/vim-hsimport'
autocmd FileType haskell nnoremap <buffer> <silent> <leader>hm :silent update <bar> HsimportSymbol<CR>

"add \w etc for camelcase
Plug 'bkad/CamelCaseMotion'
"set up the mappings further down as it causes an error on first load here

"buffer viewing.  gb and gB swap through recently used files
Plug 'jeetsukumaran/vim-buffergator'
nnoremap <silent> <leader>q :BuffergatorToggle<cr>
let g:buffergator_autodismiss_on_select = 0

Plug 'AndrewRadev/undoquit.vim'
let g:undoquit_mapping = ''

"/////
"ag file searching integration
":Ack [options] {pattern} [{directories}]
Plug 'mileszs/ack.vim'
"get ack to run ag!
let g:ackprg = 'ag --nogroup --nocolor --column'

command! -nargs=1 Find execute "Ack!" "-Q" '"'.<args>.'"'

"Ack shortcuts
nnoremap <silent> <Leader>ff :Ack! '\b<cword>\b'<CR>
nnoremap <silent> <Leader>fg :Ack! '<cword>'<CR>
"note type gets both newtype and type
nnoremap <silent> <Leader>fd :FindDefinition <cword><cr>

command! -nargs=1 -complete=tag FindDefinition :Ack! "'\b".<args>.'\s*::<bar>data\s+'<args>'\b<bar>type\s+'.<args>"\b'"<CR>

"///
"not Ack but related

"find local definition
"note dot here is concatenation. need double escaping for some reason. single quotes need less escaping!
nnoremap <Leader>fl :let @/ = '\(^\\|data\s\+\\|type\s\+\)'.expand("<cword>").'\>'<cr>n

"next/previous definition
nnoremap <Leader>n /^\w\+[\n ]*\s*::<cr>
nnoremap <Leader>N ?^\w\+[\n ]*\s*::<cr>
"///
"/////

"fuzzy find
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

nnoremap <C-t> :Tags<cr> 
nnoremap <C-_> :execute "Tags ".expand('<cword>')<cr>
command! -bang -nargs=? -complete=dir HFiles
  \ call fzf#vim#files(<q-args>, {'source': 'ag -u --ignore .hg -g ""'}, <bang>0)
nnoremap <C-n> :Files<cr>
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit',
  \ 'ctrl-p': 'pedit'}

"type information
Plug 'bitc/vim-hdevtools'

"setup shortcuts. these are only set in haskell buffers
autocmd FileType haskell nnoremap <buffer> <Leader>ht :HdevtoolsType<CR>
"need execute here as for some reason HdevtoolsClear is trying to read '|' as an argument
autocmd FileType haskell nnoremap <buffer> <silent> <space> :execute ":HdevtoolsClear"<bar>:ClearSearchHighlight<CR>
autocmd FileType haskell nnoremap <buffer> <Leader>hi :HdevtoolsInfo<CR>

"nice filebrowsing
Plug 'scrooloose/nerdtree'

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
highlight TabLineFill  ctermfg=Black  ctermbg=Yellow      cterm=NONE
highlight TabLineSel   ctermfg=Yellow ctermbg=DarkBlue    cterm=NONE
highlight Normal       ctermbg=Black

"make uuids with <leader-u>
Plug 'kburdett/vim-nuuid'

"n of m searching + also quicker than native
Plug 'google/vim-searchindex'

"haskell import stuff
Plug 'JonnyRa/vim-himposter'
let g:himporterCreateMappings = 1

Plug 'JonnyRa/vim-stackThoseErrorsOfHs', { 'do': './install' }
let g:stackThoseErrorsCreateMappings = 1

" Initialize plugin system
call plug#end()

"finish the command augroup
augroup END

call camelcasemotion#CreateMotionMappings('<leader>')
