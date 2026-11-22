# Seed public application preferences without replacing existing writable state.
{ lib, pkgs }:
files:
lib.hm.dag.entryAfter [ "writeBoundary" "privateAppConfigs" ] ''
  export ORION_SEED_FILES=${
    lib.escapeShellArg (builtins.toJSON (lib.mapAttrs (_: source: toString source) files))
  }
  run ${pkgs.python3}/bin/python3 - <<'PY'
  import json, os, pathlib
  home = pathlib.Path.home()
  for relative, source in json.loads(os.environ["ORION_SEED_FILES"]).items():
      target = home / relative
      if target.exists() or target.is_symlink():
          continue
      # Do not seed through a redirected application directory.
      parent = home
      redirected = False
      for part in pathlib.PurePosixPath(relative).parts[:-1]:
          parent /= part
          if parent.is_symlink():
              redirected = True
              break
      if redirected:
          continue
      target.parent.mkdir(parents=True, exist_ok=True)
      try:
          with target.open("xb") as output:
              os.chmod(target, 0o600)
              output.write(pathlib.Path(source).read_bytes())
      except FileExistsError:
          pass
  PY
''
