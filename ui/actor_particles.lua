local field_render = require "game.field_render"
local component = require "component"
local constants = require "game.constants"

local actor_particles = {}

function actor_particles.init()
    return dict{
        entities = {}
    }
end

function actor_particles.update(ctx, state, dt, ...)
    for _, entity in ipairs(state.entities) do
        entity.particles:update(dt)
    end

    for i = #state.entities, 1, -1 do
        local entity = state.entities[i]
        if entity.particles:getCount() == 0 then
            table.remove(state.entities, i)
        end
    end
end

function actor_particles.emit(ctx, state, args, position)
    local entity = {
        particles = particles(args),
        position = position or vec2()
    }
    table.insert(state.entities, entity)
end

function actor_particles.draw(ctx, state)
    for _, entity in ipairs(state.entities) do
        local pos = entity.position or vec2()
        local particles = entity.particles
        gfx.draw(particles, pos.x, pos.y)
    end
end

function actor_particles.step(ctx, state, gamestate)
    return state:set("gamestate", gamestate)
end


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

function actor_particles.impact(ctx, state, id)
    if not state.gamestate then return end

    local actor_position = field_render.compute_all_actor_position(state.gamestate)
    local pos = actor_position[id]

    if not pos then return end

    local master = state.gamestate:get(component.master, id)

    local args = dict(args)
        :set("dir", master == constants.id.player and -math.pi * 3 / 4  or -math.pi / 4)

    return actor_particles.emit(ctx, state, args, pos - vec2(0, 50))
end

return actor_particles
