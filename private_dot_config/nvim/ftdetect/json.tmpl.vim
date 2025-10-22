autocmd BufRead,BufNewFile *.json.tmpl set ft=json

" au BufNewFile,BufRead *.{yaml,yml} if getline(1) =~ '^apiVersion:' || getline(2) =~ '^apiVersion:' | setlocal filetype=helm | endif
" Use {{/* */}} as comments
" autocmd FileType helm setlocal commentstring={{/*\ %s\ */}}
