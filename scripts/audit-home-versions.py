#!/usr/bin/env python3
"""Read-only upstream audit of Home Manager, fonts, platforms and runtime plugins.

Run with one or more Nix-exported baseline metadata inventories. Pass
--after FINAL.json to attach evaluated post-migration versions. No packages
are installed or updated. Unresolvable upstream checks remain explicitly unknown.
"""

import concurrent.futures
import datetime
import functools
import json
import pathlib
import re
import sys
import subprocess
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
TIMEOUT = 18
HEADERS = {"User-Agent": "nixos-config-version-audit/1.0"}
OWN_SYSTEM_NAMES = {
    "X11-fonts",
    "fallback-cursor-theme",
    "fontconfig",
    "kio5-plugins-only",
    "nvidia-offload",
    "nvidia-settings",
    "sound-theme-freedesktop",
}


def request(url, body=None, headers=None):
    # curl's total transfer deadline also bounds responses that keep sending
    # partial data; a socket timeout alone does not bound those responses.
    cmd = [
        "curl",
        "--fail",
        "--silent",
        "--show-error",
        "--location",
        "--max-time",
        str(TIMEOUT),
        "--write-out",
        "\n%{url_effective}",
        url,
    ]
    for key, value in (HEADERS | (headers or {})).items():
        cmd += ["--header", key + ": " + value]
    if body is not None:
        cmd += ["--data-binary", "@-"]
    result = subprocess.run(
        cmd,
        input=body,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=TIMEOUT + 3,
    )
    if result.returncode:
        raise ValueError(result.stderr.decode().strip())
    content, resolved = result.stdout.decode().rsplit("\n", 1)
    return resolved, content


def get_json(url):
    return json.loads(request(url)[1])


def normalized(version):
    version = str(version)
    if version.startswith("version_"):
        version = version[len("version_") :].replace("_", ".")
    version = re.sub(r"^(?:rust-v|microcode-|v|release[-_]?|V)", "", version)
    return re.sub(r"(?<=\d)R$", "", version)


def numeric(version):
    v = normalized(version)
    if not re.fullmatch(r"\d+(?:\.\d+)*(?:-\d+)?", v):
        return None
    return tuple(int(x) for x in re.split(r"[.-]", v))


def comparison(before, upstream):
    if normalized(before) == normalized(upstream):
        return "current"
    a, b = numeric(before), numeric(upstream)
    if a and b:
        if a < b:
            return "behind"
        if a > b:
            return "newer-or-different-release-line"
    return "different-version-needs-review"


REPOS = {
    "oh-my-zsh": "ohmyzsh/ohmyzsh",
    "vscode": "microsoft/vscode",
    "mediainfo": "MediaArea/MediaInfo",
    "libreelec-dvb-firmware": "LibreELEC/dvb-firmware",
    "microcode-intel": "intel/Intel-Linux-Processor-Microcode-Data-Files",
    "ffmpegthumbnailer": "dirkvdb/ffmpegthumbnailer",
    "libarchive": "libarchive/libarchive",
    "imagemagick": "ImageMagick/ImageMagick",
    "nix-zsh-completions": "nix-community/nix-zsh-completions",
    "ranger": "ranger/ranger",
    "neovim": "neovim/neovim",
    "lsd": "lsd-rs/lsd",
    "powerlevel10k": "romkatv/powerlevel10k",
    "tela-icon-theme": "vinceliuice/Tela-icon-theme",
    "whitesur-kde": "vinceliuice/WhiteSur-kde",
    "endeavouros-wallpapers": "endeavouros-team/Branding",
    "endeavouros-community-wallpapers": "EndeavourOS-Community-Editions/Community-wallpapers",
    "noto-fonts-color-emoji": "googlefonts/noto-emoji",
    "source-sans-pro": "adobe-fonts/source-sans",
    "liberation-fonts": "liberationfonts/liberation-fonts",
    "inconsolata": "googlefonts/Inconsolata",
    "rt5677-firmware": "raphael/linux-samus",
    "rtl8761b-firmware": "Realtek-OpenSource/android_hardware_realtek",
    "rtl8192su-firmware": "chunkeey/rtl8192su",
    "sof-firmware": "thesofproject/sof-bin",
    "hack-font": "source-foundry/Hack",
    "noto-fonts-cjk-sans": "notofonts/noto-cjk",
    "noto-fonts-cjk-serif": "notofonts/noto-cjk",
    "dejavu-fonts": "dejavu-fonts/dejavu-fonts",
    "ttf-ms-win10": "streetsamurai00mi/ttf-ms-win10",
}


