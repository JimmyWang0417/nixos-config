"                        _                              __ _       
"  _ __   ___  _____   _(_)_ __ ___     ___ ___  _ __  / _(_) __ _ 
" | '_ \ / _ \/ _ \ \ / / | '_ ` _ \   / __/ _ \| '_ \| |_| |/ _` |
" | | | |  __/ (_) \ V /| | | | | | | | (_| (_) | | | |  _| | (_| |
" |_| |_|\___|\___/ \_/ |_|_| |_| |_|  \___\___/|_| |_|_| |_|\__, |
"                                                            |___/ 
" by wangjunrui
" Keep Coc extension declarations before plug#end; helpers before key mappings.
let s:config_dir = expand('<sfile>:p:h')
for s:module in ['dependent.vim', 'command.vim', 'coc.vim', 'plugins.vim', 'ui.vim', 'keyboard.vim', 'addition.vim']
  execute 'source ' . fnameescape(s:config_dir . '/' . s:module)
endfor
unlet s:module s:config_dir
