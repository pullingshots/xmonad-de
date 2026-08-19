# xmonad-de 🧰✨

A cozy little desktop environment built around **XMonad**, **xmobar**, helpful shell scripts, and a few quality-of-life shortcuts.

This repo is meant to turn a minimal Debian based install into a fast, keyboard-driven, slightly nerdy desktop that can:

- manage windows with XMonad
- show system status with xmobar
- switch display layouts
- manage WiFi/Ethernet
- control brightness and volume keys
- launch browsers with disposable/profile-based setups
- show music info from Quod Libet
- take screenshots
- mount encrypted USB drives
- generally make your laptop feel like *your* laptop

## Quick start 🚀

```bash
sudo apt install \
  xmonad xmobar trayer synapse quodlibet redshift-gtk \
  vorbis-tools imagemagick feh maim xclip \
  xterm thunar konsole i3lock \
  cryptsetup curl jq bc gping \
  gnupg openssh-client \
  perl
```

- `xmonad` — the window manager
- `xmobar` — the top status bar
- `trayer` — system tray support
- `synapse` — app launcher
- `quodlibet` — scriptable music player
- `redshift-gtk` — warmer screen colors at night
- `feh` + `imagemagick` — wallpaper tools
- `maim` + `xclip` — screenshots to file and clipboard
- `cryptsetup` — encrypted USB helper
- `jq`, `curl`, `bc`, `gping` — used by the display/network scripts
- `gnupg`, `openssh-client` — used by the encrypted backup script

## Installation 🧱

```bash
git clone https://github.com/pullingshots/xmonad-de.git
cd xmonad-de

cp -r .xmonad ~
cp .xmobarrc* ~
cp -r bin ~
cp -r Sounds ~
```

Then log out, choose the **XMonad** session, and log back in.

> Tip: read through the scripts before running them. Several are personalized for specific usernames, monitor names, WiFi interfaces, backlight devices, or mount points.
>
> Backup note: `bin/backup` expects a private `bin/.env` file. Do not commit that file because it contains your backup passphrase and destination.

## Keyboard shortcuts 🎹

| Shortcut | Action |
|---|---|
| `Super + Shift + Enter` | Open terminal |
| `Super + p` | Launch Synapse |
| `Super + Home` | Open file manager |
| `Super + 1..9` | Switch workspaces |
| `Super + z` | Warp mouse to focused window |
| `Super + a` | Show focused window on all workspaces |
| `Super + Shift + a` | Undo “show on all workspaces” |
| `Super + Shift + l` | Lock screen with a random wallpaper |
| `Super + Shift + w` | Open WiFi manager and connect to strongest configured network |
| `Super + Shift + e` | Switch to Ethernet |
| `Super + Shift + o` | Open interactive display manager |
| `Super + o` | Auto-apply display layout |
| `Super + Shift + b` | Pick a new wallpaper |
| `Super + s` | Take screenshot |
| `Super + x` | Mount encrypted usb drive |
| `Super + Shift + x` | Unmount encrypted usb drive |
| `Super + m` | Next Quod Libet track and refresh now-playing wallpaper |
| `Super + Shift + m` | Random album, next track, refresh now-playing wallpaper |
| `Super + n` | Refresh Quod Libet now-playing wallpaper |
| `Super + Shift + n` | Rate/love current track workflow |
| `Super + grave` | Toggle Quod Libet window |
| `Super + Shift + grave` | Launch Quod Libet |
| Volume keys | Adjust/mute volume |
| Brightness keys | Adjust screen brightness |
| Media keys | Play/pause/next/previous in Quod Libet |

`Super` is usually the Windows/Linux logo key.

## Display management 🖥️🧠

The main display helper is:

```bash
~/bin/display-mgr.sh
```

It uses `xrandr` to detect connected monitors and can ask a local Ollama model for layout suggestions.

Common usage:

```bash
display-mgr.sh
display-mgr.sh -a
display-mgr.sh -s
```

| Command | What it does |
|---|---|
| `display-mgr.sh` | Interactive mode: shows displays, asks what layout you want, offers choices |
| `display-mgr.sh -a` / `--auto` | Auto-apply saved layout, or ask Ollama for a best guess |
| `display-mgr.sh -s` / `--startup` | Startup mode: enable primary display and restart xmobar/trayer |

Layouts are remembered in:

```bash
~/.config/display-mgr/history.json
```

Tips:

- Run `xrandr` if you need to debug monitor names.
- Make sure Ollama is running if you want AI layout suggestions.
- Update `OLLAMA_MODEL` inside `bin/display-mgr.sh` if your local model has a different name.
- If bars/tray look weird, rerun `display-mgr.sh -a`.

## Network management 📡

The modern network helper is:

```bash
sudo ~/bin/wifi-mgr.sh
```