def github_latest(repo):
    url = f"https://github.com/{repo}/releases/latest"
    resolved, text = request(url)
    m = re.search(r"/releases/tag/([^/?#]+)", resolved)
    if not m:
        raise ValueError("No official non-prerelease GitHub release redirect")
    return urllib.parse.unquote(m.group(1)), resolved


def extension_ids():
    text = (ROOT / "home/modules/editors/vscode.nix").read_text()
    return re.findall(
        r"^\s+(?:unstableUnfree\.vscode-extensions\.)?([\w-]+)\.([\w-]+)\s*$",
        text,
        re.M,
    )


EXT_IDS = extension_ids()


def marketplace(extension_id):
    url = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    payload = {
        "filters": [{"criteria": [{"filterType": 7, "value": extension_id}]}],
        "flags": 65552,
    }
    _, text = request(
        url,
        json.dumps(payload).encode(),
        {
            "Content-Type": "application/json",
            "Accept": "application/json;api-version=7.2-preview.1",
        },
    )
    ext = json.loads(text)["results"][0]["extensions"][0]
    stable = []
    for v in ext.get("versions", []):
        props = {p["key"]: p["value"] for p in v.get("properties", [])}
        if (
            props.get("Microsoft.VisualStudio.Code.PreRelease", "false").lower()
            == "true"
        ):
            continue
        if v.get("targetPlatform", "universal") not in ("universal", "linux-x64"):
            continue
        stable.append(v)
    if not stable:
        raise ValueError("No stable Linux/universal version in Marketplace response")
    return stable[0][
        "version"
    ], f"https://marketplace.visualstudio.com/items?itemName={extension_id}"


PLATFORM_CACHE = {}


@functools.lru_cache(maxsize=12)
def kde_release(family):
    url = "https://download.kde.org/stable/" + family + "/"
    text = request(url)[1]
    versions = re.findall(r'href="(\d+\.\d+(?:\.\d+)?)/"', text)
    if not versions:
        raise ValueError("No stable release found in official KDE directory")
    version = max(versions, key=numeric)
    if family == "frameworks" and version.count(".") == 1:
        version += ".0"
    return version, url


