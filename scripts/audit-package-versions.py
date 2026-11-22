#!/usr/bin/env python3
"""Compare evaluated software inventories with authoritative release endpoints.

The input is JSON emitted by Nix (name/version/homepage/position/scope). This is
an inventory audit, not a dependency updater. Unknown and non-comparable versions
remain explicit; neither nixpkgs-unstable nor a successful HTTP request implies
that a package is current. HTTP responses are cached for reproducibility.
"""
from __future__ import annotations
import argparse, concurrent.futures, datetime, json, pathlib, re, threading, urllib.error, urllib.parse, urllib.request

GITHUB = {
 'cmake':'Kitware/CMake', 'git-lfs':'git-lfs/git-lfs', 'gh':'cli/cli', 'rclone':'rclone/rclone',
 'htop':'htop-dev/htop', 'neovim':'neovim/neovim', 'helix':'helix-editor/helix',
 'micro':'zyedidia/micro', 'ranger':'ranger/ranger', 'ninja':'ninja-build/ninja',
 'conda-shell':'conda/conda', 'obs-studio':'obsproject/obs-studio',
 'keepassxc':'keepassxreboot/keepassxc', 'telegram-desktop':'telegramdesktop/tdesktop',
 'obsidian':'obsidianmd/obsidian-releases', 'pandoc-cli':'jgm/pandoc',
 'btrfs-progs':'kdave/btrfs-progs', 'inxi':'smxi/inxi', 'universal-ctags':'universal-ctags/ctags',
 'docker':'moby/moby', 'systemd':'systemd/systemd', 'nix':'NixOS/nix',
 'cups':'OpenPrinting/cups', 'avahi':'avahi/avahi', 'fwupd':'fwupd/fwupd',
 'flatpak':'flatpak/flatpak', 'zstd':'facebook/zstd', 'xz':'tukaani-project/xz',
 'strace':'strace/strace', 'kbd':'legionus/kbd', 'openresolv':'NetworkConfiguration/openresolv',
 'efm-langserver':'mattn/efm-langserver',
 'speech-dispatcher':'brailcom/speechd', 'age':'FiloSottile/age', 'sops':'getsops/sops',
 'logrotate':'logrotate/logrotate', 'xdg-desktop-portal':'flatpak/xdg-desktop-portal',
 'xdg-desktop-portal-gtk':'flatpak/xdg-desktop-portal-gtk',
 'inxi':'smxi/inxi', 'clang-tools':'llvm/llvm-project',
 'iverilog':'steveicarus/iverilog', 'verible':'chipsalliance/verible',
 'rustc':'rust-lang/rust', 'rustc-wrapper':'rust-lang/rust', 'cargo':'rust-lang/cargo', 'rustfmt':'rust-lang/rustfmt',
 'nerd-fonts-hack':'ryanoasis/nerd-fonts',
}
PYPI = {'pip','fastapi','matplotlib','pillow','reportlab','scikit-learn','scipy','seaborn','black','pipx'}
NPM = {'bash-language-server':'bash-language-server'}
GNU = {'wget':'wget','gnumake':'make','gdb':'gdb','nano':'nano','mtools':'mtools',
 'coreutils-full':'coreutils','cpio':'cpio','diffutils':'diffutils','findutils':'findutils',
 'gawk':'gawk','gnugrep':'grep','patch':'patch','gnused':'sed','gnutar':'tar',
 'gzip':'gzip','ncurses':'ncurses','time':'time','which':'which','texinfo-interactive':'texinfo',
 'bash-interactive':'bash','grub2':'grub','grub':'grub'}
SPECIAL = {'typora':'The selected package is a deliberate Typora 0.11.18 plus plugin composition; compare the application and plugin separately.',
 'trae-cn':'The package version is an internal build number, not the displayed application release.',
 'deveco-studio':'Conditional authenticated Huawei download; pure evaluation does not install it.',
 'docker-easyconnect':'Pinned container image composition, not a conventional package release.',
 'p7zip':'Legacy p7zip fork; latest upstream 7-Zip is a different project and not directly comparable.',
 'cpupower':'Tracks the deliberately selected Linux 6.12 kernel branch.',
 'pkg-config-wrapper':'The declared project is pkg-config; pkgconf is a different implementation.',
 'dingtalk':'Official Linux download redirect did not expose a verifiable latest stable version (HTTP403); web asset versions are not client versions.',
 'workbuddy':'Official product/download pages did not expose unambiguous latest Linux version metadata.',
 'wpsoffice-365':'Official product page did not expose unambiguous latest Linux client version metadata.',
 'baidunetdisk':'Official download page did not expose unambiguous latest Linux client version metadata.',
}

