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

function rh.keymap_from_list(items, decrease, increase, wrap)
    local keymap = {
        [decrease] = {},
        [increase] = {}
    }

    for index, item in ipairs(items) do
        keymap[decrease][item] = items[index - 1]
        keymap[increase][item] = items[index + 1]
    end

    local head, tail = List.head(items), List.tail(items)
    keymap[decrease][head] = tail
    keymap[increase][tail] = head

    keymap[decrease].default = tail
    keymap[increase].default = head

    return keymap
end

return setmetatable(rh, rh)
