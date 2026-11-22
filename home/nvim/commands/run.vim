" Interactive programs get a terminal, with argv passed directly to the process.
function! OrionRun() abort
  let l:type = &filetype
  if index(['c', 'cpp', 'python', 'sh'], l:type) < 0
    return OrionCommandWarn('No F6 runner configured for filetype: ' . l:type)
  endif
  let l:source = OrionCommandSavedPath()
  if empty(l:source)
    return -1
  endif
  if index(['c', 'cpp'], l:type) >= 0
    let l:binary = OrionCommandExecutablePath(l:source)
    if !executable(l:binary)
      call OrionCommandWarn('Build this file with F5 before running: ' . l:binary)
      return -1
    endif
    let l:argv = [l:binary]
  elseif l:type ==# 'python'
    let l:argv = ['python3', l:source]
  else
    let l:argv = ['bash', '--', l:source]
  endif
  botright new
  try
    let l:job = jobstart(l:argv, {'term': v:true})
  catch
    close!
    call OrionCommandWarn(v:exception)
    return -1
  endtry
  if l:job <= 0
    close!
    call OrionCommandWarn('Could not start: ' . l:argv[0])
    return -1
  endif
  startinsert
  return l:job
endfunction

function! OrionBuildRun() abort
  if OrionBuild() != 0
    return -1
  endif
  return OrionRun()
endfunction