Usage:

```bash
sudo wifi-mgr.sh -l
sudo wifi-mgr.sh -a "SSID"
sudo wifi-mgr.sh -c "SSID"
sudo wifi-mgr.sh -d "SSID"
sudo wifi-mgr.sh -s
sudo wifi-mgr.sh -o
sudo wifi-mgr.sh -e
```

| Option | Action |
|---|---|
| `-l`, `--list` | Scan and list nearby networks |
| `-a`, `--add <ssid>` | Add a new network or update a saved password |
| `-c`, `--connect <ssid>` | Connect to a specific network |
| `-d`, `--disable <ssid>` | Toggle autoconnect for a saved network |
| `-s`, `--strongest-config` | Connect to the best configured network nearby |
| `-o`, `--strongest-open` | Try the strongest open network |
| `-e`, `--ethernet` | Switch to Ethernet |

After connecting, the script can test quality with ping stats and then launch `gping`.

Tips:

- Run with `sudo`.
- SSIDs with spaces should be quoted.
- The script uses NetworkManager via `nmcli`.
- If Ethernet switching fails, it tries to reconnect WiFi.

## Browser helpers 🌐

### `bin/ff`

Firefox profile launcher.

```bash
ff
ff work
ff banking
```

- With no argument, launches Firefox in a private window.
- With an argument, uses `~/Profiles/firefox/<name>`.
- Creates the profile directory if missing.
- Writes a small `user.js` and `userChrome.css` to keep new tabs/home pages quiet and minimal.

### `bin/cm`

Chromium profile launcher.

```bash
cm
cm work
cm testing
```

- With no argument, launches Chromium incognito.
- With an argument, uses `~/Profiles/chromium/<name>`.
- Expects Chromium at `~/chromium/latest/chrome`. See https://github.com/scheib/chromium-latest-linux

## Wallpaper and desktop startup 🌅

### `bin/bg`

Picks a random PNG from:

```bash
~/Wallpaper
```

Then auto-orients it, writes `/tmp/bg.jpg`, and sets it with `feh`.

```bash
bg
```

Tip: put your favorite wallpapers in `~/Wallpaper`, then hit `Super + Shift + b` whenever you need a fresh vibe.

### `bin/desktop-utilities`

Runs at XMonad startup. It currently:

- sets a wallpaper via `bin/bg`
- restarts `syndaemon` so the touchpad chills while typing
- restarts `redshift-gtk`

Edit the latitude/longitude in this script for correct Redshift behavior.

## Brightness and power ⚡

### `bin/brightness-up` / `bin/brightness-down`

Used by the brightness function keys.

They read/write:

```bash
/sys/class/backlight/amdgpu_bl0/brightness
```

If your laptop uses a different backlight device, update both scripts.

### `etc/rc.local`

Grants write permission to the Intel backlight brightness file at boot:

```bash
/sys/class/backlight/amdgpu_bl0/brightness
```

Install with:

```bash
sudo cp etc/rc.local /etc/rc.local
sudo chmod +x /etc/rc.local
sudo /etc/rc.local
```

Tip: modern systems may use `amdgpu_bl0`, `intel_backlight`, or another backlight name. Check with:

```bash
ls /sys/class/backlight
```

### `bin/performance` and `bin/powersave`

Manual power profiles.

| Script | Effect |
|---|---|
| `performance` | Sets CPU governor to performance, raises max CPU frequency, disables WiFi power saving, increases brightness |
| `powersave` | Sets CPU governor to powersave, lowers max CPU frequency, enables WiFi power saving, lowers brightness |

These write to `/sys`, so they usually need root privileges.

## Screenshots 📸

### `bin/screenshot`

Bound to:

```text
Super + s
```

It waits 5 seconds, lets you select an area, saves the image to `/tmp`, copies it to the clipboard, and opens it in `feh`.

Requires:

- `maim`
- `xclip`
- `feh`

## Music helpers 🎧

These scripts assume Quod Libet is your music player.

### `bin/quodlibet-now-playing`

If music is playing, this script:

- reads artist/album/title from Quod Libet
- creates `/tmp/quodlibet-now-playing.png`
- overlays track info onto album art
- sets it as the background with `feh`

Great for turning your desktop into a tiny now-playing shrine.

### `bin/quodlibet-lastfm-love`

Loves the current track on Last.fm using `Net::LastFM`.

Before using it:

- get a Last.fm API key/secret
- generate a session key
- replace the placeholder values in the script

The script currently contains inline notes explaining the Last.fm auth flow.

## Mount helpers 🔐📱

### `bin/encrypted-usb-mount-sda` / `bin/encrypted-usb-umount`

Opens and mounts an encrypted USB partition.

Defaults:

- device: `/dev/sda1`
- mapper name: `foobar`
- mount point: `/media/foobar`

