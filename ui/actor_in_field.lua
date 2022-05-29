local component = require "component"
local constants = require "game.constants"
local field_render = require "game.field_render"

local actor_in_field = {}

function actor_in_field.actor_position(index)
    local w, h = gfx.getWidth(), gfx.getHeight()

    local pos = vec2(w / 2, h / 2)
    local base_offset = 75
    local offset = 200
    if index < 0 then
        pos.x = pos.x - base_offset
    elseif index > 0 then
        pos.x = pos.x + base_offset
    end

    pos.x = pos.x + offset * index

    return pos
end

function actor_in_field.init() return dict() end

function actor_in_field.set_formation(ctx, state, formation)
    return state:set("formation", formation)
end

function actor_in_field.set_types(ctx, state, types)
    return state:set("animation", types)
end

function actor_in_field.step(ctx, state, gamestate)
    local formation = gamestate:ensure(component.formation, constants.id.field)
    local animation = dict()
    local master = dict()

    local entities = list(constants.id.player, constants.id.enemy) + formation:values()

    for _, id in ipairs(entities) do
        local t = gamestate:get(component.type, id) or dict()
        animation[id] = t.sprite or dict()
        master[id] = gamestate:get(component.master, id)
    end

    return state
        :set("formation", formation)
        :set("animation", animation)
        :set("master", master)
end

function actor_in_field.draw(ctx, state)
    local formation = state.formation
    local animation = state.animation or {}
    local master = state.master or {}

    for index, id in pairs(formation) do
        local pos = field_render.actor_position(index)
        local anime = (animation[id] or {}).idle
        local s = master[id] == constants.id.player and 1 or -1

        local pos = ctx:tween("position"):ensure(id, pos)
        local frame = ctx:animation():ensure(id, anime)

        frame:draw(
            "body", pos.x, pos.y, 0, s * constants.scale, constants.scale
        )
    end

    local pos = field_render.actor_position(-constants.max_positions - 1)
    local frame = get_atlas("art/characters"):get_frame("chibdigger")
    frame:draw("body", pos.x, pos.y, 0, constants.scale)
end

return actor_in_field
