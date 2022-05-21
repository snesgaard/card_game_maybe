local field_render = require "game.field_render"
local constants = require "game.constants"
local component = require "component"
local render = require "render"

local actor_status = {}

function actor_status.init()
    return dict()
end

function actor_status.step(ctx, state, gamestate)
    return state:set("gamestate", gamestate)
end

local text_opt = {
    font = render.create_font(20),
    align = "center",
    valign = "center"
}

local function draw_health_bar(ctx, gs, index, id)
    local pos = field_render.actor_position(index)

    local health = gs:get(component.health, id)
    local max_health = gs:get(component.max_health, id)

    if not health or not max_health then return end

    local tween_health = ctx:tween("health"):move_to(id, health)

    local bar = spatial(pos.x, pos.y, 0, 0):down(0, 15):expand(150, 15)

    local s = tween_health / math.max(max_health, 1)

    gfx.setColor(render.theme.dark_red)
    gfx.rectangle("fill", bar:expand(6):unpack(4))
    gfx.setColor(render.theme.red)
    if s > 0 then
        gfx.rectangle("fill", bar.x, bar.y, bar.w * s, bar.h, 4)
    end

    local str = string.format("%s/%s", health, max_health)
    gfx.setColor(render.theme.white)
    render.draw_text(str, bar.x, bar.y, bar.w, bar.h, text_opt, sx, sy)
end

function actor_status.draw(ctx, state)
    if not state.gamestate then return end

    local gs = state.gamestate

    local formation = gs:get(component.formation, constants.id.field)

    for index, id in pairs(formation) do
        draw_health_bar(ctx, gs, index, id)
    end
end

return actor_status
