-- Keep a virtual output available when the configured physical outputs are absent.
-- Physical output names belong in the local layout, not in this portable helper.
return function(physical_outputs, fallback)
    assert(type(physical_outputs) == "table", "Expected physical output names")
    assert(type(fallback) == "table" and type(fallback.output) == "string"
        and fallback.output ~= "", "Expected an explicit fallback output")
    local physical_available = false
    for _, name in ipairs(physical_outputs) do
        if name ~= fallback.output and hl.get_monitor(name) ~= nil then
            physical_available = true
            break
        end
    end
    local options = {}
    for key, value in pairs(fallback) do options[key] = value end
    options.disabled = physical_available
    hl.monitor(options)
    return physical_available
end
