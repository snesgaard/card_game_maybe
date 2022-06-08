local layout_renderer = class()

function layout_renderer.init(tween_time)
    return dict{
        layout = dict(),
        order = nil,
        position = dict(),
        tween_time = tween_time or 0.1
    }
end

function layout_renderer.update_layout(state, layout, overwrite_order)
    local next_state = state:set("layout", dict(layout))
    return next_state
end

function layout_renderer.update_position(state, position)
    return state:set("position", position)
end

function layout_renderer.mouse(ctx, state, x, y)
    local hit = nil

    for _, id in ipairs(state.order) do
        local layout = state.layout[id]
        local pos = state.position[id] or vec2()
        if layout and layout:move(pos.x, pos.y):point_inside(x, y) then
            hit = id
        end
    end

    return hit
end

function layout_renderer.get_world_shape(ctx, state, id)
    local layout = ctx:tween("spatial"):get(id)
    local position = ctx:tween("position"):get(id)

    if not layout then return end
    if not position then return layout end

    return layout:move(position.x, position.y)
end

local function handle_element_draw(ctx, state, id, element_draw)
    if not element_draw then return end
    local pos = state.position[id] or vec2()

    local rect = state.layout[id]
    if not rect then return end

    local pos = ctx:tween("position"):move_to(id, pos, state.tween_time)
    local rect = ctx:tween("spatial"):move_to(id, rect, state.tween_time)

    gfx.push("all")
    gfx.translate(pos.x, pos.y)
    element_draw(ctx, state, rect, id)
    gfx.pop()
end

local function order_from_layout(ctx, layout)
    local positions = layout:map(function(id)
        return ctx:tween("position"):get(id) or vec2()
    end)
    local spatials = layout:map(function(id)
        return ctx:tween("spatial"):get(id) or spatial()
    end)

    local function cmp(a, b)
        local x_a = positions[a].x + spatials[a].x
        local x_b = positions[b].x + spatials[b].x
        return x_a < x_b
    end

    local order = layout:keys():sort(cmp)

    return order
end

function layout_renderer.draw(ctx, state, element_draw)
    local order = state.order or order_from_layout(ctx, state.layout)

    for _, id in ipairs(order) do
        handle_element_draw(ctx, state, id, element_draw)
    end
end

return layout_renderer
