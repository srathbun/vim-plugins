set nocompatible
" set up pathogen
"au GUIEnter * simalt ~x
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

set diffopt+=iwhite

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

set ruler
" set mouse on for console
set mouse=a

" turn on persistent undo
set undodir=~/.undo
set undofile 
" have backup files and swap files saved to a temp folder
" Using /var/tmp because I have set /tmp to be tmpfs, /var/tmp is for 
" temp files that live through reboots
set backupdir=/var/tmp
" turn on syntax highlighting
syntax on

augroup pslfiles
	autocmd! 
	" wipes autocmds before setting them
	autocmd BufRead,BufNewFile *.psl setfiletype psl
	autocmd BufRead,BufNewFile *.plb setfiletype psl
	" use psl as 'make' program, recognizing error output for quickfix buffer
	autocmd BufRead *.psl set makeprg=runtime\ %:t:r.pjb\ -u
	autocmd BufRead *.psl set errorformat=%.%#\<%f\ -\ %l\\,%c\>%m,\<psl\>\ :\ Runtime\ error:\ in\ \"%f\"\ line\ %l\ %m
	" compiler commands
	autocmd BufNewFile,BufRead *.psl compiler psl
augroup END

augroup quickfix
	" Automatically open, but do not go to (if there are errors) the quickfix /
	" location list window, or close it when is has become empty.
	"
	" Note: Must allow nesting of autocmds to enable any customizations for quickfix
	" buffers.
	" Note: Normally, :cwindow jumps to the quickfix window if the command opens it
	" (but not if it's already open). However, as part of the autocmd, this doesn't
	" seem to happen.
	autocmd!
	autocmd QuickFixCmdPost [^l]* nested cwindow
augroup END


" turn on line numbers
set nu
set backspace=indent,eol,start

colorscheme zenburn
"set guifont=Consolas:h11:cANSI
set guifont=Monoco:h11:cANSI
set t_Co=256
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
set statusline+=\ %#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

"Enable indent folding
set foldenable
let javaScript_fold = 1
set fdm=indent

"Hide buffer when not in window (to prevent relogin with FTP edit)
"set bufhidden=hide
"set line wrapping
set wrap
set linebreak
set breakat=" ^I!@*-+;:,./?{}()[]<>_"
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

"set vim to automatically change to the directory of the file in the current
"buffer
set autochdir
" set the viminfo settings
set viminfo='50,<1000,s100,:100,h,/100,@100,!,%,n~/.viminfo 
set history=100


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


" turn on auto completion
filetype plugin on
if has("autocmd") && exists("+omnifunc")
augroup omnifunc
	autocmd!
	autocmd Filetype *
			\	if &omnifunc == "" |
			\		setlocal omnifunc=syntaxcomplete#Complete |
			\	endif
	autocmd FileType *
	\ if &omnifunc != '' |
	\   call SuperTabChain(&omnifunc, "<c-p>") |
	\   call SuperTabSetDefaultCompletionType("context") |
	\ endif
augroup END
endif

	"\   call SuperTabSetDefaultCompletionType("<c-x><c-u>") |
" make autocomplete more like an IDE
set completeopt=longest,menuone,preview
"set complete=.,w,b,u,t,i,k
set complete=.,k,t,i,d " t allows completing on tags, but that takes waaay too long
" automatically open and close the popup menu / preview window
" au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif

" supertab options
let g:SuperTabLongestHighlight = 1
let g:SuperTabClosePreviewOnPopupClose = 1
let g:SuperTabLongestEnhanced = 1
let g:SuperTabCompletionContexts = ['s:ContextText', 's:ContextDiscover']
let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']
let g:SuperTabContextDiscoverDiscovery =
	\ ["&omnifunc:<c-x><c-o>", "&completefunc:<c-x><c-u>"]


" commands associated with project plugin
let g:proj_flags='imsStT'
let g:proj_run2="!hg add '%r/%n'"
let g:proj_run3="!hg revert '%r/%n'"
let g:proj_run4="!hg undo"
let g:proj_run_fold3="!hg commit"
" Set up winmanager
let winManagerWindowLayout = 'FileExplorer|TagList'

" highlight long lines
"highlight OverLength ctermbg=red ctermfg=white guibg=#592929
"match OverLength /\%160v.\+/

" Set up python mode settings
let g:pymode_lint_checker = 'pyflakes'
let g:pymode_lint_config = 'c:/Program Files (x86)/vim/pylint.rc'
let g:pymode_options_indent = 0
let g:pymode_options_other = 0
let g:pymode_options_fold = 0
let g:pymode_rope_guess_project = 0
let g:pydoc = 'c:/Python27/lib/pydoc.py'

" Alternate python syntax highlighting options
highlight InheritUnderlined ctermfg=118 cterm=underline guifg=#1FF07A gui=underline
highlight Operator          ctermfg=186 cterm=none guifg=#c9c484 gui=none 
highlight pythonBuiltin     ctermfg=88 cterm=none guifg=#d1a243 gui=none 
let python_highlight_all = 1


