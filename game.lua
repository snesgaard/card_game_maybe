local nw = require "nodeworks"
local gamestate = require "gamestate"
local component = require "component"
local imtween = require "tween.im_tween"
local render = require "render"
local ui = require "ui"
local card_select = require "ui.card_select"
local instruction = require "ui.instruction_box"
local cards = require "cards"
local mechanics = require "mechanics"

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
    player = "player",
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
                {cards.shovel, cards.shovel, cards.shovel, cards.graceful_charity},
                function(card) return cards.instance(card) end
            )
        )
        :set(component.graveyard, id.player, list())
        :set(
            component.draw,
            id.player,
            List.map(
                {cards.cure, cards.cure, cards.cure, cards.cure, cards.cure},
                function(card) return cards.instance(card) end
            )
        )
end

local function ui_layer(layer, self)
    self.ui.card_select:draw()
    self.ui.instruction:draw()

    if self.ui.confirm then
        self.ui.confirm:draw(gfx.getWidth() / 2, gfx.getHeight() / 2 + 50)
    end
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

local game = {}
game.__index = game

game.id = id

function game.create(ctx)
    local w, h = gfx.getWidth(), gfx.getHeight()

    local this = {
        gamestate = initial_gamestate(),
        visualstate = initial_visualstate(),
        ui = {
            card_select = card_select(id.player),
            instruction = instruction()
                :set_shape(spatial(0, 0, w, 50))
                :set_bg_color{1, 1, 1, 0.5},
        },
        ctx = ctx
    }

    for _, ui in pairs(this.ui) do
        if ui.gamestate_step then ui:gamestate_step(this.gamestate) end
    end

    return setmetatable(this, game)
end

function game:step(...)
    local hist = gamestate.history(self.gamestate):advance(...)
    self.gamestate = hist:tail()

    for _, ui in pairs(self.ui) do
        if ui.gamestate_step then ui:gamestate_step(self.gamestate) end
    end

    return hist
end

function game:draw()
    for _, id in ipairs(layer_order) do
        render.draw_layer(self.visualstate:entity(id), self)
    end
end

function game:update(dt)
    for _, ui in pairs(self.ui) do
        if ui.update then ui:update(dt) end
    end
end

function game:pick_card_from_hand(count, slack, message)
    self.ui.card_select:configure{count=count, slack=slack, message=message}

    local keypressed = self.ctx:listen("keypressed"):collect()
    local mousemoved = self.ctx:listen("mousemoved"):collect()
    local mousepressed = self.ctx:listen("mousepressed"):collect()

    while self.ctx.alive and not self.ui.card_select:done() do
        for _, event in ipairs(keypressed:pop()) do
            if self.ui.card_select:keypressed(unpack(event)) then
                event.consumed = true
            end
        end

        for _, event in ipairs(mousemoved:pop()) do
            if self.ui.card_select:mousemoved(unpack(event)) then
                event.consumed = true
            end
        end

        for _, event in ipairs(mousepressed:pop()) do
            if self.ui.card_select:mousepressed(unpack(event)) then
                event.consumed = true
            end
        end

        self.ctx:yield()
    end

    return self.ui.card_select:pop()
end

function game:press_to_confirm(message)
    local keypressed = self.ctx:listen("keypressed"):collect()

    self.ctx.game.ui.confirm = ui.confirm():set_message(message)

    while self.ctx.alive and not self.ctx.game.ui.confirm:is_done() do
        for _, event in ipairs(keypressed:pop()) do
            if self.ctx.game.ui.confirm:keypressed(unpack(event)) then
                event.consumed = true
            end
        end
        self.ctx:yield()
    end

    local c = self.ctx.game.ui.confirm
    self.ctx.game.ui.confirm = nil

    return c:pop()
end

function game:play_card(user, card)
    self:step(mechanics.card.begin_card_play, user, card)

    if card.effect then card.effect(self, user) end

    self:step(mechanics.card.end_card_play, user)
end

return game.create
