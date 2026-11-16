{ config, lib, pkgs, ... }:
let
  fetchNpmTarball = { pname, version, hash }:
    pkgs.fetchurl {
      url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
      inherit hash;
    };

  # Published tarball plus the host imports it does not bundle.
  # @deepseek-ai/* peers come from the running dsh, not from here.
  dshPlugin = { pname, version, hash, runtime ? [ ] }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = fetchNpmTarball { inherit pname version hash; };
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        dest=$out/share/dsh/plugins/${pname}
        mkdir -p "$dest"
        cp -a . "$dest"
        ${lib.concatMapStrings (dep: ''
          mkdir -p "$dest/node_modules/${dep.pname}"
          tar -xzf ${dep.src} -C "$dest/node_modules/${dep.pname}" --strip-components=1
        '') runtime}
        runHook postInstall
      '';
    };

  ws = fetchNpmTarball {
    pname = "ws";
    version = "8.23.0";
    hash = "sha512-wCkmX8QMOrKjgO8HW2WyDbTSGeqkocxgDzS9iR79rEAexty6/2qzilx3Ag8Tqf9ykop3irLKle0MtVn5qjVnoQ==";
  };
  yaml = fetchNpmTarball {
    pname = "yaml";
    version = "2.9.1";
    hash = "sha512-3NxN8+78OdzbT7C/WjGsyfPAtJaN3FNDsWxv7Y7mcDsT/oOmgW8BpyQQFFBnvZE3j9Y2Sdz1ULFLezL7Eb2yFw==";
  };
  zod = fetchNpmTarball {
    pname = "zod";
    version = "4.6.7";
    hash = "sha512-g8W2D2kU6a8untc053fX1uVBKzM7yqAxW/3zwk83+6RyF2+SKOuV+c0wBDhUwzV1PaGapmZH+rmcUzPf+3CGwg==";
  };

  dshBetterSidebar = dshPlugin {
    pname = "dsh-better-sidebar";
    version = "0.32.0";
    hash = "sha512-DtMJTQ1+uW8zXrSyxAoGcTn9mFGZQlLO5QUwOpmLI7u4Lz5zl9qQeohZFqJoIdbWDsxGmXCnEjbeUiKkfOnzFg==";
    runtime = [
      { pname = "ws"; src = ws; }
      { pname = "yaml"; src = yaml; }
    ];
  };
  dshContext = dshPlugin {
    pname = "dsh-context";
    version = "0.85.1";
    hash = "sha512-M0Ycbx86SQF19HYRe7zlfsvagtkVGInFUDSZ9je8ti1aSQbxwoECKk0xDd5YcbUCgJLZXMWAgEx61tE0tCkSPA==";
    runtime = [ { pname = "zod"; src = zod; } ];
  };
  dshCostMeter = dshPlugin {
    pname = "dsh-cost-meter";
    version = "1.9.70";
    hash = "sha512-d3Qfk1h71QUL1liBsX9iURbx5gqi8MzP9WJj+T3EsHNAZO+MCrCUmaqT2H1PgSklrIxY8OR2whfHYEtqHCIpAw==";
  };

  dshCommunityPlugins = [
    {
      name = "dsh-better-sidebar";
      path = "${dshBetterSidebar}/share/dsh/plugins/dsh-better-sidebar";
    }
    {
      name = "dsh-context";
      path = "${dshContext}/share/dsh/plugins/dsh-context";
    }
    {
      name = "dsh-cost-meter";
      path = "${dshCostMeter}/share/dsh/plugins/dsh-cost-meter";
    }
  ];
  dshCommunityPluginManifest = pkgs.writeText "dsh-community-plugins.json" (builtins.toJSON dshCommunityPlugins);
