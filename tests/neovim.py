#!/usr/bin/env python3
"""Run real headless Neovim with recording tools and isolated temporary XDG data."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(
    os.environ.get(
        "NVIM_CONFIG_SOURCE", Path(__file__).resolve().parents[1] / "home/nvim"
    )
)
NVIM = os.environ.get("NVIM_BIN") or shutil.which("nvim")
STUB = r"""#!PYTHON
import json,os,pathlib,sys
name=pathlib.Path(sys.argv[0]).name
entry={"tool":name,"argv":sys.argv[1:]}
if name in ["black","clang-format","shfmt"]:
    entry["stdin"]=sys.stdin.read()
with open(os.environ["ORION_TEST_CALLS"],"a") as output:
    output.write(json.dumps(entry)+"\n")
if name==os.environ.get("ORION_TEST_FAIL_TOOL"):
    sys.stderr.write("deliberate tool failure\n")
    sys.exit(37)
if name in ["black","clang-format","shfmt"]:
    sys.stdout.write(os.environ.get("ORION_TEST_FORMATTED",entry["stdin"]))
if name in ["gcc","g++"]:
    target=pathlib.Path(sys.argv[sys.argv.index("-o")+1])
    target.write_text("#!"+sys.executable+"\nimport json,os,sys\nwith open(os.environ['ORION_TEST_CALLS'],'a') as f:f.write(json.dumps({'tool':'built-program','argv':sys.argv[1:]})+'\\n')\n")
    target.chmod(0o700)
