import XMonad
import XMonad.Config.Desktop
import qualified XMonad.StackSet as W -- to shift and float windows
import qualified Data.Map as M

import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName

import XMonad.Actions.Warp

import XMonad.Hooks.DynamicLog -- for getting dynamic info into xmobar

import XMonad.Layout.GridVariants

import XMonad.Actions.CopyWindow

import Graphics.X11.ExtraTypes.XF86

import Control.Exception
import System.Exit

myLayout = tiled ||| Mirror tiled ||| Full ||| Grid (16/10)
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled   = Tall nmaster delta ratio
 
    -- The default number of windows in the master pane
    nmaster = 1
 
    -- Default proportion of screen occupied by master pane
    ratio   = 1/2
 
    -- Percent of screen to increment by when resizing panes
    delta   = 3/100

myKeys (XConfig {modMask = modm}) = M.fromList $
    [ ((modm, xK_p), spawn "synapse")
    , ((modm, xK_z), warpToWindow (0) (0)) -- move mouse to currently focused window
    , ((modm, xK_a ), windows copyToAll) -- @@ Make focused window always visible
    , ((modm .|. shiftMask, xK_a ),  killAllOtherCopies) -- @@ Toggle window state back
    , ((modm .|. shiftMask, xK_l), spawn "i3lock -i \"$(find ~/Wallpaper -type f \\( -name \"*.png\" -o -name \"*.jpg\" \\) | shuf -n1)\" --scale")
    , ((modm .|. shiftMask, xK_w), spawn "xterm -e 'sudo ~/bin/wifi-mgr.sh -s'")
    , ((modm .|. shiftMask, xK_e), spawn "xterm -e 'sudo ~/bin/wifi-mgr.sh -e'")
    , ((modm, xK_Home), spawn "thunar")
    , ((modm .|. shiftMask, xK_n), spawn "quodlibet --set-rating=1.0; xterm -e '~/bin/quodlibet-lastfm-love'")
    , ((modm .|. shiftMask, xK_m), spawn "quodlibet --random=album; quodlibet --next; ~/bin/quodlibet-now-playing")
    , ((modm, xK_m), spawn "quodlibet --next; ~/bin/quodlibet-now-playing")
    , ((modm, xK_n), spawn "~/bin/quodlibet-now-playing")
    , ((modm, xK_v), spawn "sudo service bluetooth restart")
    , ((modm .|. shiftMask, xK_o), spawn "xterm -e '~/bin/display-mgr.sh'")
    , ((modm .|. shiftMask, xK_b), spawn "~/bin/bg")
    , ((modm, xK_o), spawn "xterm -e '~/bin/display-mgr.sh -a'")
    , ((noModMask, xF86XK_AudioLowerVolume), spawn "amixer sset Master on && amixer sset Master 5%- && ogg123 ~/Sounds/volume.ogg")
    , ((noModMask, xF86XK_AudioRaiseVolume), spawn "amixer sset Master on && amixer sset Master 5%+ && ogg123 ~/Sounds/volume.ogg")
    , ((noModMask, xF86XK_AudioMute), spawn "amixer sset Master toggle")
    , ((noModMask, xF86XK_AudioPlay), spawn "quodlibet --play-pause")
    , ((noModMask, xF86XK_AudioNext), spawn "quodlibet --next")
    , ((noModMask, xF86XK_AudioPrev), spawn "quodlibet --previous")
    , ((modm, xK_grave), spawn "quodlibet --toggle-window")
    , ((modm .|. shiftMask, xK_grave), spawn "quodlibet")
    , ((noModMask, xF86XK_MonBrightnessUp), spawn "~/bin/brightness-up")
    , ((noModMask, xF86XK_MonBrightnessDown), spawn "~/bin/brightness-down")
    , ((mod1Mask, xK_Tab), windows W.focusDown)
    , ((mod1Mask .|. shiftMask, xK_Tab), windows W.focusUp)
    , ((modm, xK_s), spawn "~/bin/screenshot")
    , ((modm, xK_x), spawn "xterm -e '~/bin/encrypted-usb-mount-sda'")
    , ((modm .|. shiftMask, xK_x), spawn "xterm -e '~/bin/encrypted-usb-umount'")
    ]

baergajPP = def { ppCurrent = xmobarColor "white" "" . wrap "[" "]"
               , ppTitle   = xmobarColor "green" "" . shorten 40
               , ppVisible = wrap "(" ")"
               , ppUrgent  = xmobarColor "red" "yellow"
               }

main = xmonad $ docks $ ewmh def
  { modMask = mod4Mask
  , terminal = "konsole"
  , keys     = \c -> myKeys c `M.union` keys desktopConfig c
  , logHook = dynamicLogString baergajPP >>= xmonadPropLog -- current desktop/window info in xmobar
  , layoutHook = avoidStruts(myLayout)  -- windows don't overlap xmobar
  , startupHook = do
    startupHook desktopConfig
    spawn "display-mgr.sh -s"
    spawn "desktop-utilities"
  }
