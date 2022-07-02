local ui = require "ui"
local nw = require "nodeworks"

local circle = gfx.prerender(20, 10, function(w, h)
    gfx.rectangle("fill", 0, 0, w, h)
end)

local args = {
    image = circle,
    buffer = 20,
    emit = 20,
    lifetime = 0.75,
    speed = {400, 2000},
    spread = math.pi * 0.2,
    damp = 5,
    dir = -math.pi / 4,
    acceleration = {0, 4000},
    relative_rotation = true
}

return function(ctx)
    local particle_ui = gui(ui.actor_particles)
    local draw = ctx:listen("draw"):collect()
    local update = ctx:listen("update"):collect()
    local keypressed = ctx:listen("keypressed"):collect()
    local log = ctx:listen("log"):foreach(print)

    particle_ui("emit", args, vec2(200, 200))

    while ctx.alive do
        draw:pop():foreach(function() particle_ui:draw() end)
        update:pop():foreach(function(dt) particle_ui:update(unpack(dt)) end)

        ctx:yield()
    end
end