ARCHIVES = {
 'samba':('https://download.samba.org/pub/samba/stable/','samba'),
 'nfs-utils':('https://www.kernel.org/pub/linux/utils/nfs-utils/','nfs-utils'),
 'iproute2':('https://www.kernel.org/pub/linux/utils/net/iproute2/','iproute2'),
 'kmod':('https://www.kernel.org/pub/linux/utils/kernel/kmod/','kmod'),
 'mdadm':('https://www.kernel.org/pub/linux/utils/raid/mdadm/','mdadm'),
 'alsa-utils':('https://www.alsa-project.org/files/pub/utils/','alsa-utils'),
 'mesa-demos':('https://archive.mesa3d.org/demos/','mesa-demos'),
 'libcap':('https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/','libcap'),
 'glibc':('https://ftp.gnu.org/gnu/glibc/','glibc'),
 'glibc-locales':('https://ftp.gnu.org/gnu/glibc/','glibc'),
 'zsh':('https://www.zsh.org/pub/','zsh'),
 'sudo':('https://www.sudo.ws/dist/','sudo'),
 'lvm2':('https://sourceware.org/pub/lvm2/releases/','LVM2'),
 'xfsprogs':('https://www.kernel.org/pub/linux/utils/fs/xfs/xfsprogs/','xfsprogs'),
 'bluez':('https://www.kernel.org/pub/linux/bluetooth/','bluez'),
 'kexec-tools':('https://www.kernel.org/pub/linux/utils/kernel/kexec/','kexec-tools'),
 'dbus':('https://dbus.freedesktop.org/releases/dbus/','dbus'),
 'cups-pk-helper':('https://www.freedesktop.org/software/cups-pk-helper/releases/','cups-pk-helper'),
 'udisks':('https://www.freedesktop.org/software/udisks/','udisks'),
 'upower':('https://upower.freedesktop.org/releases/','upower'),
 'accountsservice':('https://www.freedesktop.org/software/accountsservice/','accountsservice'),
 'shared-mime-info':('https://www.freedesktop.org/software/shared-mime-info/','shared-mime-info'),
 'xdg-utils':('https://www.freedesktop.org/software/xdg-utils/','xdg-utils'),
 'less':('https://www.greenwoodsoftware.com/less/download.html','less'),
 'libressl':('https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/','libressl'),
 'openssh':('https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/','openssh'),
 'bzip2':('https://sourceware.org/pub/bzip2/','bzip2'),
 'dmidecode':('https://download.savannah.gnu.org/releases/dmidecode/','dmidecode'),
 'pciutils':('https://mj.ucw.cz/download/linux/pci/','pciutils'),
 'usbutils':('https://www.kernel.org/pub/linux/utils/usb/usbutils/','usbutils'),
 'xterm':('https://invisible-island.net/archives/xterm/','xterm'),
 'colord':('https://www.freedesktop.org/software/colord/releases/','colord'),
 'pavucontrol':('https://freedesktop.org/software/pulseaudio/pavucontrol/','pavucontrol'),
 'mesa':('https://archive.mesa3d.org/','mesa'),
 'wireless-regdb':('https://www.kernel.org/pub/software/network/wireless-regdb/','wireless-regdb'),
 'hicolor-icon-theme':('https://icon-theme.freedesktop.org/releases/','hicolor-icon-theme'),
 'xdg-user-dirs':('https://user-dirs.freedesktop.org/releases/','xdg-user-dirs'),
 'acl':('https://download.savannah.gnu.org/releases/acl/','acl'),
 'attr':('https://download.savannah.gnu.org/releases/attr/','attr'),

}
for _name in ('xrandr','xrdb','setxkbmap','iceauth','xlsclients','xset','xsetroot','xinput','xprop','xauth'):
 ARCHIVES[_name]=('https://www.x.org/releases/individual/app/',_name)
for _name in ('xf86-input-evdev','xf86-input-libinput'):
 ARCHIVES[_name]=('https://www.x.org/releases/individual/driver/',_name)
for _name in ('xorg-server','xwayland'):
 ARCHIVES[_name]=('https://www.x.org/releases/individual/xserver/',_name)
for _name in ('gstreamer','gst-plugins-base','gst-plugins-good','gst-plugins-bad','gst-plugins-ugly','gst-libav'):
 ARCHIVES[_name]=(f'https://gstreamer.freedesktop.org/src/{_name}/',_name)
GNOME = {'networkmanager':'NetworkManager','gvfs':'gvfs','dconf':'dconf','at-spi2-core':'at-spi2-core','orca':'orca',
 'glib':'glib', 'gtk+3':'gtk+', 'gnome-themes-extra':'gnome-themes-extra',
 'adwaita-icon-theme':'adwaita-icon-theme','gnome-keyring':'gnome-keyring','network-manager-applet':'network-manager-applet',
 'NetworkManager-openvpn':'NetworkManager-openvpn','NetworkManager-openconnect':'NetworkManager-openconnect'}
NESTED_ARCHIVES = {
 'util-linux':('https://www.kernel.org/pub/linux/utils/util-linux/','util-linux'),
 'cryptsetup':('https://www.kernel.org/pub/linux/utils/cryptsetup/','cryptsetup'),
 'e2fsprogs':('https://www.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/','e2fsprogs'),
 'libdvdcss':('https://download.videolan.org/pub/libdvdcss/','libdvdcss'),
 'nfs-utils':('https://www.kernel.org/pub/linux/utils/nfs-utils/','nfs-utils'),
 'bind':('https://downloads.isc.org/isc/bind9/','bind'),
}

