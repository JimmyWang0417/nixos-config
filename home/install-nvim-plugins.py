"""Install vim-plug, its plugins, and coc extensions. Idempotent.

Reads plugin names from ~/.config/nvim/plugins.vim and extension names from
~/.config/nvim/coc.vim. A plugin that already has a .git checkout is left
alone. A coc extension that already has node_modules/<name>/package.json is
left alone. nvim is started only for the missing set.
"""

import os
import re
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

PLUG_URL = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
# How long to wait for the coc.nvim node service before giving up.
COC_START_ATTEMPTS = 300
COC_START_INTERVAL_MS = 200


def home() -> Path:
    raw = os.environ.get("HOME")
    if not raw:
        sys.exit("HOME is unset")
    return Path(raw)


def nvim_data_dir() -> Path:
    # Match Neovim stdpath('data'): $XDG_DATA_HOME/nvim or ~/.local/share/nvim.
    xdg = os.environ.get("XDG_DATA_HOME")
    base = Path(xdg) if xdg else home() / ".local/share"
    return base / "nvim"


def nvim_config_dir() -> Path:
    # home-manager writes this tree to $HOME/.config/nvim. plugins.vim also
    # pins plug#begin to ~/.config/nvim/plugged, which does not follow
    # XDG_CONFIG_HOME.
    return home() / ".config/nvim"


def coc_modules_dir() -> Path:
    # Match coc#util#get_data_home().
    xdg = os.environ.get("XDG_CONFIG_HOME")
    if xdg and Path(xdg).is_dir():
        root = Path(xdg) / "coc"
    else:
        root = home() / ".config/coc"
    return root / "extensions/node_modules"


def plugin_names(text: str) -> list[str]:
    names = []
    for repo in re.findall(r"(?m)^\s*Plug\s+'([^']+)'", text):
        name = repo.strip().rstrip("/").split("/")[-1]
        if name.endswith(".git"):
            name = name[: -len(".git")]
        if not name:
            sys.exit(f"Plug entry {repo!r} has no directory name")
        names.append(name)
    if not names:
        sys.exit("plugins.vim has no Plug entries")
    return names


def coc_extension_names(text: str) -> list[str]:
    match = re.search(r"g:coc_global_extensions\s*=\s*\[(.*?)\]", text, re.S)
    if not match:
        sys.exit("coc.vim has no g:coc_global_extensions list")
    names = re.findall(r"'([^']+)'", match.group(1))
    if not names:
        sys.exit("g:coc_global_extensions is empty")
    return names


def ensure_plug_vim(path: Path) -> str:
    if path.is_file() and path.stat().st_size > 0:
        return "present"
    path.parent.mkdir(parents=True, exist_ok=True)
    partial = path.with_name(path.name + ".part")
    try:
        urllib.request.urlretrieve(PLUG_URL, partial)
        if not partial.is_file() or partial.stat().st_size == 0:
            sys.exit("downloaded plug.vim is empty")
        partial.replace(path)
    finally:
        partial.unlink(missing_ok=True)
    return "fetched"


def clear_empty(path: Path, label: str) -> None:
    """Remove an empty placeholder so the installer can create a real checkout."""
    if not path.exists():
        return
    if path.is_dir() and not any(path.iterdir()):
        path.rmdir()
        return
    sys.exit(f"{path} is not {label}; leaving it in place")


def missing_plugins(root: Path, names: list[str]) -> list[str]:
    missing = []
    for name in names:
        dest = root / name
        if (dest / ".git").exists():
            continue
        clear_empty(dest, "a vim-plug checkout")
        missing.append(name)
    return missing


def missing_extensions(root: Path, names: list[str]) -> list[str]:
    missing = []
    for name in names:
        dest = root / name
        if (dest / "package.json").is_file():
            continue
        clear_empty(dest, "an installed coc extension")
        missing.append(name)
    return missing


def prepare_environment() -> None:
    bins = []
    for key in ("GIT", "NODE"):
        value = os.environ.get(key)
        if value:
            bins.append(str(Path(value).parent))
    ordered = []
    seen = set()
    for item in bins:
        if item not in seen:
            seen.add(item)
            ordered.append(item)
    if ordered:
        os.environ["PATH"] = ":".join(ordered + [os.environ.get("PATH", "")])
    os.environ["GIT_TERMINAL_PROMPT"] = "0"
    ca = os.environ.get("SSL_CERT_FILE")
    if ca:
        os.environ.setdefault("GIT_SSL_CAINFO", ca)
        os.environ.setdefault("CURL_CA_BUNDLE", ca)
    node = os.environ.get("NODE")
    if node:
        os.environ["COC_NODE_PATH"] = node


