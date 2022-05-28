local field_render = require "game.field_render"
local ui = require "ui"
local constants = require "game.constants"

local minion_spawn = {}

local images = {
    cursor_inactive = get_atlas("art/characters"):get_frame("spawn_cursor/inactive"),
    cursor_active = get_atlas("art/characters"):get_frame("spawn_cursor/active"),
}

local function draw_spawn(x, y, is_selected)
    gfx.setColor(1, 1, 1, 1)
    local im = is_selected and images.cursor_active or images.cursor_inactive
    im:draw("body", x, y, 0, constants.scale, constants.scale)
end

local function draw_spawns(indices, cursor)
    for _, index in ipairs(indices) do
        local pos = field_render.actor_position(index)
        draw_spawn(pos.x, pos.y, index == cursor)
    end
end

local function mouse_hitbox(indices)
    local hitboxes = {}

    for _, index in ipairs(indices) do
        local pos = field_render.actor_position(index)
        local w, h = 50, 150
        hitboxes[index] = spatial(pos.x - w / 2, pos.y - h, w, h)
    end

    return hitboxes
end

return function(game, indices)
    local keymap = ui.keymap_from_list(indices, "left", "right")
    local mouse_hitbox = mouse_hitbox(indices)

    local state = {cursor = List.head(indices)}

    local key_confirm = game.ctx:listen("keypressed")
        :map(function(key)
            if key == "space" and state.cursor then
                return true
            elseif key == "backspace" then
                return false
            end
        end)
        :filter(function(key) return key ~= nil end)

    local mouse_confirm = game.ctx:listen("mousepressed")
        :filter(function(x, y, button)
            return button == 1 and state.cursor
        end)
        :filter(function(x, y)
            for index, hb in pairs(mouse_hitbox) do
                if hb:point_inside(x, y) then return index end
            end
        end)
        :map(function() return true end)

    local confirm = key_confirm:merge(mouse_confirm):latest()

    local select = game.ctx:listen("keypressed")
        :map(function(key)
            return ui.key(state.cursor or "default", keymap, key)
        end)
        :foreach(function(next_cursor)
            state.cursor = next_cursor or state.cursor
        end)

    local mousemoved = game.ctx:listen("mousemoved")
        :map(function(x, y)
            for index, hb in pairs(mouse_hitbox) do
                if hb:point_inside(x, y) then return index end
            end
        end)
        :foreach(function(next_cursor)
            state.cursor = next_cursor or state.cursor
        end)

    local draw = game.ctx:listen("draw"):collect()

    while game.ctx.alive and confirm:peek() == nil do
        for _, _ in ipairs(draw:pop()) do
            draw_spawns(indices, state.cursor)

            for _, hb in pairs(mouse_hitbox) do
                --gfx.rectangle("line", hb:unpack())
            end
        end
        game.ctx:yield()
    end

    if confirm:peek() then return state.cursor end
end