PAGE_RULES = {'git': {'name': 'git',
         'version': '2.56.1',
         'url': 'https://git-scm.com/',
         'method': 'Git homepage latest release version span',
         'pattern': '<span class="version">([0-9.]+)</span>',
         'notes': ''},
 'curl': {'name': 'curl',
          'version': '8.23.0',
          'url': 'https://curl.se/download.html',
          'method': 'Official download version table',
          'pattern': '<b>curl ([0-9.]+)</b>',
          'notes': ''},
 'ffmpeg': {'name': 'ffmpeg',
            'version': '9.0.2',
            'url': 'https://ffmpeg.org/download.html',
            'method': 'Latest numbered release heading on official FFmpeg page',
            'pattern': '<h3 id="release_[^"]+">FFmpeg ([0-9.]+)',
            'notes': '8.1.3 is current within its retained 8.1 series; latest release series is '
                     'read dynamically from the current official release page.'},
 'libreoffice': {'name': 'libreoffice',
                 'version': '26.8.3',
                 'url': 'https://download.documentfoundation.org/libreoffice/stable/',
                 'method': 'Greatest numeric directory in official stable archive',
                 'pattern': 'href="([0-9]+\\.[0-9]+\\.[0-9]+)/"',
                 'notes': '25.8 branch differs from latest stable series; stable archive retains '
                          '25.8.7 as well.'},
 'gfortran-wrapper': {'name': 'gfortran-wrapper',
                      'version': '16.2.0',
                      'url': 'https://gcc.gnu.org/releases.html',
                      'method': 'Greatest GCC release in official releases table (GCC 16.2 is '
                                'tarball 16.2.0)',
                      'pattern': 'GCC ([0-9]+\\.[0-9]+)',
                      'notes': '15.3.0 is current in the retained GCC 15 branch; major 16 is '
                               'available.'},
 'python3': {'name': 'python3',
             'version': '3.15.2',
             'url': 'https://www.python.org/downloads/source/',
             'method': 'Greatest stable numeric Python release in source download entries',
             'pattern': '>Python ([0-9]+\\.[0-9]+\\.[0-9]+) - ',
             'notes': 'Same-series 3.13 latest is 3.13.18; latest full series is 3.15.2.'},
 'vlc': {'name': 'vlc',
         'version': '3.0.24',
         'url': 'https://www.videolan.org/vlc/',
         'method': 'Linux latestVersion field in official homepage PLATFORMS JSON',
         'pattern': '"linux":\\{"name":"Linux","latestVersion":"([0-9.]+)"',
         'notes': 'Do not compare with Android/iOS version 3.7.0.'},
 'openjdk': {'name': 'openjdk',
             'version': '27.0.1.1',
             'url': 'https://jdk.java.net/27/',
             'method': 'Oracle OpenJDK JDK 27 production download tarball version',
             'pattern': 'openjdk-([0-9]+(?:\\.[0-9]+)+)_',
             'notes': 'Configured JDK 21 is an LTS branch. OpenJDK jdk21u tags include '
                      'refs/tags/jdk-21.0.13-ga, refs/tags/jdk-21.0.13.0.2-ga, '
                      'refs/tags/jdk-21.0.13.0.3-ga, refs/tags/jdk-21.0.13.1-ga. Latest overall GA '
                      'is 27.0.1.1; Oracle separately publishes JDK21 21.0.13.1 but vendor build '
                      'suffixes are not interchangeable.',
             'same_series_source': 'https://api.github.com/repos/openjdk/jdk21u/git/matching-refs/tags/jdk-21.0.13'},
 'gcc': {'name': 'gcc',
         'version': '16.2.0',
         'url': 'https://gcc.gnu.org/releases.html',
         'method': 'Greatest GCC release in official releases table (GCC 16.2 is tarball 16.2.0)',
         'pattern': 'GCC ([0-9]+\\.[0-9]+)',
         'notes': '15.3.0 is current in the retained GCC 15 branch; major 16 is available.'},
 'rsync': {'url': 'https://rsync.samba.org/',
           'pattern': 'Rsync version ([0-9.]+) released',
           'method': 'official current release announcement'},
 'wpa_supplicant': {'url': 'https://w1.fi/wpa_supplicant/',
                    'pattern': 'wpa_supplicant-([0-9.]+)\\.tar\\.gz',
                    'method': 'official release download link'},
 'openrgb': {'url': 'https://openrgb.org/',
             'pattern': '/releases/download/release_([0-9.]+)/',
             'method': 'official release download link'},
 'perl': {'url': 'https://www.perl.org/',
          'pattern': '([0-9]+\\.[0-9]+\\.[0-9]+)\\s*</[^>]+>\\s*<[^>]+[^>]*>\\s*Download',
          'method': 'official latest stable homepage download'},
 'todesk': {'url': 'https://www.todesk.com/linux.html',
            'pattern': 'linux_version:"([0-9.]+)"',
            'method': 'official Linux mainstream clientInfo.linux_version (excluding gray rollout '
                      'links)',
            'notes': 'Vendor gray-rollout links are not the mainstream stable channel; Linux Arch '
                     'archive is independently older.'}}

PAGE_RULES['gcc-wrapper'] = dict(PAGE_RULES['gcc'], name='gcc-wrapper')

GITLAB = {
 'networkmanager':('gitlab.freedesktop.org','NetworkManager/NetworkManager'),
 'modemmanager':('gitlab.freedesktop.org','mobile-broadband/ModemManager'),
 'upower':('gitlab.freedesktop.org','upower/upower'),
 'shared-mime-info':('gitlab.freedesktop.org','xdg/shared-mime-info'),
 'power-profiles-daemon':('gitlab.freedesktop.org','upower/power-profiles-daemon'),
 'bolt':('gitlab.freedesktop.org','bolt/bolt'),
 'geoclue':('gitlab.freedesktop.org','geoclue/geoclue'),
 'rtkit':('gitlab.freedesktop.org','pipewire/rtkit'),
 'accountsservice':('gitlab.freedesktop.org','accountsservice/accountsservice'),
 'xdg-utils':('gitlab.freedesktop.org','xdg/xdg-utils'),
 'sane-backends':('gitlab.com','sane-project/backends'),
 'man-db':('gitlab.com','man-db/man-db'),
 'procps':('gitlab.com','procps-ng/procps'),
 'desktop-file-utils':('gitlab.freedesktop.org','xdg/desktop-file-utils'),
}
GITHUB.update({'udisks':'storaged-project/udisks','microcode-intel':'intel/Intel-Linux-Processor-Microcode-Data-Files'})

