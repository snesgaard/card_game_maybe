local nw = require "nodeworks"
local gamestate = require "gamestate"
local component = require "component"
local imtween = require "im_tween"
local render = require "render"

local function actor_position(index)
    local w, h = gfx.getWidth(), gfx.getHeight()
    local mid = spatial(w / 2, h, 0, 0):move(0, -40)
    if index == 0 then return mid end
    local s = index < 0 and -1 or 1
    return mid:move(s * (200 + 60 * (math.abs(index) - 1)), 0)
end

local function draw_actor(x, y)
    local w, h = 50, 200
    gfx.rectangle("fill", x - w / 2, y - h, w, h)
end

local id = {
    player = {},
    enemy = {},
    field = {}
}

local actions = {
    attack = "attack",
    defend = "defend",
    heal = "heal"
}

local layer_id = {
    background = {},
    field = {},
    overlay = {}
}

local layer_order = {
    layer_id.background,
    layer_id.field,
}


local function initial_gamestate()
    return gamestate.state()
        :set(component.health, id.player, 10)
        :set(component.health, id.enemy, 20)
        :set(component.max_health, id.player, 10)
        :set(component.max_health, id.enemy, 20)
        :set(component.party_order, id.field, {id.player})
        :set(component.enemy_order, id.field, {id.enemy})
end

local function draw_gamestate(entity)
    local gamestate = entity:get(component.gamestate)
    local party_order = gamestate:get(component.party_order, id.field)
    local enemy_order = gamestate:get(component.enemy_order, id.field)

    gfx.setColor(0.2, 0.4, 0.8)
    for index, id in ipairs(party_order) do
        local position = actor_position(-index)
        draw_actor(position.x, position.y)
    end
    gfx.setColor(0.8, 0.4, 0.2)
    for index, id in ipairs(enemy_order) do
        local position = actor_position(index)
        draw_actor(position.x, position.y)
    end
end

local function setup_visual_state(gamestate)
    local visual_state = nw.ecs.entity()

    visual_state:entity(layer_id.field)
        :set(nw.component.layer_type, draw_gamestate)
        :set(component.gamestate, gamestate)

    visual_state:entity(layer_id.background)
        :set(nw.component.layer_type, render.layer_type.color)
        :set(nw.component.color, 0.1, 0.1, 0.1)

    return visual_state
end

return function(ctx)
    ctx.gamestate = initial_gamestate()
    ctx.pos_tweens = imtween()
        :set_speed(200)
    ctx.visual_state = setup_visual_state(ctx.gamestate)

    local draw = ctx:listen("draw")
        :foreach(
            function()
                local layer_entities = List.map(
                    layer_order,
                    function(id) return ctx.visual_state:entity(id) end
                )
                render.render(layer_entities)
            end)


    while ctx.alive do
        ctx:yield()
    end
end