def upstream(row):
    name = row["name"]
    pos = row.get("position", "")
    for path, family in [
        ("/kde/plasma/", "plasma"),
        ("/kde/gear/", "release-service"),
        ("/kde/frameworks/", "frameworks"),
    ]:
        if path in pos:
            return kde_release(family)
    if "/libraries/qt-6/" in pos:
        url = "https://download.qt.io/official_releases/qt/"
        versions = re.findall(r'href="(6\.\d+)/"', request(url)[1])
        if not versions:
            raise ValueError("No official Qt 6 stable release directory")
        track = max(versions, key=numeric)
        versions = re.findall(
            r'href="(' + re.escape(track) + r'\.\d+)/"', request(url + track + "/")[1]
        )
        if not versions:
            raise ValueError("No official Qt 6 stable patch release directory")
        return max(versions, key=numeric), url + track + "/"
    if row["scope"] == "vscode-extension":
        ids = [
            a + "." + b
            for a, b in EXT_IDS
            if row["name"].lower() == ("vscode-extension-" + a + "-" + b).lower()
        ]
        if name == "vscode-extension-rust-analyzer":
            ids = ["rust-lang.rust-analyzer"]
        if not ids:
            raise ValueError(
                "Could not map derivation name to declared Marketplace extension ID"
            )
        return marketplace(ids[0])
    if name in ("noto-fonts-cjk-sans", "noto-fonts-cjk-serif"):
        url = "https://github.com/notofonts/noto-cjk/releases"
        text = request(url)[1]
        prefix = "Sans" if name.endswith("sans") else "Serif"
        versions = re.findall(prefix + r"(\d+\.\d+)", text)
        if not versions:
            raise ValueError("No style-specific stable CJK release found")
        return max(versions, key=numeric), url
    if name in REPOS:
        return github_latest(REPOS[name])
    if name == "linux":
        url = "https://www.kernel.org/releases.json"
        releases = get_json(url)["releases"]
        stable = next(x for x in releases if x["moniker"] == "stable")
        return stable["version"], url
    archive_adapters = {
        "atool": (
            "https://download.savannah.nongnu.org/releases/atool/",
            r"atool-(\d+\.\d+\.\d+)\.tar",
        ),
        "poppler-utils": (
            "https://poppler.freedesktop.org/",
            r"poppler-(\d+\.\d+\.\d+)\.tar",
        ),
        "zsh": ("https://www.zsh.org/pub/", r"zsh-(\d+\.\d+(?:\.\d+)?)\.tar"),
        "man-db": (
            "https://download.savannah.gnu.org/releases/man-db/",
            r"man-db-(\d+\.\d+\.\d+)\.tar",
        ),
        "djvulibre": (
            "https://djvu.sourceforge.net/",
            r"djvulibre-(\d+\.\d+\.\d+)\.tar",
        ),
        "terminus-font": (
            "https://terminus-font.sourceforge.net/",
            r"terminus-font-(\d+\.\d+(?:\.\d+)?)\.tar",
        ),
        "freefont-ttf": (
            "https://ftp.gnu.org/gnu/freefont/",
            r"freefont-ttf-(\d+)\.(?:tar|zip)",
        ),
        "unifont": ("https://unifoundry.com/unifont/", r"unifont-(\d+\.\d+\.\d+)"),
        "sound-theme-freedesktop": (
            "https://people.freedesktop.org/~mccann/dist/",
            r"sound-theme-freedesktop-(\d+\.\d+(?:\.\d+)?)\.tar",
        ),
        "xdg-user-dirs": (
            "https://user-dirs.freedesktop.org/releases/",
            r"xdg-user-dirs-(\d+\.\d+(?:\.\d+)?)\.tar",
        ),
        "kio-fuse": (
            "https://download.kde.org/stable/kio-fuse/",
            r"kio-fuse-(\d+\.\d+\.\d+)\.tar",
        ),
        "phonon-vlc": (
            "https://download.kde.org/stable/phonon/phonon-backend-vlc/",
            r'href="(\d+\.\d+\.\d+)/"',
        ),
        "wireless-regdb": (
            "https://www.kernel.org/pub/software/network/wireless-regdb/",
            r"wireless-regdb-(\d+\.\d+\.\d+)\.tar",
        ),
        "w3m": ("https://git.sr.ht/~rkta/w3m/refs", r'/refs/v(\d+\.\d+\.\d+)["<]'),
    }
    if name in ("font-cursor-misc", "font-misc-misc", "font-alias"):
        archive_adapters[name] = (
            "https://www.x.org/releases/individual/font/",
            re.escape(name) + r"-(\d+\.\d+\.\d+)\.tar",
        )
    if name in archive_adapters:
        url, pattern = archive_adapters[name]
        versions = re.findall(pattern, request(url)[1])
        if not versions:
            raise ValueError(
                "No unambiguous stable tarball/version found in official archive"
            )
        return max(versions, key=numeric), url
    if name in ("shared-mime-info", "fontconfig"):
        project = "1205" if name == "shared-mime-info" else "fontconfig%2Ffontconfig"
        url = (
            "https://gitlab.freedesktop.org/api/v4/projects/"
            + project
            + "/repository/tags?per_page=50"
        )
        versions = [r["name"] for r in get_json(url) if numeric(r["name"])]
        if not versions:
            raise ValueError("No stable project tag from official GitLab")
        return max(versions, key=numeric), url
    if name == "linux-firmware":
        url = "https://gitlab.com/api/v4/projects/kernel-firmware%2Flinux-firmware/repository/tags?per_page=30"
        versions = [
            r["name"] for r in get_json(url) if re.fullmatch(r"\d{8}", r["name"])
        ]
        if not versions:
            raise ValueError("No dated official firmware release tag found")
        return max(versions), url
    if name == "gyre-fonts":
        url = "https://ctan.org/json/2.0/pkg/tex-gyre"
        return get_json(url)["version"]["number"], url
    if name == "alsa-firmware":
        url = "https://www.alsa-project.org/files/pub/firmware/"
        versions = re.findall(
            r"alsa-firmware-(\d+\.\d+(?:\.\d+)?)\.tar", request(url)[1]
        )
        if not versions:
            raise ValueError("No firmware tarball in official ALSA directory")
        return max(versions, key=numeric), url
    if name in ("nvidia-x11", "nvidia-settings"):
        url = "https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt"
        return request(url)[1].split()[0], url
    if name in ("plasma-desktop", "kwin"):
        url = "https://download.kde.org/stable/plasma/"
        text = request(url)[1]
        versions = re.findall(r'href="(\d+\.\d+\.\d+)/"', text)
        if not versions:
            raise ValueError("No stable version found in KDE release directory")
        return max(versions, key=numeric), url
    if name == "mesa":
        url = "https://archive.mesa3d.org/"
        text = request(url)[1]
        versions = re.findall(r"mesa-(\d+\.\d+\.\d+)\.tar", text)
        if not versions:
            raise ValueError("No stable Mesa tarball version found")
        return max(versions, key=numeric), url
    if name == "pay-respects":
        url = "https://codeberg.org/api/v1/repos/iff/pay-respects/releases/latest"
        d = get_json(url)
        return d["tag_name"], d["html_url"]
    homepage = row.get("homepage", "")
    if isinstance(homepage, list):
        homepage = homepage[0] if homepage else ""
    if homepage:
        resolved, text = request(homepage)
        raise ValueError(
            "Official homepage searched successfully ("
            + resolved
            + "); no unambiguous stable-version signal. Manual confirmation required."
        )
    raise ValueError(
        "No reliable upstream homepage or stable-version signal; manual confirmation required"
    )


