" pager.vim — read-only viewer for the context-inspector reports.
" Loaded with `nvim -RNn -u NONE -c 'source .../pager.vim' <file>`.
" The content arrives WITHOUT ANSI (the lib strips it); here we recolor it by
" pattern, replicating ci_colorize()'s rules but as Neovim :syntax, so the color
" is kept AND we gain vi navigation (j/k, /, n, y, etc.).

" --- pager appearance ---
set readonly nomodifiable noswapfile nobackup nowritebackup
set number norelativenumber nolist signcolumn=no
set laststatus=0 noruler noshowcmd noshowmode
set wrap linebreak breakindent scrolloff=2
set mouse=a
silent! set termguicolors

" --- quit = closes the popup ---
nnoremap <silent> <buffer> q     <Cmd>qa!<CR>
nnoremap <silent> <buffer> <Esc> <Cmd>qa!<CR>
nnoremap <silent> <buffer> <C-c> <Cmd>qa!<CR>

" --- syntax that mimics ci_colorize ---
if has('syntax')
  syntax on
  syntax clear
  syntax match ciHeader   /^═══.*═══\s*$/
  syntax match ciContext  /^Context Usage.*$/
  syntax match ciModel    /^Model:.*$/
  syntax match ciTokens   /^Tokens:.*$/
  syntax match ciFree     /^Free space:.*$/
  syntax match ciUsage    /^Usage:.*$/
  syntax match ciSection  /^—\s.*$/
  syntax match ciBlock    /^\%(Breakdown.*\|On-disk inventory:\|System prompt \/.*\)$/
  " agentsview health/get blocks
  syntax match ciHKey     /^\s*\%(Grade\|Outcome\|Health\|Signals\|Session\|Project\|Agent\|Branch\|Cwd\|Started\|Ended\|Messages\):.*$/
  syntax match ciGradeA   /\<A\>\s*(score/
  syntax match ciFail     /\%(Tool failures\|Consecutive fails\|Final failure streak\|Secret findings\):\s*[1-9][0-9]*/
  syntax match ciBullet   /•/
  syntax match ciSlash    #\s/\%(context\|mcp\|memory\|cost\|compact\|permissions\|agents\|skills\)\>#

  highlight default ciHeader  cterm=bold ctermfg=14 gui=bold guifg=#56b6c2
  highlight default ciContext cterm=bold ctermfg=13 gui=bold guifg=#c678dd
  highlight default ciModel              ctermfg=6  guifg=#56b6c2
  highlight default ciTokens  cterm=bold ctermfg=11 gui=bold guifg=#e5c07b
  highlight default ciFree     cterm=bold ctermfg=10 gui=bold guifg=#98c379
  highlight default ciUsage   cterm=bold ctermfg=11 gui=bold guifg=#e5c07b
  highlight default ciSection            ctermfg=3  guifg=#d19a66
  highlight default ciBlock   cterm=bold ctermfg=12 gui=bold guifg=#61afef
  highlight default ciHKey    cterm=bold ctermfg=12 gui=bold guifg=#61afef
  highlight default ciGradeA  cterm=bold ctermfg=10 gui=bold guifg=#98c379
  highlight default ciFail    cterm=bold ctermfg=9  gui=bold guifg=#e06c75
  highlight default ciBullet             ctermfg=6  guifg=#56b6c2
  highlight default ciSlash              ctermfg=5  guifg=#c678dd
endif

normal! gg