def gitlab_version(name,cache):
 if name not in GITLAB:return None
 domain,project=GITLAB[name]
 url=f'https://{domain}/api/v4/projects/{urllib.parse.quote(project,safe="")}/repository/tags?per_page=100'
 r=fetch(url,cache);values=[]
 if 'error' not in r:
  try:values=[item['name'] for item in json.loads(r['body'])]
  except (ValueError,KeyError,TypeError):pass
 values=[v for v in values if stable_numeric(v,name)]
 return url,r,max(values,key=numeric) if values else None,'official project tags; numeric non-prerelease tags with project development-series filtering'

def xfce_version(p,cache):
 home=p.get('homepage','');home=' '.join(home) if isinstance(home,list) else home
 if 'xfce.org' not in home:return None
 name=p['name'];category='xfce'
 namespace=re.search(r'xfce\.org/(xfce|apps|panel-plugins|art)/',home)
 if namespace:category=namespace[1]
 source_path=p.get('position','').rsplit(':',1)[0]
 physical=pathlib.Path(source_path)
 if not physical.exists() and source_path.startswith('/nix/store/'):
  physical=pathlib.Path.home()/'.local/share/nix-singleuser/store'/source_path.removeprefix('/nix/store/')
 if physical.is_file():
  text=physical.read_text()
  match=re.search(r'category\s*=\s*"([a-z-]+)"',text) or re.search(r'owner\s*=\s*"(apps|xfce|panel-plugins|art)"',text) or re.search(r'xfce(?:\.org)?/src/(apps|xfce|panel-plugins|art)/',text)
  if match:category=match[1]
 elif '/apps/' in home:category='apps'
 elif '/panel-plugins/' in home:category='panel-plugins'
 url=f'https://archive.xfce.org/src/{category}/{name}/';r=fetch(url,cache)
 dirs=set(re.findall(r'href=[\"\']([0-9]+(?:\.[0-9]+)+)/',r.get('body','')))
 def stable(v):
  parts=numeric(v)
  return parts is not None and not (parts[0]==4 and len(parts)>1 and parts[1]%2)
 values=[]
 for directory in sorted((v for v in dirs if stable(v)),key=numeric,reverse=True)[:2]:
  child=fetch(url+directory+'/',cache)
  values.extend(v for v in archive_versions(child.get('body',''),name) if stable(v))
 return url,r,max(values,key=numeric) if values else None,'official Xfce source-release archive; exclude odd minor development branches in the 4.x desktop series'

def github_tags(repo,cache):
 url=f'https://github.com/{repo}/tags';r=fetch(url,cache)
 values=re.findall(r'/releases/tag/([^"<>?]+)',r.get('body',''))
 values=[urllib.parse.unquote(v) for v in values]
 values=[v for v in values if numeric(v) is not None]
 return url,r,max(values,key=numeric) if values else None

def page_version(name,cache):
 if name not in PAGE_RULES:return None
 rule=PAGE_RULES[name];url=rule['url'];r=fetch(url,cache);value=None
 if 'error' not in r:
  values=re.findall(rule['pattern'],r['body'])
  if values:
   value=max(values,key=numeric)
   if name in {'gcc','gcc-wrapper','gfortran-wrapper'}:value += '.0'
 return url,r,value,rule['method']

def archive_versions(body, project):
 pattern = re.escape(project)+r'[-_.]?([0-9]+(?:\.[0-9]+)*(?:p[0-9]+)?)\.(?:tar\.(?:gz|xz|bz2|zst)|tgz)'
 return set(re.findall(pattern,body,flags=re.IGNORECASE))

def stable_numeric(version, name):
 if numeric(version) is None:return False
 if name=='gtk+3' and numeric(version)[:2] != (3,24):return False
 bits=numeric(version)
 if len(bits)>1 and any(part>=90 for part in bits[2:]):return False
 if name in {'dbus','networkmanager','gvfs','dconf','at-spi2-core','gstreamer','gst-plugins-base','gst-plugins-good','gst-plugins-bad','gst-plugins-ugly','gst-libav','pipewire','glib'} and len(bits)>1 and bits[1]%2:return False
 return True

def archive_version(name, cache):
 if name in GNOME:
  project=GNOME[name];url=f'https://download.gnome.org/sources/{project}/cache.json';r=fetch(url,cache)
  values=[]
  if 'error' not in r:
   try:values=list(json.loads(r['body'])[1][project])
   except (ValueError,KeyError,IndexError):pass
 elif name in ARCHIVES and name not in NESTED_ARCHIVES:
  url,project=ARCHIVES[name];r=fetch(url,cache);values=archive_versions(r.get('body',''),project)
 elif name in NESTED_ARCHIVES:
  url,project=NESTED_ARCHIVES[name];r=fetch(url,cache);values=[]
  dirs=set(re.findall(r'href=[\"\'](v?[0-9]+(?:\.[0-9]+)*)/',r.get('body','')))
  for directory in sorted(dirs,key=lambda v:numeric(v) or (),reverse=True)[:3]:
   nested=fetch(url+directory+'/',cache)
   values.extend(archive_versions(nested.get('body',''),project))
 elif name in {'pipewire','wireplumber'}:
  url=f'https://gitlab.freedesktop.org/api/v4/projects/pipewire%2F{name}/repository/tags?per_page=100';r=fetch(url,cache);values=[]
  if 'error' not in r:
   try:values=[d['name'] for d in json.loads(r['body'])]
   except (ValueError,TypeError,KeyError):pass
 else:return None
 values=[v for v in values if stable_numeric(v,name)]
 value=max(values,key=numeric) if values else None
 method='official project tags; numeric non-prerelease names, with project-specific development-series filtering' if name in {'pipewire','wireplumber'} else 'official source release archive; numeric release tarballs and project-specific stable-series filtering'
 return url,r,value,method

