local nw = require "nodeworks"
local gamestate = require "gamestate"
local component = require "component"
local imtween = require "tween.im_tween"
local render = require "render"
local ui = require "ui"
local card_select = require "ui.card_select"
local cards = require "cards"

local function actor_position(index)
    local w, h = gfx.getWidth(), gfx.getHeight()
    local mid = spatial(w / 2, h, 0, 0):move(0, -400)
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
    ui = {},
    overlay = {},
}

local layer_order = {
    layer_id.background,
    layer_id.field,
    layer_id.ui
}


local function initial_gamestate()
    return gamestate.state()
        :set(component.health, id.player, 10)
        :set(component.health, id.enemy, 20)
        :set(component.max_health, id.player, 10)
        :set(component.max_health, id.enemy, 20)
        :set(component.party_order, id.field, {id.player})
        :set(component.enemy_order, id.field, {id.enemy})
        :set(
            component.hand,
            id.player,
            List.map(
                {cards.shovel, cards.shovel, cards.shovel, cards.cure},
                function(card) return cards.instance(card) end
            )
        )
end

local function ui_layer(layer, ctx)
    ctx.ui.card_select:draw()
end

local function initial_visualstate()
    local vs = nw.ecs.entity()

    vs:entity(layer_id.background)
        :set(nw.component.layer_type, render.layer_type.color)
        :set(nw.component.color, 0.5, 0.5, 0.5)

    vs:entity(layer_id.ui)
        :set(nw.component.layer_type, ui_layer)

    return vs
end

local function draw_visual_state(ctx)
    for _, id in ipairs(layer_order) do
        render.draw_layer(ctx.visualstate:entity(id), ctx)
    end
end

return function(ctx)
    ctx.gamestate = initial_gamestate()
    ctx.visualstate = initial_visualstate()
    ctx.ui = {
        card_select = card_select(id.player)
    }

    for _, ui in pairs(ctx.ui) do
        if ui.gamestate_step then ui:gamestate_step(ctx.gamestate) end
    end

    local draw = ctx:listen("draw")
        :foreach(function() return draw_visual_state(ctx) end)

    local update = ctx:listen("update")
        :foreach(function(dt)
            for _, ui in pairs(ctx.ui) do
                if ui.update then ui:update(dt) end
            end
        end)

    local keypressed = ctx:listen("keypressed"):collect()

    while ctx.alive do
        for _, event in ipairs(keypressed:pop()) do
            if ctx.ui.card_select:keypressed(unpack(event)) then
                event.consumed = true
            end
        end
        ctx:yield()
    end
end
