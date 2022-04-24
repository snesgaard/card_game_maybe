local nw = require "nodeworks"

local function handle_key(selected, keymap, key)
    local km = keymap[key]
    if not km then return selected end
    return km[selected] or selected
end

local function key(selected, keymap, key)
    return handle_key(selected, keymap, key)
end

local function move_to(dst, to, speed)

end

return {key=key}