in
{
  options.orion.packages.unstable = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Packages from nixpkgs-unstable when nixos-26.05 is missing or older.";
  };

  config = {
  nixpkgs.config.allowUnfree = true;
  # Local expressions in pkgs/. Orion does not install them from here.
  nixpkgs.overlays = [
    (import ../overlay.nix)
  ];
  # yakkhini.dingtalk 9.0.0.261105002 bundles OpenSSL 1.1 (EOL). The package
  # matches the installed client, so this one name is permitted.
  nixpkgs.config.permittedInsecurePackages = [
    "dingtalk-9.0.0.261105002"
  ];

  programs.firefox = {
    enable = true;
    languagePacks = [ "zh-CN" ];
  };

  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    gh
    wget
    curl
    rsync
    rclone
    unzip
    p7zip
    htop
    btop
    fastfetch
    fzf
    lsd
    neovim
    helix
    micro
    ranger
    nano
    cmake
    gnumake
    gdb
    gfortran
    pkg-config
    ninja
    nodejs
    bubblewrap
    python3
    conda
    jdk
    (python3.withPackages (
      ps: with ps; [
        pip
        fastapi
        matplotlib
        pillow
        reportlab
        scikit-learn
        scipy
        seaborn
      ]
    ))
    vlc
    obs-studio
    keepassxc
    telegram-desktop
    discord
    obsidian
    google-chrome
    microsoft-edge
    vscode
    heroic
    libreoffice-qt
    nur.repos.freegoxing.baidunetdisk
    nur.repos.yakkhini.dingtalk
    nur.repos.novel2430.wpsoffice-365
    todesk
    typst
    pandoc
    jetbrains.idea
    jetbrains.pycharm
    btrfs-progs
    compsize
    ntfs3g
    exfatprogs
    dosfstools
    e2fsprogs
    xfsprogs
    cryptsetup
    lvm2
    mdadm
    dmidecode
    usbutils
    pciutils
    powertop
    acpi
    config.boot.kernelPackages.cpupower
    inxi
    alsa-utils
    ffmpeg
    libdvdcss
    mesa-demos
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    openrgb
    logiops
    mariadb
    nfs-utils
    samba
    papirus-icon-theme
    xdg-utils
    xterm
    udiskie
    pipx
    shfmt
    tokei
    marksman
    bash-language-server
    universal-ctags
  ] ++ config.orion.packages.unstable ++ [
    dshBetterSidebar # 网页侧栏：文件树、编辑器和终端
    dshContext # 上下文构成面板，不压缩上下文
    dshCostMeter # 会话费用和订阅额度
  ];

  # Home-manager module, so lib.hm exists. Links the pinned plugins into the
  # web profile without replacing bundles the user already has.
  home-manager.users.jimmywang0417 = { lib, ... }: {
    home.activation.dshCommunityPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export DSH_PLUGIN_MANIFEST=${dshCommunityPluginManifest}
      ${pkgs.python3}/bin/python3 - <<'PY'
      import json, os, pathlib, shutil
      profile = pathlib.Path.home() / ".dsh" / "profiles" / "web"
      modules = profile / "node_modules"
      modules.mkdir(parents=True, exist_ok=True)
      plugins = json.loads(pathlib.Path(os.environ["DSH_PLUGIN_MANIFEST"]).read_text())
      manifest_path = profile / "package.json"
      if manifest_path.exists():
          manifest = json.loads(manifest_path.read_text())
      else:
          manifest = {
              "name": "dsh-profile-web",
              "private": True,
              "dependencies": {},
              "dsh": {"profile": {"bundles": [
                  "@deepseek-ai/dsh-base",
                  "@deepseek-ai/dsh-web-app",
              ]}},
          }
      dependencies = manifest.setdefault("dependencies", {})
      bundles = manifest.setdefault("dsh", {}).setdefault("profile", {}).setdefault("bundles", [
          "@deepseek-ai/dsh-base",
          "@deepseek-ai/dsh-web-app",
      ])
      for plugin in plugins:
          name, path = plugin["name"], plugin["path"]
          dependencies[name] = "link:" + path
          link = modules / name
          if link.is_symlink() or link.is_file():
              link.unlink()
          elif link.exists():
              shutil.rmtree(link)
          link.symlink_to(path)
          if name not in bundles:
              bundles.append(name)
      manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
      patch = profile / "cordis.patch.yml"
      if not patch.exists():
          patch.write_text(
              "# Your patch layer for this dsh profile, applied after every bundle layer:\n"
              "# a top-level YAML array of loader patch entries (id-targeted config\n"
              "# overrides, disables, and insert lists; `!!js` expressions allowed).\n"
              "[]\n"
          )
      workspace = profile / "pnpm-workspace.yaml"
      if not workspace.exists():
          workspace.write_text("packages:\n - .\n\nnodeLinker: hoisted\nautoInstallPeers: false\n")
      PY
    '';
  };
  };
}
