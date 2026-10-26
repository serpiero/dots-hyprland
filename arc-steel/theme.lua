-- Arc Steel — local Hyprland profile

local dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local _ENV = setmetatable({}, {__index = _G})
local variables = dofile(dir .. "variables.lua")
local colors = dofile(dir .. "colors.lua")

for k, v in pairs(variables) do _ENV[k] = v end
for k, v in pairs(colors) do _ENV[k] = v end

-- Arc Steel: effective compositor settings, applied once.
hl.config({
    general = {
        border_size = 0,
        gaps_in = 5,
        gaps_out = 10,
        col = {
            inactive_border = "rgba(" .. cy0 .. tr0 .. ")",
            active_border = "rgba(" .. re0 .. trF .. ")",
        },
    },
    input = { follow_mouse = 1 },
    cursor = { no_warps = true },
    decoration = {
        rounding = 20,
        rounding_power = 2,
        active_opacity = activeTr,
        inactive_opacity = inActiveTr,
        dim_inactive = true,
        dim_strength = 0.04,
        dim_special = 0,
        blur = {
            enabled = true,
            size = 14,
            passes = 3,
            noise = 0.015,
            contrast = 1.12,
            brightness = 1.08,
            vibrancy = 0.12,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
            popups = true,
            popups_ignorealpha = 0.6,
        },
        shadow = {
            enabled = true,
            range = 24,
            scale = 1,
            render_power = 3,
            color = "rgba(00000055)",
            color_inactive = "rgba(" .. no0 .. tr2 .. ")",
        },
    },
    group = {
        col = {
            border_active = "rgba(" .. re0 .. trF .. ")",
            border_inactive = "rgba(" .. re1 .. trF .. ")",
            border_locked_active = "rgba(" .. vi0 .. trF .. ")",
            border_locked_inactive = "rgba(" .. vi0 .. tr7 .. ")",
        },
        groupbar = {
            col = {
                active = "rgba(" .. re0 .. trF .. ")",
                inactive = "rgba(" .. re1 .. trF .. ")",
                locked_active = "rgba(" .. vi0 .. trF .. ")",
                locked_inactive = "rgba(" .. vi0 .. tr7 .. ")",
            },
            font_size = fontM,
            text_color = "rgba(" .. no0 .. trF .. ")",
            height = 1,
            indicator_height = 24,
            text_offset = -12,
        },
    },
    animations = { enabled = true },
})
hl.window_rule({match={class=".*"}, no_blur=false, border_size=0})
hl.window_rule({match={class=".*"}, opacity="0.82 override 0.80 override 1.0 override"})
hl.window_rule({match={class="(Chatgpt|[Cc]hat[Gg][Pp][Tt]|firefox|org.mozilla.firefox|org.kde.dolphin|dolphin|[Ww]hats[Aa]pp.*)"}, opacity="0.82 override 0.80 override 1.0 override"})
hl.window_rule({match={class="(kitty|foot|Alacritty|org.kde.konsole)"}, opacity="1.0 override 0.94 override 1.0 override"})
hl.window_rule({match={class="(mpv|vlc|steam_app_.*)"}, opacity="1.0 override 1.0 override 1.0 override"})
-- Native XWayland menus have no WM_CLASS/title. Their transparent padding must
-- never receive the main window's glass, rounded frame or compositor shadow.
-- Keep this after the general rules, for every app rather than a translated name.
hl.window_rule({match={class="^$",title="^$",xwayland=true},
 no_blur=true,no_shadow=true,rounding=0,border_size=0,
 opacity="1.0 override 1.0 override 1.0 override"})
hl.window_rule({match={title="^[A-Za-z]+ContextMenu$"},float=true,
 no_blur=true,no_shadow=true,rounding=0,border_size=0,no_anim=true,
 opacity="1.0 override 1.0 override 1.0 override"})