" NERDTree options
nmap <F5> :NERDTreeToggle<CR>
augroup nerdTree
	autocmd!
	" Open NERDTree if vim is empty
	autocmd vimenter * if !argc() | NERDTree | endif
	" close vim if NERDTree is the last buffer
	autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
augroup END


nmap <F6> :TagbarToggle<CR>
let g:tagbar_type_javascript = {
	\ 'ctagstype' : 'Javascript',
	\ 'ctagsbin' : '/usr/local/bin/ctags',
	\ 'kinds'     : [
		\ 'a:array',
		\ 'b:boolean',
		\ 'm:method',
		\ 'n:number',
		\ 'o:object',
		\ 'p:property',
		\ 's:string',
		\ 'c:class',
		\ 'f:function',
		\ 'v:variable:0:0'
	\ ],
	\ 'sro'        : '.',
	\ 'kind2scope' : {
		\ 'o' : 'object',
		\ 'f' : 'function'
	\ },
	\ 'scope2kind' : {
		\ 'object' : 'o',
		\ 'function' : 'f'
	\ }
\ }

"let g:tagbar_type_javascript = {
"	\ 'ctagsbin' : '/usr/local/bin/ctags'
"\ }
"let g:tlist_javascript_settings = 'javascript;s:string;a:array;o:object;f:function'
let g:tlist_javascript_settings = 'javascript;a:array;b:boolean;c:class;f:function;m:method;n:number;o:object;p:property;s:string;v:variable'

nmap <F7> :TlistToggle<CR>
let Tlist_Ctags_Cmd='/usr/local/bin/ctags'
nmap <F8> :Gstatus<CR>

" Syntastic options
let g:syntastic_check_on_open=1
let g:syntastic_enable_signs=1

let g:syntastic_error_symbol='✗'
let g:syntastic_warning_symbol='⚠'

let g:syntastic_enable_balloons = 1
let g:syntastic_auto_loc_list=1

let g:syntastic_loc_list_height=6
let g:syntastic_mode_map = { 'mode': 'active',
						   \ 'active_filetypes': ['ruby', 'php', 'js', 'sh'],
						   \ 'passive_filetypes': ['puppet', 'python'] }

let g:syntastic_quiet_warnings=1
let g:syntastic_stl_format = '[%E{Err: %fe #%e}%B{, }%W{Warn: %fw #%w}]'

augroup jsopts
	autocmd!
	au FileType javascript set dictionary+=$HOME/.vim/bundle/node-dict/dict/node.dict
	au FileType javascript setlocal equalprg=/usr/local/share/npm/bin/js-beautify\ -f\ -\ -q\ -t\ -j\ -w\ 140\ --good-stuff\ -b\ \"end-expand\"
	au FileType javascript call tern#Enable()
	let s:script = 'var p = require.resolve("jshint"); var l = p.indexOf("jshint"); process.stdout.write(p.substr(0, l)+"jshint/bin/jshint");'
	au FileType javascript let g:syntastic_javascript_jshint_exe = system("node -e '" . s:script . "'")
augroup END

" search for a tags file in the current dir, looking recursively up towards
" root until one is found
set tags=./tags;/


augroup insertMode
	autocmd!
	"Higlight current line only in insert mode
	autocmd InsertLeave * set nocursorline
	autocmd InsertEnter * set cursorline
augroup END
"cursorline coloring
highlight CursorLine ctermbg=8 cterm=NONE

nmap <leader>l <Plug>TaskList
nmap <leader>c :cclose<CR>:lclose<CR>

nnoremap <silent> <Leader>g :CommandT<CR>

nnoremap <buffer> <Leader>td :TernDoc<CR>
nnoremap <buffer> <Leader>tb :TernDocBrowse<CR>
nnoremap <buffer> <Leader>tt :TernType<CR>
nnoremap <buffer> <Leader>td :TernDef<CR>
nnoremap <buffer> <Leader>tpd :TernDefPreview<CR>
nnoremap <buffer> <Leader>tsd :TernDefSplit<CR>
nnoremap <buffer> <Leader>ttd :TernDefTab<CR>
nnoremap <buffer> <Leader>tr :TernRefs<CR>
nnoremap <buffer> <Leader>tR :TernRename<CR>

" SWANK settings
" not working
" let g:slimv_swank_cmd = '!osascript -e "tell application \"Terminal\" to do script \"node ~/git/swank-js/swank.js\""'
let g:slime_target = "tmux"
let g:slime_no_mappings = 1
xmap <leader>s <Plug>SlimeRegionSend
nmap <leader>s <Plug>SlimeMotionSend
nmap <leader>ss <Plug>SlimeLineSend

xmap <leader>e <Plug>SlimeRegionEval
nmap <leader>e <Plug>SlimeMotionEval
nmap <leader>ee <Plug>SlimeLineEval

" bashsupport settings
let g:BASH_Ctrl_j   = 'off'
let g:BASH_AuthorName   = 'Spencer Rathbun'
let g:BASH_Email        = 'srathbun@riverainc.com'
let g:BASH_Company      = 'Rivera Group Inc.'
