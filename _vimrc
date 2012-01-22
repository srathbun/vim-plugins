set nocompatible
source $VIMRUNTIME/vimrc_example.vim
source $VIMRUNTIME/mswin.vim
"behave mswin
" set up pathogen
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()


set diffexpr=MyDiff()
function MyDiff()
	let opt = '-a --binary '
	if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
	if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
	let arg1 = v:fname_in
	if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
	let arg2 = v:fname_new
	if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
	let arg3 = v:fname_out
	if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
	let eq = ''
	if $VIMRUNTIME =~ ' '
		if &sh =~ '\<cmd'
			let cmd = '""' . $VIMRUNTIME . '\diff"'
			let eq = '"'
		else
			let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
		endif
	else
		let cmd = $VIMRUNTIME . '\diff'
	endif
	silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction

" Return indent (all whitespace at start of a line), converted from
" tabs to spaces if what = 1, or from spaces to tabs otherwise.
" When converting to tabs, result has no redundant spaces.
function! Indenting(indent, what, cols)
  let spccol = repeat(' ', a:cols)
  let result = substitute(a:indent, spccol, '\t', 'g')
  let result = substitute(result, ' \+\ze\t', '', 'g')
  if a:what == 1
    let result = substitute(result, '\t', spccol, 'g')
  endif
  return result
endfunction

" Convert whitespace used for indenting (before first non-whitespace).
" what = 0 (convert spaces to tabs), or 1 (convert tabs to spaces).
" cols = string with number of columns per tab, or empty to use 'tabstop'.
" The cursor position is restored, but the cursor will be in a different
" column when the number of characters in the indent of the line is changed.
function! IndentConvert(line1, line2, what, cols)
  let savepos = getpos('.')
  let cols = empty(a:cols) ? &tabstop : a:cols
  execute a:line1 . ',' . a:line2 . 's/^\s\+/\=Indenting(submatch(0), a:what, cols)/e'
  call histdel('search', -1)
  call setpos('.', savepos)
endfunction
command! -nargs=? -range=% Space2Tab call IndentConvert(<line1>,<line2>,0,<q-args>)
command! -nargs=? -range=% Tab2Space call IndentConvert(<line1>,<line2>,1,<q-args>)
command! -nargs=? -range=% RetabIndent call IndentConvert(<line1>,<line2>,&et,<q-args>)

" turn on incremental search with ignore case (except explicit caps) and
" highlighting
set incsearch
set ignorecase
set smartcase
set hlsearch
" turn off equalizing windows when one gets closed
set ea

" turn on persistent undo
set undodir=C:\\Vim\\undoFiles
set undofile 
" turn on syntax highlighting
syntax on
autocmd BufRead,BufNewFile *.psl setfiletype psl
autocmd BufRead,BufNewFile *.plb setfiletype psl
"autocmd BufRead,BufNewFile *.let setfiletype let
" use py compile to 'make' python code, for syntax checking with quickfix buf
" autocmd BufRead *.py set makeprg=python\ -c\ \"import\ py_compile,sys;\ sys.stderr=sys.stdout;\ py_compile.compile(r'%')\"
" autocmd BufRead *.py set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m
" Deprecated in favor of pylint
" autocmd BufRead *.py set makeprg=pylint\ -i\ y\ --rcfile=pylint.rc\ %
" autocmd BufRead *.py set efm=%+P[%f],%t%n:\ %#%l:%m,%Z,%+IYour\ code%m,%Z,%-G%.%#
" Deprecated in favor of python mode plugin
" use psl as 'make' program, recognizing error output for quickfix buffer
autocmd BufRead *.psl set makeprg=runtime\ %:t:r.pjb\ -u
autocmd BufRead *.psl set errorformat=%.%#\<%f\ -\ %l\\,%c\>%m,\<psl\>\ :\ Runtime\ error:\ in\ \"%f\"\ line\ %l\ %m

" turn on line numbers
set nu
set backspace=indent,eol,start
"colorscheme darkblue
colorscheme zenburn
set guifont=Consolas:h11:cANSI
set background=dark

" turn on autoindent
set ai
" these may conflict
"Turn on smart indent
set smartindent
set tabstop=4 "set tab character to 4 characters
"set expandtab "turn tabs into whitespace
set shiftwidth=4 "indent width for autoindent
filetype indent on "indent depends on filetype

"Informative status line
set statusline=%F%m%r%h%w\ [TYPE=%Y\ %{&ff}]\ [%l/%L\ (%p%%)]

"Enable indent folding
set foldenable
set fdm=indent

"Hide buffer when not in window (to prevent relogin with FTP edit)
"set bufhidden=hide
"set line wrapping
set wrap
set linebreak
set nolist
set textwidth=0
set wrapmargin=0

"Have 3 lines of offset (or buffer) when scrolling
set scrolloff=3


"Spell check
function! ToggleSpell()
        if !exists("b:spell")
           setlocal spell spelllang=en
	   setlocal spellsuggest=9 " show only 9 suggestions for misspelled words
           let b:spell = 1
        else
           setlocal nospell
           unlet b:spell
        endif
endfunction

"if &t_Co == 256
 " colorscheme xoria256
"endif