def audit(row):
    row = dict(row)
    for key in (
        "check_error",
        "note",
        "upstream_version",
        "upstream_url",
        "upstream_track_version",
        "track_status",
    ):
        row.pop(key, None)
    row["baseline_version"] = row.pop("version", "")
    if row["name"] == "ttf-ms-win10":
        row.update(
            status="intentional-release-line",
            upstream_version=None,
            upstream_url="https://github.com/streetsamurai00mi/ttf-ms-win10",
            note="Explicit Windows 10 font snapshot retained by user configuration. No claim it matches current Windows 11 fonts.",
        )
        return row
    if not row["baseline_version"]:
        row.update(
            status="generated-no-independent-release",
            upstream_version=None,
            note="Local wrapper or generated Home Manager artifact; not a separately released upstream application.",
        )
        return row
    try:
        v, url = upstream(row)
        row.update(
            upstream_version=v,
            upstream_url=url,
            status=comparison(row["baseline_version"], v),
        )
        if "unstable-" in row["baseline_version"]:
            row.update(
                status="snapshot-not-comparable",
                note="Nix package uses a source snapshot; the official release tag is not an ordering proof for the pinned commit.",
            )
        if row["name"] == "linux":
            releases = get_json("https://www.kernel.org/releases.json")["releases"]
            track = next(
                (x["version"] for x in releases if x["version"].startswith("6.12.")),
                None,
            )
            row.update(
                status="intentional-release-line",
                upstream_track_version=track,
                track_status=comparison(row["baseline_version"], track)
                if track
                else "unverified",
                note="Host explicitly selects Linux 6.12 LTS. upstream_version is newest stable series; upstream_track_version is the current stable patch of the selected LTS line.",
            )
        if row["name"] == "ttf-ms-win10":
            row.update(
                status="intentional-release-line",
                note="Configured Windows 10 font snapshot is intentionally retained; no claim it matches Windows 11/current proprietary fonts.",
            )
    except Exception as e:
        homepage = row.get("homepage", "")
        if isinstance(homepage, list):
            homepage = homepage[0] if homepage else ""
        if row["name"] in REPOS:
            homepage = "https://github.com/" + REPOS[row["name"]] + "/releases/latest"
        row.update(
            upstream_version=None,
            status="unverified",
            upstream_url=homepage or None,
            check_error=str(e),
            note=str(e),
        )
        if (
            row["name"] in ("oh-my-zsh", "ranger", "noto-fonts")
            or "unstable-" in row["baseline_version"]
        ):
            row.update(
                status="snapshot-not-comparable",
                note=str(e)
                + " The package uses a source snapshot or aggregate; no single stable release comparison was verified.",
            )
    return row


