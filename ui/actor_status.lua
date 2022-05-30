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

local frame = get_atlas("art/characters"):get_frame("status_bar/attack_health")
local master_frame = get_atlas("art/characters"):get_frame("status_bar/master")


local function draw_health_bar(ctx, id, bar, health, max_health)
    local tween_health = ctx:tween("health"):move_to(id, health)
    local s = tween_health / math.max(max_health, 1)

    gfx.setColor(render.theme.dark)
    gfx.rectangle("fill", bar:unpack())
    gfx.setColor(render.theme.red)
    if s > 0 then
        local dw = (1 - s) * bar.w
        gfx.rectangle("fill", bar.x + dw, bar.y, bar.w * s, bar.h)
    end
end

local function draw_health_text(health, max_health, bar)
    local str = string.format("%s/%s", health, max_health)
    gfx.setColor(render.theme.white)
    local sx = 1 / constants.scale
    render.draw_text(health, bar.x, bar.y, bar.w, bar.h, text_opt, sx)
end

local function draw_attack(attack, slice)
    local sx = 1 / constants.scale
    gfx.setColor(render.theme.white)
    render.draw_text(attack or "?", slice.x, slice.y, slice.w, slice.h, text_opt, sx)
end

local function draw_status_bar(ctx, gs, index, id)
    local pos = field_render.actor_position(index)
    local health = gs:get(component.health, id)
    local max_health = gs:get(component.max_health, id)
    local attack = gs:get(component.attack, id)

    if not health or not max_health then return end

    local anchor = frame.slices.anchor or spatial()
    local center = -anchor:center()

    gfx.push()
    gfx.translate(pos.x, pos.y)
    gfx.setColor(1, 1, 1)
    --gfx.circle("fill", 0, 0, 5)
    gfx.scale(constants.scale)
    gfx.translate(center:unpack())

    local healthbar_slice = frame.slices.healthbar
    draw_health_bar(ctx, id, healthbar_slice, health, max_health)
    gfx.setColor(1, 1, 1)
    frame:draw(0, 0)
    draw_attack(attack, frame.slices.attack)
    draw_health_text(health, max_health, frame.slices.healthtext)

    gfx.pop()
end

local function draw_master_bar(ctx, gs, index, id)
    local pos = field_render.actor_position(index)
    local health = gs:get(component.health, id)
    local max_health = gs:get(component.max_health, id)
    local attack = gs:get(component.attack, id)

    if not health or not max_health then return end

    local anchor = master_frame.slices.anchor or spatial()
    local center = -anchor:center()

    gfx.push()
    gfx.translate(pos.x, pos.y)
    gfx.setColor(1, 1, 1)
    --gfx.circle("fill", 0, 0, 5)
    gfx.scale(constants.scale)
    gfx.translate(center:unpack())

    local healthbar_slice = master_frame.slices.healthbar
    draw_health_bar(ctx, id, healthbar_slice, health, max_health)
    gfx.setColor(1, 1, 1)
    master_frame:draw(0, 0)
    draw_health_text(health, max_health, master_frame.slices.healthtext)

    gfx.pop()
end

function actor_status.draw(ctx, state)
    if not state.gamestate then return end

    local gs = state.gamestate

    local formation = gs:get(component.formation, constants.id.field)

    for index, id in pairs(formation) do
        draw_status_bar(ctx, gs, index, id)
    end

    draw_master_bar(ctx, gs, -constants.max_positions - 1, constants.id.player)
    draw_master_bar(ctx, gs, constants.max_positions + 1, constants.id.enemy)
end

return actor_status
