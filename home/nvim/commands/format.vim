" Format the buffer through stdin; formatting never saves or runs its contents.
function! OrionFormat() abort
  if &buftype !=# '' || !&modifiable
    return OrionCommandWarn('This buffer cannot be formatted.')
  endif
  let l:name = empty(expand('%:p')) ? 'untitled.' . &filetype : expand('%:p')
  if index(['c', 'cpp'], &filetype) >= 0
    let l:argv = ['clang-format', '--assume-filename=' . l:name]
  elseif &filetype ==# 'python'
    let l:argv = ['black', '--quiet', '--stdin-filename', l:name, '-']
  elseif &filetype ==# 'sh'
    let l:argv = ['shfmt', '-filename', l:name]
  else
    return OrionCommandWarn('No F3 formatter configured for filetype: ' . &filetype)
  endif
  let l:input = join(getline(1, '$'), "\n") . (&endofline ? "\n" : '')
  let l:result = OrionCommandCapture(l:argv, l:input)
  if l:result.exit != 0
    return OrionCommandReport(l:result)
  endif
  let l:lines = split(l:result.stdout, "\n", 1)
  let l:endofline = !empty(l:result.stdout) && l:result.stdout[-1:] ==# "\n"
  if l:endofline
    call remove(l:lines, -1)
  endif
  if empty(l:lines)
    let l:lines = ['']
  endif
  let l:view = winsaveview()
  let l:count = len(l:lines)
  call setline(1, l:lines)
  if line('$') > l:count
    silent! undojoin
    execute (l:count + 1) . ',$delete _'
  endif
  let &l:endofline = l:endofline
  call winrestview(l:view)
  return 0
endfunction