def npm_plugin(name, scope):
    url = "https://registry.npmjs.org/" + urllib.parse.quote(name, safe="") + "/latest"
    row = {
        "name": name,
        "scope": scope,
        "baseline_version": None,
        "status": "runtime-unpinned",
        "upstream_url": url,
        "note": "Installed by activation/plugin manager when missing; no installed version or revision is locked by this flake. Existing installations are not automatically upgraded by a Nix input update.",
    }
    try:
        d = get_json(url)
        row["upstream_version"] = d["version"]
        row["upstream_version_kind"] = (
            "npm latest dist-tag (may itself point to a prerelease)"
        )
        row["engines"] = d.get("engines", {})
        row["peerDependencies"] = d.get("peerDependencies", {})
    except Exception as e:
        row.update(upstream_version=None, check_error=str(e))
    return row


def runtime_rows():
    plugin_root = ROOT / "modules/programs/dsh/plugins"
    manifests = re.findall(
        r"\./([a-z-]+\.nix)", (plugin_root / "default.nix").read_text()
    )
    dsh = [
        name
        for filename in manifests
        for name in re.findall(
            r'^\s+"([^"\n]+)"', (plugin_root / filename).read_text(), re.M
        )
    ]
    coc = re.findall(r"'(coc-[^']+)'", (ROOT / "home/nvim/coc.vim").read_text())
    tasks = [(n, "dsh-plugin") for n in dsh] + [(n, "coc-extension") for n in coc]
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
        rows = list(pool.map(lambda p: npm_plugin(*p), tasks))
    for repo in re.findall(
        r"^Plug '([^']+)'", (ROOT / "home/nvim/plugins.vim").read_text(), re.M
    ):
        rows.append(
            {
                "name": repo,
                "scope": "vim-plugin",
                "baseline_version": None,
                "upstream_version": None,
                "status": "runtime-unpinned",
                "upstream_url": "https://github.com/" + repo,
                "note": "vim-plug installs only when missing; flake locks no revision. coc.nvim uses its release branch, other declarations default branch. No installed revision was inspected.",
            }
        )
    rows.append(
        {
            "name": "junegunn/vim-plug",
            "scope": "vim-plugin-manager",
            "baseline_version": None,
            "upstream_version": None,
            "status": "runtime-unpinned",
            "upstream_url": "https://github.com/junegunn/vim-plug",
            "note": "Downloaded from master if plug.vim is missing; no revision pinned.",
        }
    )
    return rows


