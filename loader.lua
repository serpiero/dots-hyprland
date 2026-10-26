-- The original Illogical Impulse config is loaded first. This is an optional visual layer.
local root = os.getenv("RICE_ROOT") or (os.getenv("HOME") .. "/.local/share/rice-profiles")
local profile = os.getenv("RICE_PROFILE_VERIFY")
if not profile then
    local f = io.open(root .. "/active", "r")
    if f then profile = f:read("*l"); f:close() end
end
local runtime = root .. "/web-runtime/bin:"
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if path:sub(1,#runtime) == runtime then path = path:sub(#runtime+1) end
hl.env("PATH", profile == "arc-steel" and (runtime .. path) or path)
local style = root .. "/arc-steel/application-style"
hl.env("XDG_CONFIG_HOME", profile == "arc-steel" and (style .. "/config") or (os.getenv("HOME") .. "/.config"))
hl.env("KDE_COLOR_SCHEME_PATH", profile == "arc-steel" and (style .. "/arc-steel.colors") or "")
hl.env("GTK2_RC_FILES", profile == "arc-steel" and (style .. "/gtk2.rc") or (os.getenv("GTK2_RC_FILES") or ""))
local data = os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
hl.env("XDG_DATA_DIRS", profile == "arc-steel" and (style .. "/share:" .. data) or data)
if profile == "arc-steel" then dofile(root .. "/arc-steel/theme.lua") end
dofile(root .. "/desktop-controls.lua")
hl.bind("CTRL+SUPER+ALT+P", hl.dsp.exec_cmd("python3 " .. root .. "/rice.py menu"), {description = "Configuration: Choose rice profile"})
