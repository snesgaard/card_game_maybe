local mechanics = require "mechanics"

local card = {}

function card.instance(card_type)
    if card_type == nil then
        error("card type was nil")
    end
    card_type.__index = card_type
    return setmetatable({}, card_type)
end

card.theme = {
    normal = gfx.hex2color("f2eee3"),
    key = gfx.hex2color("a9dc54")
}

function card.minion(data)
    data.type = "minion"
    return data
end

function card.skill(data)
    data.type = "skill"
    return data
end

local BASE = ...

function card.__index(t, k)
    return require(BASE .. "." .. k)
end

return setmetatable(card, card)
