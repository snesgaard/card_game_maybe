local nw = require "nodeworks"
local gamestate = require "gamestate"
local component = require "component"
local imtween = require "im_tween"

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

local function initial_gamestate()
    return gamestate.state()
        :set(component.health, id.player, 10)
        :set(component.health, id.enemy, 20)
        :set(component.max_health, id.player, 10)
        :set(component.max_health, id.enemy, 20)
        :set(component.party_order, id.field, {id.player})
        :set(component.enemy_order, id.field, {id.enemy})
end

local function draw_gamestate(ctx, gamestate)
    local party_order = gamestate:get(component.party_order, id.field)
    local enemy_order = gamestate:get(component.enemy_order, id.field)

    gfx.setColor(0.2, 0.4, 0.8)
    for index, id in ipairs(party_order) do
        local position = actor_position(-index)
        local offset = ctx.pos_tweens:ensure(id, vec2())
        draw_actor(position.x + offset.x, position.y + offset.y)
    end
    gfx.setColor(0.8, 0.4, 0.2)
    for index, id in ipairs(enemy_order) do
        local position = actor_position(index)
        draw_actor(position.x, position.y)
    end
end

local function animate_attack(ctx)
    ctx.pos_tweens:move_to(id.player, vec2(100, 0))
    while not ctx.pos_tweens:is_done(id.player) do ctx:yield() end
    ctx.pos_tweens:move_to(id.player, vec2(0, 0))
    while not ctx.pos_tweens:is_done(id.player) do ctx:yield() end
end

local function select_player_action(ctx)
    local draw = ctx:listen("draw"):collect()
    local interrupt = ctx:listen("keypressed")
        :filter(function(key) return key == "a" end)
        :latest()

    while not interrupt:peek() and ctx:is_alive() do
        for _, _ in ipairs(draw:peek()) do
            gfx.setColor(0.5, 0.5, 0.5)
            gfx.rectangle("fill", 0, 0, 100, 100)
        end
        ctx:yield()
    end
end

return function(ctx)
    ctx.gamestate = initial_gamestate()
    ctx.pos_tweens = imtween()
        :set_speed(200)

    local draw = ctx:listen("draw")
        :foreach(function() draw_gamestate(ctx, ctx.gamestate) end)

    local update_tween = ctx:listen("update")
        :foreach(function(dt) ctx.pos_tweens:update(dt) end)

    local cooldown = ctx:listen("update")
        :reduce(function(agg, dt) return agg - dt end, 0.2)

    local perform_attack = ctx:listen("keypressed")
        :filter(function(key) return key == "a" end)
        :foreach(function() cooldown:reset() end)
        :latest()


    while ctx.alive do
        local player_action = select_player_action(ctx)
        animate_attack(ctx)
        --local enemy_action = select_enemy_action(ctx)
        ctx:yield()
    end
end
