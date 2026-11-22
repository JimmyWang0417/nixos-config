" F5 checks scripts and builds a single C/C++ source file.
function! OrionBuild() abort
  let l:type = &filetype
  if index(['c', 'cpp', 'python', 'sh'], l:type) < 0
    return OrionCommandWarn('No F5 build/check configured for filetype: ' . l:type)
  endif
  let l:source = OrionCommandSavedPath()
  if empty(l:source)
    return 1
  endif
  if l:type ==# 'c'
    let l:argv = ['gcc', '-Wall', '-Wextra', '-Wshadow', '-Wconversion', '-std=c17', '-O2', l:source, '-o', OrionCommandExecutablePath(l:source)]
  elseif l:type ==# 'cpp'
    let l:argv = ['g++', '-Wall', '-Wextra', '-Wshadow', '-Wconversion', '-std=c++14', '-O2', l:source, '-o', OrionCommandExecutablePath(l:source)]
  elseif l:type ==# 'python'
    let l:argv = ['python3', '-m', 'py_compile', l:source]
  else
    let l:argv = ['bash', '-n', '--', l:source]
  endif
  return OrionCommandReport(OrionCommandCapture(l:argv, ''))
endfunction
