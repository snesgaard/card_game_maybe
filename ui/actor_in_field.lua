local component = require "component"
local constants = require "game.constants"
local field_render = require "game.field_render"
local mechanics = require "mechanics"

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

actor_in_field[mechanics.combat.spawn_minion] = function(ctx, state, gamestate, step)
    local pos = field_render.actor_position(step.info.index)
    ctx:tween("position"):warp_to(step.info.id, pos)
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

local function draw_actor(ctx, state, index, id)
    local formation = state.formation
    local animation = state.animation or {}
    local master = state.master or {}

    local pos = field_render.actor_position(index)
    local anime = (animation[id] or {}).idle
    local s = master[id] == constants.id.player and 1 or -1

    local pos = ctx:tween("position"):ensure(id, pos)
    local frame = ctx:animation():ensure(id, anime)

    gfx.setColor(1, 1, 1)
    if frame then
        frame:draw(
            "body", pos.x, pos.y, 0, s * constants.scale, constants.scale
        )
    else
        gfx.push()
        gfx.translate(pos.x, pos.y)
        local w, h = 100, 200
        gfx.rectangle("fill", -w / 2, -h, w, h)
        gfx.pop()
    end
end

function actor_in_field.draw(ctx, state)
    local formation = state.formation
    local animation = state.animation or {}
    local master = state.master or {}

    for index, id in pairs(formation) do
        draw_actor(ctx, state, index, id)
    end

    draw_actor(ctx, state, -constants.max_positions - 1, constants.id.player)
    draw_actor(ctx, state, constants.max_positions + 1, constants.id.enemy)
end

function actor_in_field.reset_position(ctx, state, id)
    if not state.formation then return end

    local index = state.formation:find(id)
    if not index then return end
    ctx:tween("position"):move_to(id, field_render.actor_position(index))
end

function actor_in_field.animate_attack(ctx, state, id)
    if not state.formation then return end

    local index = state.formation:find(id)
    if not index then return end
    local pos = field_render.actor_position(index)
    local attack_offset = index < 0 and vec2(50, 0) or vec2(-50, 0)
    ctx:tween("position"):move_to(id, attack_offset + pos)

    return state, function() return ctx:tween("position"):done(id) end
end

return actor_in_field
