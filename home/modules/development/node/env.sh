# POSIX shell: keep npm state in XDG roots without changing HOME.
: "${NPM_CONFIG_USERCONFIG:=${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc}"
: "${NPM_CONFIG_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/npm}"
: "${NPM_CONFIG_PREFIX:=${XDG_DATA_HOME:-$HOME/.local/share}/npm}"
: "${NODE_REPL_HISTORY:=${XDG_STATE_HOME:-$HOME/.local/state}/node/repl_history}"
export NPM_CONFIG_USERCONFIG NPM_CONFIG_CACHE NPM_CONFIG_PREFIX NODE_REPL_HISTORY

# Normalize inherited prefixes too, then put user-global commands after Nix tools.
_node_path_rest=${PATH-}
_node_path_result=
_node_path_started=0
while :; do
  case $_node_path_rest in
  *:*)
    _node_path_entry=${_node_path_rest%%:*}
    _node_path_rest=${_node_path_rest#*:}
    _node_path_more=1
    ;;
  *)
    _node_path_entry=$_node_path_rest
    _node_path_more=0
    ;;
  esac
  if [ "$_node_path_entry" != "$HOME/.npm-global/bin" ] && [ "$_node_path_entry" != "$NPM_CONFIG_PREFIX/bin" ]; then
    if [ "$_node_path_started" = 1 ]; then
      _node_path_result=$_node_path_result:$_node_path_entry
    else
      _node_path_result=$_node_path_entry
      _node_path_started=1
    fi
  fi
  [ "$_node_path_more" = 1 ] || break
done
PATH=${_node_path_result:+$_node_path_result:}$NPM_CONFIG_PREFIX/bin
export PATH
unset _node_path_rest _node_path_result _node_path_started _node_path_entry _node_path_more
