" Explicit helper composition; reloads replace definitions safely.
let s:command_dir = expand('<sfile>:p:h') . '/commands'
for s:module in ['common.vim', 'format.vim', 'build.vim', 'run.vim']
  execute 'source ' . fnameescape(s:command_dir . '/' . s:module)
endfor
unlet s:module s:command_dir

" Retain existing function names for user mappings and commands.
function! Format() abort
  return OrionFormat()
endfunction
function! Compile() abort
  return OrionBuild()
endfunction
function! Run() abort
  return OrionRun()
endfunction
function! CompileRunGcc() abort
  return OrionBuildRun()
endfunction

function! BuildComposer(info)
  if a:info.status != 'unchanged' || a:info.force
    if has('nvim')
      !cargo build --release --locked
    else
      !cargo build --release --locked --no-default-features --features json-rpc
    endif
  endif
endfunction