_CACHE_LOCKS = {}
_CACHE_GUARD = threading.Lock()

def fetch(url, cache, redirect_only=False, head=False):
 # Multiple package variants can share one authoritative endpoint. Serialize
 # that endpoint so readers never observe a half-written cache file.
 with _CACHE_GUARD:
  lock=_CACHE_LOCKS.setdefault((str(cache),url,redirect_only,head),threading.Lock())
 with lock:
  return _fetch_record(url,cache,redirect_only,head)

def _fetch_record(url, cache, redirect_only=False, head=False):
 key = urllib.parse.quote(url, safe='') + ('.redirect' if redirect_only else '') + ('.head' if head else '') + '.json'
 path = cache / key
 if path.exists(): return json.loads(path.read_text())
 try:
  req=urllib.request.Request(url,headers={'User-Agent':'nixos-config-version-audit/1.0'},method='HEAD' if head else 'GET')
  with urllib.request.urlopen(req,timeout=18) as r:
   result={'url':r.url,'status':r.status,'headers':{'x-oss-meta-version':r.headers.get('x-oss-meta-version')},'body':'' if redirect_only or head else r.read(20000000).decode('utf-8',errors='replace')}
 except Exception as e: result={'url':url,'error':str(e)}
 path.write_text(json.dumps(result)); return result

def numeric(version):
 if not version:return None
 version=version.split('+',1)[0]
 # Distribution wrappers and suffixes require manual interpretation.
 v=version
 for prefix in ('rust-v', 'release-', 'docker-v', 'fuse-', 'intel-media-', 'llvmorg-', 'udisks-', 'microcode-'):
  v=v.removeprefix(prefix)
 v=v.lstrip('vV')
 v=re.sub(r'^(\d+)_(\d+)$',r'\1.\2',v)
 m=re.fullmatch(r'(\d+(?:\.\d+)*)(?:p(\d+))?',v)
 if not m:return None
 return tuple(map(int,m[1].split('.'))) + ((int(m[2]),) if m[2] else ())

def relation(local, upstream):
 if local == upstream:return 'equal'
 if re.fullmatch(r'\d{4}-\d{2}-\d{2}',local or '') and re.fullmatch(r'v?\d{4}-\d{2}-\d{2}',upstream or ''):
  return 'behind' if local<upstream.lstrip('v') else 'equal' if local==upstream.lstrip('v') else 'ahead-or-different-series'
 a,b=numeric(local),numeric(upstream)
 if a is None or b is None:return 'not-comparable'
 n=max(len(a),len(b)); a+= (0,)*(n-len(a)); b+=(0,)*(n-len(b))
 return 'behind' if a<b else 'equal' if a==b else 'ahead-or-different-series'

def comparison_version(name,version):
 if name=='texlive':
  match=re.match(r'^([12]\d{3})(?:-|$)',version or '')
  return match[1] if match else version
 return version

def project_relation(name,local,upstream):
 return relation(comparison_version(name,local),upstream)