Use with care:

```bash
encrypted-usb-mount-sda
encrypted-usb-umount
```

Tip: confirm the device name first with `lsblk`. Mounting the wrong disk is not a fun side quest.

## Backups 💾🔐

### `bin/backup`

Creates an encrypted backup archive of `$HOME`, excluding large/cache-heavy directories, then copies it to a configured remote location.

It creates:

```bash
/tmp/backup.tar.bz2.gpg
```

The script expects a private environment file next to the script:

```bash
~/bin/.env
```

Example:

```bash
BACKUP_PASSPHRASE='change-me'
BACKUP_LOCATION='user@example.com:/path/to/backups/'
```

Run:

```bash
backup
```

What it does:

1. loads `BACKUP_PASSPHRASE` and `BACKUP_LOCATION` from `~/bin/.env`
2. creates a compressed tar backup of `$HOME`
3. excludes browser caches, downloads, repositories’ git objects, local app caches, games, and other bulky/generated files
4. encrypts the archive with `gpg -c`
5. uploads it with `scp`

Requires:

- `gnupg`
- `openssh-client`

Tips:

- Keep `~/bin/.env` private and out of git.
- Make sure SSH access to `BACKUP_LOCATION` works before running the backup.
- Review the exclude list in `bin/backup` before relying on it.
- The script removes any existing `/tmp/backup.tar.bz2.gpg` before creating a new backup.

## App updater 🦊📬

### `bin/update-mozilla.sh`

Updates local Firefox and Thunderbird installs.

Defaults:

| App | Install path |
|---|---|
| Firefox | `~/firefox` |
| Thunderbird | `~/thunderbird` |

The script:

1. checks the installed version
2. checks Mozilla’s latest version
3. downloads the latest tarball if needed
4. extracts it into the existing install directory

Run:

```bash
update-mozilla.sh
```

Tip: close Firefox/Thunderbird before updating.

## Config files 🛠️

### `.xmonad/xmonad.hs`

The heart of the desktop.

Customize here if you want to change:

- terminal emulator
- file manager
- keyboard shortcuts
- layout choices
- startup applications
- xmobar logging
- workspace/window behavior

Current terminal:

```haskell
terminal = "konsole"
```

Current startup helpers:

```haskell
display-mgr.sh -s
desktop-utilities
```

### `.xmobarrc`

Primary xmobar config.

Shows:

- XMonad workspace/window info
- battery
- CPU
- memory
- swap
- disk IO
- network
- weather
- date/time

Weather station is currently:

```text
CYYC
```

Change that if you are not near Calgary.

### `.xmobarrc-secondary`

Secondary monitor xmobar config.

Used by `display-mgr.sh` when more than one monitor is connected.

## Personalization checklist ✅

Before daily driving this setup, check these values:

- wallpaper directory in `bin/bg`
- Redshift latitude/longitude in `bin/desktop-utilities`
- browser paths in `bin/ff` and `bin/cm`
- Firefox/Chromium profile base directories
- backlight device names in brightness scripts
- WiFi/Ethernet interface names if using legacy network scripts
- encrypted USB device name before mounting
- backup destination and passphrase in `~/bin/.env` for `bin/backup`
- Last.fm credentials if using the love-track helper
- weather station in `.xmobarrc`
- terminal/file manager in `.xmonad/xmonad.hs`
- Ollama model name in `bin/display-mgr.sh`

## Troubleshooting 🧯

### Brightness keys do nothing

Check your backlight device:

```bash
ls /sys/class/backlight
```

Then update `bin/brightness-up`, `bin/brightness-down`, and possibly `etc/rc.local`.

### xmobar or trayer looks weird

Try:

```bash
display-mgr.sh -a
```

or restart XMonad.

### WiFi script cannot connect

Try listing known connections:

```bash
nmcli connection show
```

Then use:

```bash
sudo wifi-mgr.sh -l
sudo wifi-mgr.sh -a "SSID"
sudo wifi-mgr.sh -c "SSID"
```

### Display manager AI suggestions fail

Make sure Ollama is running and the configured model exists:

```bash
ollama list
```

Then update `OLLAMA_MODEL` in `bin/display-mgr.sh`.

### Quod Libet scripts are quiet

Make sure Quod Libet is running and playing music:

```bash
quodlibet --status
```

## Optional nice extras 🍒

- [Vim Vixen](https://addons.mozilla.org/en-CA/firefox/addon/vim-vixen/) for keyboard-first Firefox browsing
- [Oh My Zsh](https://ohmyz.sh/) if you want a fancy shell prompt and plugin ecosystem

## Have fun 🐧

This setup is intentionally hackable. Break it, tweak it, rename things, add shortcuts, swap tools, and make your desktop feel like a tiny command-center spaceship.
