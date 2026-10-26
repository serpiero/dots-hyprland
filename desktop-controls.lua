-- Input shortcuts are independent of the visual profile.
local root = os.getenv("RICE_ROOT") or (os.getenv("HOME") .. "/.local/share/rice-profiles")

hl.unbind("SUPER + V")
hl.bind("SUPER + V", hl.dsp.window.float({action = "toggle"}),
 {description = "Window: Float/Tile"})

hl.unbind("SUPER + H")
hl.bind("SUPER + H", hl.dsp.global("quickshell:overviewClipboardToggle"),
 {description = "Utilities: Clipboard history"})
hl.bind("SUPER + H", hl.dsp.exec_cmd(
 "qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"))

hl.window_rule({name = "steel-settings", match = {class = "^org.serpiero.ArcSteelSettings$"},
 float = true, center = true, size = {900, 650}, pin = true})