def run_nvim(bootstrap: Path) -> None:
    nvim = os.environ.get("NVIM") or "nvim"
    cmd = [nvim, "--headless", "-n", "-i", "NONE", "-u", str(bootstrap)]
    print("nvim-plugins:", " ".join(cmd), flush=True)
    subprocess.check_call(cmd)


def write_plug_bootstrap(directory: Path) -> Path:
    path = directory / "plug-install.vim"
    path.write_text(
        "\n".join(
            [
                "set nocompatible",
                "filetype plugin on",
                "set nomore",
                "execute 'set runtimepath^=' . fnameescape($NVIM_SITE)",
                "execute 'source' fnameescape($NVIM_PLUGINS_VIM)",
                "PlugInstall --sync",
                "qa!",
                "",
            ]
        )
    )
    return path


def write_coc_bootstrap(directory: Path, extensions: list[str]) -> Path:
    listed = ",".join("'" + name.replace("'", "''") + "'" for name in extensions)
    path = directory / "coc-install.vim"
    path.write_text(
        "\n".join(
            [
                "set nocompatible",
                "filetype plugin on",
                "set nomore",
                "let g:coc_global_extensions = []",
                "execute 'set runtimepath^=' . fnameescape($NVIM_SITE)",
                "execute 'source' fnameescape($NVIM_PLUGINS_VIM)",
                f"let s:coc_exts = [{listed}]",
                "let s:coc_attempt = 0",
                "function! s:CocInstallWhenReady() abort",
                "  if get(g:, 'coc_service_initialized', 0)",
                "    try",
                "      call coc#util#install_extension(['-sync'] + s:coc_exts)",
                "    catch",
                "      echohl Error",
                "      echom v:exception",
                "      echohl None",
                "      cquit 1",
                "    endtry",
                "    qa!",
                "    return",
                "  endif",
                "  let s:coc_attempt += 1",
                f"  if s:coc_attempt >= {COC_START_ATTEMPTS}",
                "    echohl Error",
                "    echom 'coc.nvim service did not initialize'",
                "    echohl None",
                "    cquit 1",
                "  endif",
                f"  call timer_start({COC_START_INTERVAL_MS}, {{-> s:CocInstallWhenReady()}})",
                "endfunction",
                f"call timer_start({COC_START_INTERVAL_MS}, {{-> s:CocInstallWhenReady()}})",
                "",
            ]
        )
    )
    return path


def main() -> None:
    prepare_environment()
    config = nvim_config_dir()
    plugins_vim = config / "plugins.vim"
    coc_vim = config / "coc.vim"
    if not plugins_vim.is_file() or not coc_vim.is_file():
        sys.exit(f"missing {plugins_vim} or {coc_vim}")

    plugs = plugin_names(plugins_vim.read_text(encoding="utf-8"))
    extensions = coc_extension_names(coc_vim.read_text(encoding="utf-8"))
    plug_vim = nvim_data_dir() / "site/autoload/plug.vim"
    print(f"plug.vim: {ensure_plug_vim(plug_vim)}", flush=True)

    plug_root = home() / ".config/nvim/plugged"
    need_plugs = missing_plugins(plug_root, plugs)
    need_exts = missing_extensions(coc_modules_dir(), extensions)
    if not need_plugs and not need_exts:
        print("nvim plugins: already installed", flush=True)
        return

    os.environ["NVIM_SITE"] = str(nvim_data_dir() / "site")
    os.environ["NVIM_PLUGINS_VIM"] = str(plugins_vim)
    with tempfile.TemporaryDirectory(prefix="nvim-plugin-install-") as tmp:
        directory = Path(tmp)
        if need_plugs:
            print("PlugInstall --sync: " + " ".join(need_plugs), flush=True)
            run_nvim(write_plug_bootstrap(directory))
        if need_exts:
            print("CocInstall -sync: " + " ".join(need_exts), flush=True)
            run_nvim(write_coc_bootstrap(directory, need_exts))

    still_plugs = [name for name in plugs if not (plug_root / name / ".git").exists()]
    modules = coc_modules_dir()
    still_exts = [
        name for name in extensions if not (modules / name / "package.json").is_file()
    ]
    if still_plugs or still_exts:
        sys.exit(f"still missing plugs={still_plugs} coc={still_exts}")
    print("nvim plugins: installed", flush=True)


if __name__ == "__main__":
    main()