def special_version(name, cache):
 # Vendor endpoints carry channel information; use stable, not beta/nightly.
 endpoints = {
  'discord':'https://discord.com/api/download?platform=linux&format=tar.gz',
  'android-studio':'https://developer.android.com/studio?hl=en',
  'qoder-cn':'https://qoder-app.oss-cn-beijing.aliyuncs.com/qoder-app/releases/latest/Qoder-CN-linux-amd64.deb',
  'trae-cn':'https://api.trae.ai/icube/api/v1/native/version/trae/cn/latest',
  'mariadb-server':'https://downloads.mariadb.org/rest-api/mariadb/',
  'cpupower':'https://www.kernel.org/releases.json',
  'rustc':'https://static.rust-lang.org/dist/channel-rust-stable.toml',
  'rustc-wrapper':'https://static.rust-lang.org/dist/channel-rust-stable.toml',
  'rustfmt':'https://static.rust-lang.org/dist/channel-rust-stable.toml',
  'texlive':'https://mirror.ctan.org/systems/texlive/tlnet/release-texlive.txt',
  'cargo':'https://static.rust-lang.org/dist/channel-rust-stable.toml',
  'firefox': 'https://product-details.mozilla.org/1.0/firefox_versions.json',
  'google-chrome': 'https://versionhistory.googleapis.com/v1/chrome/platforms/linux/channels/stable/versions',
  'microsoft-edge': 'https://edgeupdates.microsoft.com/api/products?view=enterprise',
  'nodejs': 'https://nodejs.org/dist/index.json',
  'intellij-idea': 'https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release',
  'idea': 'https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release',
  'pycharm': 'https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release',
 }
 if name not in endpoints:return None
 url=endpoints[name];r=fetch(url,cache,name=='discord',head=name=='qoder-cn');value=None;note='vendor stable release API'
 if name=='discord':
  match=re.search(r'/linux/x64/([0-9.]+)/',r.get('url',''))
  return url,r,match[1] if match else None,'official stable Linux x64 download redirect'
 if name=='android-studio':
  values=re.findall(r'/ide-zips/([0-9]+(?:\.[0-9]+)+)/android-studio-[^"<>]*linux',r.get('body',''))
  return url,r,max(values,key=numeric) if values else None,'official Android Studio stable Linux download package version (release label independently checked in Google updates XML)'
 if name=='qoder-cn':
  return url,r,r.get('headers',{}).get('x-oss-meta-version'),'official latest Linux amd64 package HEAD x-oss-meta-version; binary not downloaded'
 if name=='trae-cn':
  values=[]
  try:
   linux=json.loads(r.get('body','{}'))['data']['manifest']['linux']
   for item in linux['download']:
    if item.get('region')=='cn':
     match=re.search(r'/releases/stable/([0-9.]+)/',item.get('x64.deb',''))
     if match:values.append(match[1])
  except (ValueError,KeyError,TypeError):pass
  return url,r,max(values,key=numeric) if values else None,'official Trae CN stable Linux x64 download build number; displayed app version is a separate field'
 if name=='mariadb-server' and 'error' not in r:
  try:
   branches=[x['release_id'] for x in json.loads(r['body'])['major_releases'] if x['release_status']=='Stable']
   branch=max(branches,key=numeric);url+=branch+'/';r=fetch(url,cache)
   releases=json.loads(r.get('body','{}')).get('releases',[])
   if isinstance(releases,dict):releases=list(releases.values())
   values=[item['release_id'] for item in releases if item.get('release_status') in (None,'Stable') and numeric(item.get('release_id','')) is not None]
   if values:value=max(values,key=numeric)
  except (ValueError,KeyError,TypeError):pass
  return url,r,value,'MariaDB official release API, latest branch marked Stable; configured branch may intentionally be LTS'
 if name in {'rustc','rustc-wrapper','cargo','rustfmt'}:
  if 'error' not in r:
   try:
    import tomllib
    value=tomllib.loads(r['body'])['pkg']['rust']['version'].split()[0]
   except (ValueError,KeyError,TypeError):pass
  return url,r,value,'official Rust stable distribution version; Nix Cargo/rustfmt use the Rust toolchain version, so this comparison uses the toolchain release coordinate'
 if name=='texlive':
  match=re.search(r'(?:version|release)\s+([12]\d{3})',r.get('body',''),re.IGNORECASE)
  if not match:match=re.search(r'TeX Live[^\n]*?([12]\d{3})',r.get('body',''),re.IGNORECASE)
  if not match:
   url='https://tug.org/texlive/';r=fetch(url,cache)
   text=re.sub(r'<[^>]+>',' ',r.get('body',''))
   match=re.search(r'TeX Live\s+([12]\d{3})\s+(?:is(?: now)? available|was released)',text,re.IGNORECASE)
  return url,r,match[1] if match else None,'official TeX Live release manifest or available-release announcement; compare distribution year, not per-package TeX versions'
 if name=='cpupower' and 'error' not in r:
  try:
   values=[x['version'] for x in json.loads(r['body'])['releases'] if x['version'].startswith('6.12.')]
   if values:value=max(values,key=numeric)
  except (ValueError,KeyError,TypeError):pass
  return url,r,value,'kernel.org latest longterm Linux 6.12 release, matching the selected cpupower branch'
 if 'error' not in r:
  try:
   d=json.loads(r['body'])
   if name=='firefox':value=d['LATEST_FIREFOX_VERSION']
   elif name=='google-chrome':value=d['versions'][0]['version']
   elif name=='microsoft-edge':
    versions=[release['ProductVersion'] for product in d if product['Product']=='Stable' for release in product['Releases'] if release['Platform']=='Linux' and release['Architecture']=='x64']
    if versions:value=max(versions,key=lambda v:tuple(map(int,v.split('.'))))
   elif name=='nodejs':
    versions=[release['version'] for release in d if re.fullmatch(r'v\d+\.\d+\.\d+',release['version'])]
    if versions:value=max(versions,key=numeric)
    note='vendor latest stable release; configured Node may intentionally use an LTS branch'
   elif name in ('idea','intellij-idea','pycharm'):value=d['IIU' if name in ('idea','intellij-idea') else 'PCP'][0]['version']
  except (ValueError,KeyError,IndexError,TypeError) as e:r['error']='unexpected vendor API shape: '+str(e)
 return url,r,value,note

