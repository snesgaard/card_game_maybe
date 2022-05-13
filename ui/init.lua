local rh = {}

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

function rh.key(cursor, keymap, key)
    if not cursor then return end
    local km = keymap[key]
    if not km then return end
    return km[cursor]
end

return setmetatable(rh, rh)
