local nw = require "nodeworks"
local gamestate = require "gamestate"
local component = require "component"
local imtween = require "im_tween"
local render = require "render"
local ui = require "ui"

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
    cards = {},
    overlay = {}
}

local layer_order = {
    layer_id.background,
    layer_id.field,
    layer_id.cards
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

local function card_keymap()
    local keymap = {left = {}, right = {}}

    for i = 1, 10 do
        keymap.left[i] = i - 1
        keymap.right[i] = i + 1
    end

    keymap.left[1] = 10
    keymap.right[10] = 1

    keymap.left.default = 10
    keymap.right.default = 1

    return keymap
end

local function draw_card_layer(layer, ctx)
    gfx.push("all")
    render.push.state(layer)

    local body = render.card_size()
    local dx = body.w / 2

    gfx.setColor(1, 1, 1)
    gfx.rectangle(
        "fill", spatial(gfx.getWidth() / 2, 0, 0, gfx.getHeight()):expand(2, 0):unpack()
    )

    for i = 1, (ctx.count or 10) do
        local x, y = ctx.pos_tweens:get(i):unpack()
        if i == ctx.selected then
            gfx.setColor(0, 1, 0)
            gfx.rectangle("fill", body:move(x, y):expand(10, 10):unpack())
        end
        gfx.setColor(1, 1, 1)
        render.draw_card(x, y)
    end
    gfx.pop()
end

local function selection_offset(index, selected)
    if not selected then return vec2() end
    local body = render.card_size()
    local dx = body.w / 2 + 10

    local diff = math.abs(index - selected)
    if index < selected then return vec2(-dx / diff, 0) end
    if selected < index then return vec2(dx / diff, 0) end

    return vec2(0, -150)
end

local function card_selection_update(ctx, dt)
    local count = ctx.count or 10
    local w, h = gfx.getWidth(), gfx.getHeight()
    local mid = spatial(w * 0.5, h, 0, 0)

    local body = render.card_size()
    local dx = body.w / 2
    local last_x = body.w + dx * (count - 1)
    local mid_x = last_x / 2
    local ox = mid.x - mid_x


    for i = 1, count do
        local px = vec2(dx * (i - 1) + ox, 850)
        local ox = selection_offset(i, ctx.selected)
        ctx.pos_tweens:move_to(i, px + ox, 0.1)
    end
end

local function card_selection(ctx)
    ctx.selected = 1
    ctx.count = 10

    local keypressed = ctx:listen("keypressed"):collect()
    local update = ctx:listen("update"):collect()
    local degrade = ctx:listen("keypressed")
        :filter(function(key) return key == "d" end)
        :latest()

    while ctx.alive do
        for _, event in ipairs(keypressed:pop()) do
            ctx.selected = ui.key(ctx.selected, card_keymap(), unpack(event))
        end

        if degrade:pop() then ctx.count = ctx.count -1 end

        for _, event in ipairs(update:pop()) do
            card_selection_update(ctx, unpack(event))
        end


        ctx:yield()
    end
end

local function setup_visual_state(gamestate)
    local visual_state = nw.ecs.entity()

    visual_state:entity(layer_id.field)
        :set(nw.component.layer_type, draw_gamestate)
        :set(component.gamestate, gamestate)

    visual_state:entity(layer_id.background)
        :set(nw.component.layer_type, render.layer_type.color)
        :set(nw.component.color, 0.5, 0.5, 0.5)

    visual_state:entity(layer_id.cards)
        :set(nw.component.layer_type, draw_card_layer)

    return visual_state
end

return function(ctx)
    ctx.gamestate = initial_gamestate()
    ctx.pos_tweens = imtween()
        :set_speed(1000)
    ctx.visual_state = setup_visual_state(ctx.gamestate)

    local draw = ctx:listen("draw")
        :foreach(
            function()
                local layer_entities = List.map(
                    layer_order,
                    function(id) return ctx.visual_state:entity(id) end
                )
                render.render(layer_entities, ctx)
            end)
    local update = ctx:listen("update")
        :foreach(function(dt) ctx.pos_tweens:update(dt) end)


    while ctx.alive do
        card_selection(ctx)
        ctx:yield()
    end
end