hl.layer_rule({match={namespace="(quickshell:.*|waybar|rofi|swaync-control-center|swaync-notification-window)"},blur=true,ignore_alpha=0.1})
-- The notification panel handles its own short reveal without a second layer animation.
hl.layer_rule({match={namespace="quickshell:sidebarRight"},no_anim=true})
local root = os.getenv("RICE_ROOT") or (os.getenv("HOME") .. "/.local/share/rice-profiles")
local function bind(key,action,description)
 hl.unbind(key)
 hl.bind(key,hl.dsp.exec_cmd("python3 " .. root .. "/session.py " .. action),{description=description})
end
bind("SUPER + Return","terminal","Applications: Open terminal")
bind("SUPER + T","terminal","Applications: Open terminal")
bind("CTRL + ALT + T","terminal","Applications: Open terminal")
bind("SUPER + R","spotlight","Applications: Open Arc Steel Spotlight")
hl.unbind("CTRL + SUPER + T")
hl.bind("CTRL + SUPER + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), {description="Shell: Choose wallpaper"})
bind("CTRL + SUPER + A","web-chat","Shell: Open Intelligence")
bind("CTRL + SUPER + R","sync","Configuration: Start shell if stopped")
hl.env("qsConfig", "arc-steel")

-- Persistent screenshot selection overlay, scoped to Arc Steel.
local function capture(key, mode)
 hl.unbind(key)
 hl.bind(key, hl.dsp.exec_cmd("python3 " .. root .. "/capture-overlay.py " .. mode), {description=mode=="screen" and "Capture: Capture full screen" or mode=="window" and "Capture: Capture active window" or "Capture: Select and annotate region"})
end
capture("SUPER + SHIFT + S", "region")
capture("Print", "screen")
capture("CTRL + Print", "window")
hl.window_rule({match={class="(spectacle|org.kde.spectacle)"}, float=true, center=true,
 size={"(monitor_w*0.72)","(monitor_h*0.80)"}, opacity="1.0 override 1.0 override 1.0 override", no_dim=true})

-- No entrance/exit motion for the frozen screenshot selection.
hl.layer_rule({match={namespace="arc-steel:capture"},no_anim=true,blur=false})

-- Opaque launcher surface needs no backdrop blur fringe.
hl.layer_rule({match={namespace="quickshell:overview"},blur=false})

-- Google Lens is intentionally disabled in this profile.
hl.unbind("SUPER + SHIFT + A")

-- Arc Steel settings replace inherited controls that do not affect this fork.
-- Match a stable app id: the translated window title must not control its layout.
hl.window_rule({match={class="^org.serpiero.ArcSteelSettings$"}, float=true, center=true})
bind("SUPER + I", "settings", "Configuration: Open Arc Steel settings")
hl.unbind("CTRL+SUPER+ALT+Slash")
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("python3 " .. string.format("%q", root .. "/ui/scripts/open-config.py") .. " " .. string.format("%q", root .. "/arc-steel/theme.lua")), {description="Configuration: Edit Arc Steel keybinds"})
-- Fixed dark palette: inherited light/dark and palette-family actions are inapplicable.
hl.unbind("CTRL + SUPER + SHIFT + D")
hl.unbind("CTRL + SUPER + P")
hl.unbind("CTRL + SUPER + ALT + T")

-- Keep one documented binding for these actions in this profile. Base bindings
-- remain untouched for other profiles; paired shortcut/fallback handlers remain.
for _, key in ipairs({
 "SUPER + B", "SUPER + O",          -- aliases of SUPER+A: left sidebar
 "SUPER + ALT + Space",            -- alias of SUPER+V: float/tile
 "SUPER + ALT + R",                -- alias of SUPER+SHIFT+R: region recording
 "SHIFT + SUPER + ALT + Slash",    -- upstream welcome/setup window
 "SUPER + ALT + F11", "SUPER + ALT + F12", -- upstream notification test actions
}) do hl.unbind(key) end

local overrides = root .. "/ui/settings/hypr-overrides.lua"
local f = io.open(overrides,"r")
if f then f:close(); dofile(overrides) end

