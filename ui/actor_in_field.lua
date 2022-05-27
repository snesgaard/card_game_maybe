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
    local formation = gamestate:get(component.formation, constants.id.field)
    local animation = dict()

    for _, id in pairs(formation) do
        local t = gamestate:get(component.type, id) or dict()
        animation[id] = t.sprite or dict()
    end

    return state
        :set("formation", formation)
        :set("animation", types)
end

function actor_in_field.draw(ctx, state)
    local formation = state.formation
    local animation = state.animation or {}
end

return actor_in_field
