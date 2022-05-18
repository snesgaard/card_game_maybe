local component = require "component"
local constants = require "game.constants"
local render = require "render"

local hand_render = class()

function hand_render.create()
    return setmetatable({}, hand_render)
end

function hand_render:set(hand, selected, highlight)
    self.state = {
        hand = hand,
        selected = selected,
        highlight = highlight
    }
    return self
end

return card_select.create
