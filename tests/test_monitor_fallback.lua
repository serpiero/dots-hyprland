local configure = dofile("monitor-fallback.lua")
local available = {}
local applied
hl = {
    get_monitor = function(name) return available[name] end,
    monitor = function(options) applied = options end
}
local fallback = {output="HEADLESS", mode="preferred", scale=1, disabled=true}
assert(not configure({"PRIMARY", "SECONDARY"}, fallback))
assert(applied.disabled == false, "Sole virtual output must remain enabled")
assert(fallback.disabled == true, "Caller layout must not be mutated")
assert(applied.mode == "preferred" and applied.scale == 1)
available.PRIMARY = {}
assert(configure({"PRIMARY", "SECONDARY"}, fallback))
assert(applied.disabled == true, "Physical output can replace virtual output")
available = {SECONDARY = {}}
assert(configure({"PRIMARY", "SECONDARY"}, fallback))
assert(applied.disabled == true)
available = {HEADLESS = {}}
assert(not configure({"HEADLESS"}, fallback))
assert(applied.disabled == false, "Fallback cannot count as a physical output")
available = {}
assert(not configure({}, fallback))
assert(applied.disabled == false)
assert(not pcall(configure, {}, {output=""}))
print("PASS: absent/primary/secondary/fallback-only outputs, layout preservation and validation")
