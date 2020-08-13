# xmonad-de

Configs and Scripts to use Xmonad as your Desktop Environment

## Set-up instructions using Xubuntu (20.04) as base system

### Install packages

`apt install xmonad xmobar trayer synapse quodlibet redshift-gtk vorbis-tools imagemagick feh`

- xmonad: tiling window manager and keyboard shortcut management
- xmobar: status bar (workspaces, date, cpu, network, etc)
- trayer: system tray for apps that depend on it
- synapse: launcher and zeitgeist powered finder
- quodlibet: scriptable music player
- redshift-gtk: auto screen color temperature adjustment
- vorbis-tools: provides ogg123 which is used in volume media key script
- feh, imagemagick: used to set background

### Clone repo, copy files

```
$ git clone https://github.com/pullingshots/xmonad-de.git
$ cp -r xmonad-de/.xmonad ~
$ cp xmonad-de/.xmobarrc* ~
$ cp -r xmonad-de/bin ~
$ cp -r xmonad-de/Sounds ~

```

### Edit display switching scripts

Run `xrandr` from a terminal and make note of display names (i.e. eDP-1, HDMI-1, etc)

Edit `bin/single` script with appropriate display names. This script is called when you log in to set up xmobar and trayer on a single display.

Edit `bin/extrld` script with appropriate display names and test it to position trayer and xmobar how you want for multiple extended displays.

To switch between single and extended displays use `<Super>-o` (single) and `<Super>-<Shift>-o` (extended)

### Edit auto-start login script
 
Edit `bin/bg` to point at the photos you want to use for the background. Use `<Super>-<Shift>-b` to change background

Edit `bin/desktop-utilities` to add or remove programs you want auto-started at login. By default it sets the background, runs syndaemon (to deactivate the touchpad while typing), and starts redshift-gtk (you will need to add your lat and lon to get correct behaviour)

### Log in to Xmonad!

At this point you can logout, choose Xmonad as your session and log back in.

`<Super>-<Shift>-<Enter>` to open a terminal

`<Super>-p` to open the launcher

`<Super>-Home` to open file manager

`<Super>-1 thru 9` to switch to the corresponding workspace

### WiFi and network management

Run `ip addr` and make note of your wifi and ethernet device names. Edit device names in `bin/wifi-wpa` and `bin/eth`.

Copy wifi network settings file: `sudo cp -r xmonad-de/etc/wpa_supplicant /etc/`

Edit `/etc/wpa_supplicant/wpa_supplicant.conf` to add your wifi network settings

`<Super>-<Shift>-w` to connect to wifi

`<Super>-<Shift>-e` to connect to ethernet

run `bin/wifi` to scan for available networks and `bin/wifi [ssid]` to connect to an open network

### Screen brightness Fn keys

Copy system startup script to give permission to brightness file `/sys/class/backlight/intel_backlight/brightness`

`sudo cp xmonad-de/etc/rc.local /etc/` and run it so that you do not need to reboot `sudo /etc/rc.local`

Brightness Fn keys should now work!

### Volume Fn keys

These should just work and will play a "pop" sound when pressed.

### Media keys

Play/Pause Fn key will play/pause quodlibet


### Screenshots

`<Super>-s` to take a screenshot

## Common settings to change

Edit `xmonad/xmonad.hs` to change the terminal emulator or file manager. I prefer Konsole and Dolphin. `sudo apt install konsole dolphin breeze-icon-theme`

Try Konsole with the Solarized color scheme and Terminus font. `sudo apt install xfonts-terminus`

## Vim Vixen for Firefox

Try the [Vim Vixen](https://addons.mozilla.org/en-CA/firefox/addon/vim-vixen/) Firefox extension to navigate the web without a mouse!

## Oh my zsh

A highly recommended shell - https://ohmyz.sh