nmap <F4> :call ToggleSpell()<CR>
imap <F4> <Esc>: call ToggleSpell()<CR>a
" map ctrl backspace to delete word in insert mode
imap <C-BS> <C-W>
" map ctrl hjkl to move window
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-H> <C-W>h
noremap <C-L> <C-W>l

function! s:ExecuteInShell(command)
	let command = join(map(split(a:command), 'expand(v:val)'))
	let winnr = bufwinnr('^' . command . '$')
	silent! execute  winnr < 0 ? 'botright new ' . fnameescape(command) : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number
	echo 'Execute ' . command . '...'
	silent! execute 'silent %!'. command
	silent! execute 'resize ' . line('$')
	silent! redraw
	silent! execute 'au BufUnload <buffer> execute bufwinnr(' . bufnr('#') . ') . ''wincmd w'''
	silent! execute 'nnoremap <silent> <buffer> <LocalLeader>r :call <SID>ExecuteInShell(''' . command . ''')<CR>'
	echo 'Shell command ' . command . ' executed.'
endfunction

command! -complete=shellcmd -nargs=+ Shell call s:ExecuteInShell(<q-args>)

nnoremap <silent> <Space> :silent noh<Bar>echo<CR>
" turn on auto completion
filetype plugin on
if has("autocmd") && exists("+omnifunc")
autocmd Filetype *
		\	if &omnifunc == "" |
		\		setlocal omnifunc=syntaxcomplete#Complete |
		\	endif
endif

" make autocomplete more like an IDE
set completeopt=longest,menuone
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
"inoremap <expr> <C-n> pumvisible() ? '<C-n>' :	\ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

"inoremap <expr> <M-,> pumvisible() ? '<C-n>' :\ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
" keep menu item always highlighted by simulating <Up> on pu visible
"inoremap <expr> <C-p> pumvisible() ? '<C-p>' :	\ '<C-p><C-r>=pumvisible() ? "\<lt>Up>" : ""<CR>'

" mini buf explorer setup
"let g:miniBufExplMapWindowNavVim = 1
"let g:miniBufExplMapWindowNavArrows = 1
"let g:miniBufExplMapCTabSwitchBufs = 1
"let g:miniBufExplModSelTarget = 1
"let g:miniBufExplSplitBelow=0
"let g:miniBufExplorerDebugLevel = 0
"let g:miniBufExplorerDebugMode = 0

"set vim to automatically change to the directory of the file in the current
"buffer
set autochdir
" set the viminfo settings
set viminfo='50,<1000,s100,:100,h,/100,@100,!,%,nC:/vim/viminfo 


" Function to disable the match paren plugin for remote file editing
" It is unknown why this causes vim to run slowly
function! s:ToggleMatchParen()
        if exists("g:loaded_matchparen")
                :NoMatchParen
                :echo 'MatchParen plugin turned off'
        else
                :DoMatchParen
                :echo 'MatchParen plugin turned on'
        endif
endfunction 

let g:NotEditingRemotely = 1

function! s:ToggleRemoteFile()
    if exists("g:NotEditingRemotely")
        " Disable the matchparen.vim plugin"
        :NoMatchParen

        " Turn off detection of the type of file"
        filetype off

        " Disable the netrwPlugin.vim"
        au! Network
        au! FileExplorer

        " Remove tag scanning (t) and included file scanning (i)"
        set complete=.,w,b,u,k

        " Remove these autocommands which were added by vimBallPlugin.vim"
        au! BufEnter *.vba
        au! BufEnter *.vba.gz
        au! BufEnter *.vba.bz2
        au! BufEnter *.vba.zip

        unlet g:NotEditingRemotely

        :echo 'Remote Edit mode turned on'
    else
        " Enable the matchparen.vim plugin"
        :DoMatchParen

        " Turn on detection of files"
        filetype on

        " Add back in tag scanning (t) and included file scanning (i)"
        set complete=.,w,b,u,t,i,k

        let g:NotEditingRemotely = 1

        :echo 'Remote Edit mode turned off'
    endif
endfunction

command! -nargs=0 ToggleRemoteFile call s:ToggleRemoteFile()
"noremap <F6> :ToggleRemoteFile<CR>

let g:SuperTabLongestHighlight = 1
let g:SuperTabDefaultCompletionType = "context"
" commands associated with project plugin
let g:proj_flags='imsStTv'
let g:proj_run2='!fossil add %n'
let g:proj_run3='!fossil revert %n'
let g:proj_run4='!fossil undo'
let g:proj_run_fold3='!fossil commit'

" compiler commands
autocmd BufNewFile,BufRead *.psl compiler psl
" highlight long lines
"highlight OverLength ctermbg=red ctermfg=white guibg=#592929
"match OverLength /\%160v.\+/

" Set up python mode settings
let g:pymode_lint_config = 'pylint.rc'
let g:pymode_options_indent = 0
let g:pymode_options_other = 0
let g:pymode_options_fold = 0
let g:pymode_rope_guess_project = 0
let g:pydoc = 'c:/Python27/lib/pydoc.py'

" Alternate python syntax highlighting options
highlight InheritUnderlined ctermfg=118 cterm=underline guifg=#1FF07A gui=underline
let python_highlight_all = 1
