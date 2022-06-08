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

local function populate_keymap_list(keymap, items, decrease, increase, wrap)
    for index, item in ipairs(items) do
        keymap[decrease][item] = items[index - 1]
        keymap[increase][item] = items[index + 1]
    end

    local head, tail = List.head(items), List.tail(items)
    if tail and head then
        keymap[decrease][head] = tail
        keymap[increase][tail] = head
    end

    keymap[decrease].default = tail
    keymap[increase].default = head
end

function rh.keymap_from_list(items, decrease, increase, wrap)
    local keymap = {
        [decrease] = {},
        [increase] = {}
    }

    populate_keymap_list(keymap, items, decrease, increase, wrap)

    return keymap
end

local function connect_rows(keymap, lower, upper, decrease, increase)
    if not lower or not upper then return end
    local low_count = #lower
    local up_count = #upper

    for index, item in ipairs(lower) do
        keymap[decrease][item] = upper[1]
    end

    for index, item in ipairs(upper) do
        keymap[increase][item] = lower[1]
    end
end

function rh.keymap_from_matrix(matrix, wrap)
    local keymap = {
        left = {},
        right = {},
        up = {},
        down = {}
    }

    for _, row in ipairs(matrix) do
        populate_keymap_list(keymap, row, "left", "right", wrap)
    end

    for index, row in ipairs(matrix) do
        local lower = row
        local upper = matrix[index + 1]
        connect_rows(keymap, lower, upper, "down", "up")
    end

    if wrap then
        connect_rows(keymap, matrix[#matrix], matrix[1], "down", "up")
    end

    return keymap
end

return setmetatable(rh, rh)
