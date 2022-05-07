local field_render = {}

function field_render.entity_position(index)
    local w, h = gfx.getWidth(), gfx.getHeight()
    local mid = spatial(w / 2, h / 2)
    local base_offset = 200
    local offset = 100
    if index < 0 then
        mid = mid:move(-base_offset)
    elseif index > 0 then
        mid = mid:move(base_offset)
    end

    return mid + base_offset + offset * index
end

function field_render.party_position(index)
    return field_render.entity_position(-index)
end

function field_render.enemy_position(index)
    return field_render.entity_position(index)
end

function field_render.draw(gamestate)

end

return field_render