def audit(p, cache):
 name=p['name']; home=p.get('homepage','')
 if isinstance(home,list): home=next(iter(home),'')
 row=dict(p); row['upstream_status']='unverified'; row['official_stable_version']=None
 row['sources']=[]; row['notes']=SPECIAL.get(name,'')
 if name=='nerd-fonts-hack':row['notes']+=' Composite version: Nerd Fonts release precedes +; the suffix is the bundled original Hack font version. Compare only the Nerd Fonts release coordinate.'
 if name=='verible':row['notes']+=' Upstream publishes rolling snapshot builds; non-semantic snapshot tags are not treated as stable version numbers.'
 if name in {'texlive','texlive-combined','texlive-scheme-full','texlive-scheme-medium'}:row['notes']+=' This is a TeX Live bundle/distribution year, not a claim that every included TeX package matches its own latest release.'
 if p.get('scope')=='explicit-extra' and not p.get('packageName'):
  row['upstream_status']='identity-unverified'
  row['notes']='Legacy supplemental record used a selector label without raw package identity. Regenerate the inventory before comparing versions.'
  return row
 if name=='sops-install-secrets':
  row['upstream_status']='generated-or-wrapper'
  row['notes']='Internal sops-nix activation installer. Its package version is not the standalone getsops/sops CLI version; the installer is pinned through the sops-nix flake input.'
  return row
 if name.startswith('docker-image-'):
  row['upstream_status']='generated-or-wrapper'
  row['notes']='Pinned container-image derivation. The image tag is embedded in its package name and must not be compared with Docker CLI or upstream application release numbers.'
  return row
 if name in {'nodejs','python3','openjdk','gfortran-wrapper','gcc','gcc-wrapper','mariadb-server','ffmpeg','libreoffice','clang-tools'}:row['notes']+=' A lower default major version may be a maintained LTS or compatibility branch; numeric lag alone does not imply lack of support.'
 if name.startswith(('nixos-', 'nix-info', 'fcitx5-with-addons-')) or (not p.get('version') and name!='texlive' and (not home or name.startswith('python3-'))):
  row['upstream_status']='generated-or-wrapper'
  row['notes']='Generated configuration/wrapper; component versions are audited separately and this entry has no independent stable release.'
  return row
 repo=GITHUB.get(name)
 if not repo and isinstance(home,str):
  m=re.search(r'https?://github\.com/([^/]+/[^/#]+)',home)
  if m:repo=m[1].removesuffix('.git')
 method=None; value=None
 vendor=xfce_version(p,cache) or special_version(name,cache) or gitlab_version(name,cache) or archive_version(name,cache) or page_version(name,cache)
 if name in PAGE_RULES and PAGE_RULES[name].get('notes'):row['notes'] += ' '+PAGE_RULES[name]['notes']
 if vendor:
  url,r,value,method=vendor
 elif name in PYPI:
  url=f'https://pypi.org/pypi/{name}/json'; r=fetch(url,cache); method='official PyPI project latest release'
  if 'error' not in r:
   try: value=json.loads(r['body'])['info']['version']
   except (ValueError,KeyError):
    # info precedes the potentially very large release-file history.
    m=re.search(r'"version"\s*:\s*"([^"]+)"',r['body'])
    if m:value=m[1]
    else:r['error']='PyPI info.version not found'
 elif name in NPM:
  url=f'https://registry.npmjs.org/{NPM[name]}/latest';r=fetch(url,cache);method='official npm latest tag'
  if 'error' not in r:
   try:value=json.loads(r['body'])['version']
   except (ValueError,KeyError) as e:r['error']='invalid npm metadata: '+str(e)
 elif repo and name not in SPECIAL:
  url=f'https://github.com/{repo}/releases/latest';r=fetch(url,cache,True);method='upstream GitHub designated latest non-prerelease release'
  m=re.search(r'/releases/tag/(.+)$',r.get('url',''))
  if m:value=urllib.parse.unquote(m[1])
 elif name in GNU:
  project=GNU[name];url=f'https://ftp.gnu.org/gnu/{project}/';r=fetch(url,cache);method='GNU official release archive (greatest stable numeric tarball)'
  if 'error' not in r:
   versions=re.findall(re.escape(project)+r'-(\d+(?:\.\d+)+)\.tar\.(?:gz|xz|bz2)',r['body'])
   if versions:value=max(set(versions),key=lambda v:tuple(map(int,v.split('.'))))
 elif home:
  url=home.replace('http://','https://');r=fetch(url,cache);method='official homepage inspected; no verified machine-readable stable version rule'
 else:
  row['notes']=row['notes'] or 'Generated wrapper/configuration entry has no independent upstream release metadata.'
  return row
 row['sources'].append({'url':url,'resolved_url':r.get('url'), 'method':method, 'error':r.get('error')})
 tag_only=bool(vendor and ('tags;' in method or 'project tags;' in method))
 if repo and name not in SPECIAL and (value is None or relation(p.get('version',''),value)=='ahead-or-different-series'):
  tags_url,tags_response,tags_value=github_tags(repo,cache)
  row['sources'].append({'url':tags_url,'resolved_url':tags_response.get('url'),'method':'official numeric non-prerelease tag fallback; tags are not a designated release','error':tags_response.get('error')})
  if tags_value:
   row['latest_numeric_tag']=tags_value
   row['tag_comparison']=relation(p.get('version',''),tags_value)
   if value is None:value=tags_value;tag_only=True
 if name=='deepseek-harness' and value is None:
  release_url='https://api.github.com/repos/deepseek-ai/deepseek-harness/releases?per_page=10'
  preview=fetch(release_url,cache)
  row['sources'].append({'url':release_url,'resolved_url':preview.get('url'),'method':'official release metadata, including prerelease flags','error':preview.get('error')})
  try:
   releases=json.loads(preview.get('body','[]'))
   if releases and all(item.get('prerelease') for item in releases):
    row['upstream_status']='prerelease-only'
    row['latest_preview']=releases[0]['tag_name'].removeprefix('dsh-v')
    row['notes']='No designated stable release; latest observed release is a prerelease and is compared separately.'
  except (ValueError,TypeError,KeyError):pass
 if name=='verible' and value:
  row['latest_snapshot']=value
  row['upstream_status']='not-comparable'
  row['notes']+=' Latest published snapshot is recorded separately; no stable version is asserted.'
  return row
 if value:
  if tag_only:
   row['latest_numeric_tag']=value;row['tag_comparison']=relation(p.get('version',''),value);row['upstream_status']='tag-only'
   row['notes']+=' Numeric upstream tag is an available release candidate signal; a stable-release designation was not independently verified.'
  else:
   row['official_stable_version']=value; row['upstream_status']=project_relation(name,p.get('version',''),value) if p.get('baseline_present',True) else 'newly-added'
   if name=='texlive':row['comparison_coordinate']='TeX Live distribution year'
 return row

def recipe_path(record):
 return re.sub(r'^/nix/store/[^/]+/', '',record.get('position','')).rsplit(':',1)[0]

def homepage_identity(record):
 home=record.get('homepage','')
 if isinstance(home,list):home=next(iter(home),'')
 if not home:return None
 url=urllib.parse.urlsplit(home)
 host=url.netloc.lower().removeprefix('www.');path=url.path.rstrip('/')
 if host=='github.com':path=path.lower()
 aliases={
  ('heroicgameslauncher.com',''):('github.com','/heroic-games-launcher/heroicgameslauncher'),
  ('linux-usb.org',''):('git.kernel.org','/pub/scm/linux/kernel/git/gregkh/usbutils.git'),
  ('github.com','/nm-l2tp/network-manager-l2tp'):('github.com','/nm-l2tp/networkmanager-l2tp'),
  ('bluez.org',''):('bluez.github.io',''),
 }
 return aliases.get((host,path),(host,path))