def attach_after(data, inventory):
    by_name = {}
    for r in inventory:
        by_name.setdefault(r["name"], []).append(r)
    status_alias = {
        "current": "equal",
        "newer-or-different-release-line": "ahead-or-different-track",
    }
    for row in data["rows"]:
        row["version"] = row.get("baseline_version")
        runtime = row["status"] == "runtime-unpinned"
        row["official_stable_version"] = (
            None if runtime else row.get("upstream_version")
        )
        row["upstream_status"] = status_alias.get(row["status"], row["status"])
        row["sources"] = (
            [
                {
                    "url": row["upstream_url"],
                    "method": "official upstream release/registry query",
                    "error": row.get("check_error"),
                }
            ]
            if row.get("upstream_url")
            else []
        )
        row["notes"] = row.get("note", "")
        candidates = by_name.get(row["name"], [])
        match = next(
            (r for r in candidates if r["scope"] == row["scope"]),
            candidates[0] if candidates else None,
        )
        if runtime:
            row["after_version"] = None
            row["after_upstream_status"] = "runtime-unpinned"
        elif match:
            row["after_version"] = match.get("version", "")
            row["after_position"] = match.get("position", "")
            row["after_upstream_status"] = (
                status_alias.get(
                    comparison(row["after_version"], row["upstream_version"]),
                    comparison(row["after_version"], row["upstream_version"]),
                )
                if row.get("upstream_version")
                else row["upstream_status"]
            )
            if row["status"] in (
                "intentional-release-line",
                "snapshot-not-comparable",
                "generated-no-independent-release",
            ):
                row["after_upstream_status"] = row["upstream_status"]
            if row.get("upstream_track_version"):
                row["after_track_status"] = comparison(
                    row["after_version"], row["upstream_track_version"]
                )
        else:
            row["after_version"] = None
            row["after_upstream_status"] = (
                "absent-or-renamed-in-final-inventory" if inventory else "not-assessed"
            )
    return data


def main():
    args = sys.argv[1:]
    after = []
    if "--after" in args:
        index = args.index("--after")
        after = json.load(open(args[index + 1]))
        args = args[:index]
    inventory = []
    for filename in args:
        inventory.extend(json.load(open(filename)))
    for i, r in enumerate(inventory):
        if (
            "/kde/" in r.get("position", "")
            or "/libraries/qt-6/" in r.get("position", "")
            or r["name"] in OWN_SYSTEM_NAMES
        ):
            r = dict(r)
            r["scope"] = "desktop"
            inventory[i] = r
    rows = []
    seen = set()
    for r in inventory:
        if r["scope"] not in (
            "home",
            "font",
            "vscode-extension",
            "hardware",
            "desktop",
            "firmware",
        ):
            continue
        key = (r["scope"], r["name"], r.get("version", ""))
        if key in seen:
            continue
        seen.add(key)
        rows.append(r)
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
        audited = []
        for item in pool.map(audit, rows):
            audited.append(item)
            print(item["scope"], item["name"], item["status"], flush=True)
    # Include modules newly introduced by migration, while preserving a null
    # baseline so they cannot inflate the number of previously old packages.
    known = {(r["scope"], r["name"]) for r in audited}
    additions = []
    for raw in after:
        row = dict(raw)
        if (
            "/kde/" in row.get("position", "")
            or "/libraries/qt-6/" in row.get("position", "")
            or row["name"] in OWN_SYSTEM_NAMES
        ):
            row["scope"] = "desktop"
        if row["scope"] not in (
            "home",
            "font",
            "vscode-extension",
            "hardware",
            "desktop",
            "firmware",
        ):
            continue
        key = (row["scope"], row["name"])
        if key not in known:
            known.add(key)
            additions.append(row)
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
        for row in pool.map(audit, additions):
            row["baseline_version"] = None
            row["status"] = "not-in-baseline"
            audited.append(row)
    audited += runtime_rows()
    out = {
        "checked_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "scope": "Home Manager packages, fonts, VS Code extensions, kernel/NVIDIA/desktop platform and declared runtime plugins; no transitive dependency audit.",
        "method": "Official release pages/APIs and registries only. Runtime-unpinned and unverified entries are not counted as current. Nix baseline metadata exported before migration.",
        "rows": audited,
    }
    dest = ROOT / "inventory/software-versions-home.json"
    dest.write_text(
        json.dumps(attach_after(out, after), ensure_ascii=False, indent=2) + "\n"
    )
    from collections import Counter

    print(len(audited), Counter(r["status"] for r in audited))


if __name__ == "__main__":
    main()
