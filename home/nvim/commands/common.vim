" Shared argv-only process and buffer helpers. No user filename enters a shell.
function! OrionCommandWarn(message) abort
  echohl WarningMsg
  echomsg a:message
  echohl None
  return 1
endfunction

function! s:Collect(result, stream, job, data, event) abort
  call extend(a:result[a:stream], a:data)
endfunction

function! OrionCommandCapture(argv, input) abort
  let l:result = {'stdout': [], 'stderr': []}
  try
    let l:job = jobstart(a:argv, {
          \ 'stdout_buffered': v:true,
          \ 'stderr_buffered': v:true,
          \ 'on_stdout': function('s:Collect', [l:result, 'stdout']),
          \ 'on_stderr': function('s:Collect', [l:result, 'stderr']),
          \ })
  catch
    return {'exit': 127, 'stdout': '', 'stderr': v:exception}
  endtry
  if l:job <= 0
    return {'exit': 127, 'stdout': '', 'stderr': 'Could not start: ' . a:argv[0]}
  endif
  if !empty(a:input)
    call chansend(l:job, a:input)
  endif
  call chanclose(l:job, 'stdin')
  let l:status = jobwait([l:job], 30000)[0]
  if l:status < 0
    call jobstop(l:job)
    call jobwait([l:job], 3000)
    return {'exit': 124, 'stdout': '', 'stderr': 'Command did not finish within 30 seconds: ' . a:argv[0]}
  endif
  return {'exit': l:status, 'stdout': join(l:result.stdout, "\n"), 'stderr': join(l:result.stderr, "\n")}
endfunction

function! OrionCommandReport(result) abort
  if a:result.exit != 0
    return OrionCommandWarn(empty(a:result.stderr) ? a:result.stdout : a:result.stderr)
  endif
  if !empty(a:result.stdout) || !empty(a:result.stderr)
    echomsg a:result.stdout . a:result.stderr
  endif
  return 0
endfunction

function! OrionCommandSavedPath() abort
  if &buftype !=# '' || empty(expand('%:p'))
    call OrionCommandWarn('Save this buffer to a named file before checking, building or running it.')
    return ''
  endif
  try
    if &modified || !filereadable(expand('%:p'))
      silent write
    endif
  catch
    call OrionCommandWarn(v:exception)
    return ''
  endtry
  return expand('%:p')
endfunction

function! OrionCommandExecutablePath(source) abort
  let l:target = fnamemodify(a:source, ':r')
  return l:target ==# a:source || empty(fnamemodify(l:target, ':t')) ? a:source . '.out' : l:target
endfunction
