import json, os, pathlib, subprocess

names = json.loads(os.environ["DSH_PLUGIN_NAMES"])
root = pathlib.Path(os.environ.get("DSH_HOME") or pathlib.Path.home() / ".dsh")
manifest_path = root / "profiles" / "web" / "package.json"
deps = {}
if manifest_path.exists():
    deps = json.loads(manifest_path.read_text()).get("dependencies") or {}
wanted = set(names)
add, remove = [], []
for key, spec in deps.items():
    if not isinstance(spec, str):
        spec = ""
    if key not in wanted and spec not in wanted:
        remove.append(key)
for name in names:
    spec = deps.get(name, "")
    if not isinstance(spec, str):
        spec = ""
    # pnpm saves `github:owner/repo` under the package name, not the spec.
    if spec == "" and any(
        isinstance(value, str) and value == name for value in deps.values()
    ):
        continue
    if spec.startswith("link:") or spec.startswith("file:"):
        if name not in remove:
            remove.append(name)
        add.append(name)
    elif spec == "":
        add.append(name)
dsh = os.environ["DSH"]
if remove:
    subprocess.check_call([dsh, "plugin", "--profile", "web", "remove", *remove])
if add:
    subprocess.check_call([dsh, "plugin", "--profile", "web", "add", *add])
