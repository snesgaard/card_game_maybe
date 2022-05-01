local component = require "component"
local imtween = require "im_tween"

local function get_latest_state(ctx, gamestate)
    print("step")
    ctx.gamestate = gamestate
end

local function draw(ctx)
    local gs = ctx.gamestate
    local id = ctx.id
    if not gs or not id then return end

    local hp = gs:get(component.health, id)
    local max_hp = gs:get(component.max_health, id)
    local lag_hp = ctx.tween:move_to(id, hp)

    local layout = spatial(20, 20, 200, 20)
    local s = lag_hp / max_hp
    gfx.setColor(0.5, 0.5, 0.5)
    gfx.rectangle("fill", layout:unpack())
    gfx.setColor(1, 1, 1)
    gfx.rectangle("fill", layout.x, layout.y, math.floor(layout.w * s), layout.h)
end

local function update(ctx, dt)
    ctx.tween:update(dt)
end

return function(ctx, id)
    ctx.id = id
    ctx.tween = imtween()
        :set_speed(10)
        :set_ease(ease.inQuad)
    while ctx.alive do
        ctx:visit_event("gamestate_step", get_latest_state)
        ctx:visit_event("update", update)
        ctx:visit_event("draw:ui", draw)
        ctx:yield()
    end

end
