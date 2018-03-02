command! OpenErrors cfile $TRENT_ROOT/.errors

function! ReadErrors()
  silent !read-errors
  redraw!
  OpenErrors
  ":execute "normal! \<C-O>"
endfunction

command! ReadErrors call ReadErrors()