def same_project(before, after):
 names=(before['name'],after['name'])
 renamed=names==('idea','intellij-idea')
 if names[0]!=names[1] and not renamed:return False
 # Raw pname is preserved by the inventory; packageName supplies independent
 # provenance, while its version suffix is intentionally not compared.
 home=homepage_identity(before);current_home=homepage_identity(after)
 if home and current_home:
  # A shared generic build wrapper must not overrule conflicting project URLs.
  return True if home==current_home else None
 recipe=recipe_path(before)
 if recipe and recipe==recipe_path(after):return True
 return None

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--before',required=True);ap.add_argument('--extra');ap.add_argument('--after');ap.add_argument('--output',required=True)
 ap.add_argument('--cache',default='/tmp/nixos-software-audit-http');ap.add_argument('--workers',type=int,default=6)
 a=ap.parse_args();cache=pathlib.Path(a.cache);cache.mkdir(parents=True,exist_ok=True)
 source=json.loads(pathlib.Path(a.before).read_text())
 source=[p for p in source if p.get('scope') in {'system','explicit-extra'}]
 if a.extra: source+=json.loads(pathlib.Path(a.extra).read_text())
 after_rows=json.loads(pathlib.Path(a.after).read_text()) if a.after else []
 before_names={p['name'] for p in source}
 for p in after_rows:
  if (p['scope'] in {'system','explicit-extra'} or p['name'] in {'whitesur-gtk-theme','whitesur-cursors','whitesur-icon-theme','xfce4-panel-profiles','cargo','rustc','rustc-wrapper','rustfmt','iverilog','verible','texlive','nerd-fonts-hack'}) and p['name'] not in before_names:
   source.append(dict(p,version='',baseline_present=False))
 unique={}
 for p in source:
  home=p.get('homepage','')
  if isinstance(home,list): home=' '.join(home)
  # KDE/Qt/platform/font/driver audit is recorded in the complementary home audit.
  if 'invent.kde.org' in home or 'qt.io' in home or p['name'] in {'qttools','kwayland-integration','kio5-plugins-only','nvidia-x11','nvidia-settings','nvidia-offload','X11-fonts','fontconfig','fallback-cursor-theme','sound-theme-freedesktop','alsa-firmware','sof-firmware'}:continue
  key=(p['name'],p.get('version',''),homepage_identity(p))
  if key not in unique:unique[key]=dict(p,attributes=[])
  if p.get('attribute') and p['attribute'] not in unique[key]['attributes']:unique[key]['attributes'].append(p['attribute'])
 with concurrent.futures.ThreadPoolExecutor(max_workers=a.workers) as ex:
  rows=list(ex.map(lambda p:audit(p,cache),unique.values()))
 after={}
 for p in after_rows:after.setdefault(p['name'],[]).append(p)
 position=recipe_path
 for row in rows:
  candidates=after.get(row['name'],[])
  if not candidates and row['name']=='idea':candidates=after.get('intellij-idea',[])
  if not candidates and row['upstream_status']=='generated-or-wrapper':
   candidates=[p for p in after_rows if p['scope']==row['scope'] and position(p)==position(row)]
  exact=[p for p in candidates if position(p)==position(row)]
  if exact:candidates=exact
  if len({p.get('version','') for p in candidates})>1:
   major=(row.get('version') or '').split('.')[0]
   matched=[p for p in candidates if p.get('version','').split('.')[0]==major]
   if matched:candidates=matched
  if candidates:
   current_record=candidates[0]
   identity=same_project(row,current_record)
   row['current_package_name']=current_record.get('packageName')
   row['current_name']=current_record['name']
   row['identity_match']='verified' if identity else 'unverified'
   current=current_record.get('version','')
   row['unstable_version']=current
   row['unstable_upstream_status']=project_relation(row['name'],current,row['official_stable_version']) if row['official_stable_version'] else row['upstream_status'] if row['upstream_status'] in {'generated-or-wrapper','tag-only','prerelease-only','not-comparable'} else 'unverified'
   if row.get('latest_numeric_tag'):row['unstable_tag_comparison']=relation(current,row['latest_numeric_tag'])
   if not identity and row['upstream_status']!='generated-or-wrapper':
    row['unstable_upstream_status']='identity-unverified'
    row['notes']+=' Baseline/current project identity could not be matched by recipe or homepage; no numeric version conclusion is made.'
 report={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'Evaluated system package inventory and explicit wrapped/Python/input-method extras, excluding separately audited KDE/Qt/fonts/NVIDIA. Actual package names are preserved; selector attributes are metadata. Deduplicated by package name, baseline version and homepage identity.',
 'methodology':'GitHub designated latest is the maintainers’ release label and can lag tagged releases. Official upstream releases/latest, PyPI/npm and GNU release archives. Unverified rows explicitly remain unverified; latest unstable is never assumed equal to upstream. Numeric comparisons do not decide suitability of release branches. Baseline/current comparisons require matching recipe or homepage identity, never selector names alone. Metadata-only, not build/runtime validation.',
 'baseline':'git HEAD at audit start (26.05 system plus selected unstable/NUR apps)','rows':rows}
 pathlib.Path(a.output).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 from collections import Counter
 print(json.dumps({'rows':len(rows),'statuses':dict(Counter(p['upstream_status'] for p in rows))}))
if __name__=='__main__':main()