"""


def vim_string(text):
    return "'" + str(text).replace("'", "''") + "'"


class NeovimCommandTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="neovim-commands-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.tools = self.root / "bin"
        self.tools.mkdir()
        for tool in ["black", "clang-format", "shfmt", "gcc", "g++", "python3", "bash"]:
            path = self.tools / tool
            path.write_text(STUB.replace("#!PYTHON", "#!" + sys.executable, 1))
            path.chmod(0o700)
        self.calls_path = self.root / "calls.jsonl"
        self.environment = os.environ.copy()
        self.environment.update(
            PATH=str(self.tools), ORION_TEST_CALLS=str(self.calls_path)
        )
        for variable in [
            "XDG_DATA_HOME",
            "XDG_CONFIG_HOME",
            "XDG_STATE_HOME",
            "XDG_CACHE_HOME",
        ]:
            directory = self.root / variable.lower()
            directory.mkdir()
            self.environment[variable] = str(directory)

    def calls(self):
        return (
            [json.loads(line) for line in self.calls_path.read_text().splitlines()]
            if self.calls_path.exists()
            else []
        )

    def source_file(self, name, content="original\n"):
        path = self.root / name
        path.write_text(content)
        return path

    def edit(self, path, filetype):
        return f"execute 'edit ' . fnameescape({vim_string(path)})\nsetlocal filetype={filetype}\n"

    def execute(self, actions):
        driver = self.root / "check.vim"
        errors = self.root / "errors.json"
        driver.write_text(
            "set nomore\n"
            + f"execute 'source ' . fnameescape({vim_string(SOURCE / 'command.vim')})\n"
            + f"execute 'source ' . fnameescape({vim_string(SOURCE / 'keyboard.vim')})\n"
            + actions
            + f"\ncall writefile([json_encode(v:errors)], {vim_string(errors)})\n"
            + "if !empty(v:errors)\n  cquit\nendif\nqa!\n"
        )
        result = subprocess.run(
            [NVIM, "--headless", "-u", "NONE", "-i", "NONE", "-n", "-S", str(driver)],
            cwd=self.root,
            env=self.environment,
            capture_output=True,
            text=True,
            timeout=15,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(errors.exists(), result.stderr)
        self.assertEqual(json.loads(errors.read_text()), [], result.stderr)

    def test_shell_formatting_uses_stdin_and_never_runs_or_saves_script(self):
        path = self.source_file(
            "format 'quoted'; touch PWN; $(touch PWN2).sh", "touch SHOULD_NOT_RUN\n"
        )
        self.environment["ORION_TEST_FORMATTED"] = "touch    SHOULD_NOT_RUN\n"
        self.execute(
            self.edit(path, "sh")
            + "call assert_equal(0, Format())\ncall assert_equal(['touch    SHOULD_NOT_RUN'], getline(1, '$'))"
        )
        self.assertEqual(path.read_text(), "touch SHOULD_NOT_RUN\n")
        self.assertFalse((self.root / "SHOULD_NOT_RUN").exists())
        self.assertFalse((self.root / "PWN").exists())
        self.assertFalse((self.root / "PWN2").exists())
        self.assertEqual(
            self.calls(),
            [
                {
                    "tool": "shfmt",
                    "argv": ["-filename", str(path)],
                    "stdin": "touch SHOULD_NOT_RUN\n",
                }
            ],
        )

    def test_python_formatting_supports_unnamed_modified_buffer(self):
        self.environment["ORION_TEST_FORMATTED"] = "x = 1\n"
        self.execute(
            "enew\nsetlocal filetype=python\ncall setline(1, 'x=1')\ncall assert_equal(0, Format())\ncall assert_equal(['x = 1'], getline(1, '$'))\ncall assert_equal('', expand('%'))"
        )
        call = self.calls()[0]
        self.assertEqual(call["tool"], "black")
        self.assertEqual(
            call["argv"], ["--quiet", "--stdin-filename", "untitled.python", "-"]
        )
        self.assertEqual(call["stdin"], "x=1\n")

    def test_formatter_failure_preserves_buffer_and_original_disk_file(self):
        path = self.source_file("bad.py", "original\n")
        self.environment["ORION_TEST_FAIL_TOOL"] = "black"
        self.execute(
            self.edit(path, "python")
            + "call setline(1, 'unsaved')\ncall assert_notequal(0, Format())\ncall assert_equal(['unsaved'], getline(1, '$'))\ncall assert_true(&modified)"
        )
        self.assertEqual(path.read_text(), "original\n")

    def test_missing_formatter_reports_failure_without_changing_buffer(self):
        (self.tools / "black").unlink()
        self.execute(
            "enew\nsetlocal filetype=python\ncall setline(1, 'untouched')\ntry\ncall assert_notequal(0, Format())\ncatch\ncall assert_report(v:exception)\nendtry\ncall assert_equal(['untouched'], getline(1, '$'))"
        )
        self.assertEqual(self.calls(), [])

    def test_formatter_replaces_all_lines_and_preserves_view(self):
        path = self.source_file("many.py", "old one\nold two\nold three\n")
        self.environment["ORION_TEST_FORMATTED"] = "new one\nnew two\n"
        self.execute(
            self.edit(path, "python")
            + "call cursor(2, 2)\ncall assert_equal(0, Format())\ncall assert_equal(['new one', 'new two'], getline(1, '$'))\ncall assert_equal(2, line('.'))"
        )
        self.assertEqual(path.read_text(), "old one\nold two\nold three\n")

    def test_c_and_cpp_use_separate_compilers_and_safe_absolute_paths(self):
        c = self.source_file("中文 'quoted'; touch PWN; $(touch PWN2).c")
        cpp = self.source_file("separate cpp.cpp")
        self.execute(
            self.edit(c, "c")
            + "call setline(1, 'saved before building')\ncall assert_equal(0, Compile())\n"
            + self.edit(cpp, "cpp")
            + "call assert_equal(0, Compile())"
        )
        calls = self.calls()
        self.assertEqual([call["tool"] for call in calls], ["gcc", "g++"])
        self.assertIn(str(c), calls[0]["argv"])
        self.assertIn(str(c.with_suffix("")), calls[0]["argv"])
        self.assertIn("-std=c17", calls[0]["argv"])
        self.assertIn("-std=c++14", calls[1]["argv"])
        self.assertEqual(c.read_text(), "saved before building\n")
        self.assertFalse((self.root / "PWN").exists())
        self.assertFalse((self.root / "PWN2").exists())

    def test_f5_only_syntax_checks_python_and_shell(self):
        python = self.source_file("check 'python'; file.py")
        shell = self.source_file("check shell.sh")
        self.execute(
            self.edit(python, "python")
            + "call assert_equal(0, Compile())\n"
            + self.edit(shell, "sh")
            + "call assert_equal(0, Compile())"
        )
        self.assertEqual(
            self.calls(),
            [
                {"tool": "python3", "argv": ["-m", "py_compile", str(python)]},
                {"tool": "bash", "argv": ["-n", "--", str(shell)]},
            ],
        )

    def test_run_python_uses_direct_argv_terminal_without_time_shell_typo(self):
        path = self.source_file("run 'python'; $(touch PWN).py")
        self.execute(
            self.edit(path, "python")
            + "let job = Run()\ncall assert_true(job > 0)\ncall assert_equal([0], jobwait([job], 5000))"
        )
        self.assertEqual(self.calls(), [{"tool": "python3", "argv": [str(path)]}])
        self.assertFalse((self.root / "PWN").exists())

    def test_f7_checks_then_runs_script_once(self):
        path = self.source_file("run shell.sh")
        self.execute(
            self.edit(path, "sh")
            + "let job = CompileRunGcc()\ncall assert_true(job > 0)\ncall assert_equal([0], jobwait([job], 5000))"
        )
        self.assertEqual(
            self.calls(),
            [
                {"tool": "bash", "argv": ["-n", "--", str(path)]},
                {"tool": "bash", "argv": ["--", str(path)]},
            ],
        )

    def test_f7_builds_and_runs_c_binary_with_spaces_and_metacharacters(self):
        path = self.source_file("compiled 'file'; $(touch PWN).c")
        self.execute(
            self.edit(path, "c")
            + "let job = CompileRunGcc()\ncall assert_true(job > 0)\ncall assert_equal([0], jobwait([job], 5000))"
        )
        self.assertEqual(
            [call["tool"] for call in self.calls()], ["gcc", "built-program"]
        )
        self.assertFalse((self.root / "PWN").exists())

    def test_f7_never_runs_stale_binary_after_compile_failure(self):
        path = self.source_file("compile failure.c")
        binary = path.with_suffix("")
        binary.write_text(
            f"#!{sys.executable}\nfrom pathlib import Path\nPath({str(self.root / 'STALE_EXECUTED')!r}).touch()\n"
        )
        binary.chmod(0o700)
        self.environment["ORION_TEST_FAIL_TOOL"] = "gcc"
        self.execute(self.edit(path, "c") + "call assert_equal(-1, CompileRunGcc())")
        self.assertEqual([call["tool"] for call in self.calls()], ["gcc"])
        self.assertFalse((self.root / "STALE_EXECUTED").exists())

    def test_unnamed_and_readonly_modified_buffers_do_not_launch_tools(self):
        path = self.source_file("readonly.c")
        self.execute(
            "enew\nsetlocal filetype=c\ncall setline(1, 'unsaved')\ncall assert_notequal(0, Compile())\nenew!\n"
            + self.edit(path, "c")
            + "setlocal readonly\ncall setline(1, 'changed')\ncall assert_notequal(0, Compile())"
        )
        self.assertEqual(self.calls(), [])
        self.assertEqual(path.read_text(), "original\n")

    def test_extensionless_source_cannot_overwrite_itself(self):
        path = self.source_file("extensionless")
        self.execute(self.edit(path, "c") + "call assert_equal(0, Compile())")
        self.assertEqual(path.read_text(), "original\n")
        self.assertEqual(self.calls()[0]["argv"][-1], str(path) + ".out")

    def test_full_init_load_order_theme_and_plugin_declarations_survive_reload(self):
        site = Path(self.environment["XDG_DATA_HOME"]) / "nvim/site"
        (site / "autoload").mkdir(parents=True)
        (site / "autoload/plug.vim").write_text(
            "function! plug#begin(...) abort\nlet g:orion_test_plugins = []\ncommand! -nargs=+ Plug call add(g:orion_test_plugins, <q-args>)\nendfunction\n"
            "function! plug#end() abort\ncall assert_equal(12, len(g:coc_global_extensions))\nendfunction\n"
        )
        (site / "colors").mkdir()
        (site / "colors/ayu.vim").write_text("let g:colors_name = 'ayu'\n")
        self.execute(
            f"execute 'set runtimepath^=' . fnameescape({vim_string(site)})\n"
            + f"execute 'source ' . fnameescape({vim_string(SOURCE / 'init.vim')})\n"
            + f"execute 'source ' . fnameescape({vim_string(SOURCE / 'init.vim')})\n"
            + "call assert_equal(17, len(g:orion_test_plugins))\n"
            + "call assert_equal(12, len(g:coc_global_extensions))\n"
            + "call assert_equal('light', g:ayucolor)\n"
            + "call assert_equal('ayu', g:colors_name)"
        )
        self.assertEqual(self.calls(), [])

    def test_existing_navigation_and_function_key_bindings_survive_reload(self):
        self.execute(
            f"execute 'source ' . fnameescape({vim_string(SOURCE / 'command.vim')})\n"
            + "call assert_equal('k', maparg('i', 'n'))\ncall assert_equal('i', maparg('h', 'n'))\n"
            + "call assert_equal(':call Format()<CR>', maparg('<F3>', 'n'))\n"
            + "call assert_equal(':call Compile()<CR>', maparg('<F5>', 'n'))\n"
            + "call assert_equal(':call Run()<CR>', maparg('<F6>', 'n'))\n"
            + "call assert_equal(':call CompileRunGcc()<CR>', maparg('<F7>', 'n'))"
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
