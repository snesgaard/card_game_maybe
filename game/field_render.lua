local constants = require "game.constants"
local component = require "component"

local field_render = {}

function field_render.actor_position(index)
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

function field_render.party_position(index)
    return field_render.actor_position(-index)
end

function field_render.enemy_position(index)
    return field_render.actor_position(index)
end

function field_render.compute_all_actor_position(gamestate)
    local formation = gamestate:get(component.formation, constants.id.field)

    local actor_pos = {}

    for index, id in pairs(formation) do
        actor_pos[id] = field_render.actor_position(index)
    end

    return actor_pos
end

function field_render.draw_actor(game, id, x, y, s)
    local s = s or 1
    local type = game.gamestate:get(component.type, id)
    gfx.setColor(1, 1, 1)
    gfx.push()

    gfx.translate(x, y)
    if not type then
        gfx.rectangle("fill", -25, 0, 50, -200)
    else
        local image = type.sprite.idle
        image:head():draw("body", 0, 0, 0, s * 3, 3)
    end

    gfx.pop()
end

function field_render.draw(game)
    local f = game.gamestate:ensure(component.formation, constants.id.field)

    for index, id in pairs(f) do
        local pos = field_render.actor_position(index)
        local s = index < 0 and 1 or -1
        field_render.draw_actor(game, id, pos.x, pos.y, s)
    end
end

function field_render.draw_ui_actor(game, index, id)
    local pos = field_render.actor_position(index)
end

function field_render.draw_ui(game)
    local gs = game.gamestate
    local vs = game.visualstate

    local party_order = gs:get(component.party_order, constants.id.field)
    local enemy_order = gs:get(component.enemy_order, constants.id.field)
    local all_order = {}

    for index, id in pairs(party_order) do
        field_render.draw_ui_actor(game, -index, id)
    end

    for index, id in pairs(enemy_order) do
        field_render.draw_ui_actor(game, index, id)
    end
end

return field_render
