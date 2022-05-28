local nw = require "nodeworks"
local gamestate = require "gamestate"
local component = require "component"
local render = require "render"
local ui = require "ui"
local cards = require "cards"
local mechanics = require "mechanics"
local constants = require "game.constants"
local field_render = require "game.field_render"

local id = {
    player = "player",
    enemy = {},
    field = constants.field
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
end

local function handle_event_to_ui(ui, api_name, event_list)
    for _, event in ipairs(event_list) do
        if ui:action(api_name, unpack(event)) then
            event.consumed = true
        end
    end
end

local game = {}
game.__index = game

game.id = id

function game.create(ctx)
    local w, h = gfx.getWidth(), gfx.getHeight()

    local this = {
        gamestate = initial_gamestate(),
        ui = {
            card_select = gui(ui.card_select_better),
            target_select = gui(ui.target_select.ui),
            actor_status = gui(ui.actor_status)
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

    for _, step in ipairs(hist.steps) do
        self.gamestate = step.gamestate

        --for _, ui in pairs(self.ui) do
        --    ui:action(step.func, step.gamestate, step)
        --end

        for _, ui in pairs(self.ui) do
            ui:action(step.func, step.gamestate, step)
            ui:action("step", step.gamestate, step)
        end
    end

    return hist
end

function game:draw()
    local w, h = gfx.getWidth(), gfx.getHeight()
    gfx.setColor(0.5, 0.5, 0.5)
    gfx.rectangle("fill", 0, 0, w, h)
    gfx.setColor(1, 1, 1)
    field_render.draw(self)
    self.ui.actor_status:draw()
    self.ui.card_select:draw()
    self.ui.target_select:draw()
end

function game:update(dt)
    for _, ui in pairs(self.ui) do
        if ui.update then
            ui:update(dt)
        end
    end
end

function game:pick_card(count, strict)
    local keypressed = self.ctx:listen("keypressed"):collect()
    local ui = self.ui.card_select

    while self.ctx.alive and ui:action("peek"):size() ~= count do
        handle_event_to_ui(
            ui, "keypressed", keypressed:pop()
        )
        self.ctx:yield()
    end

    return ui:action("pop"):unpack()
end

function game:select_minion_spawn(user)
    local indices = {-4, -3, -2, -1, 1, 2, 3, 4}
    return ui.minion_spawn_select(self, indices)
end

function game:spawn_minion(minion, user)
    local id = {}
    local spawn_point = self:select_minion_spawn(user)

    if not spawn_point then return end

    if minion.entry then
        --if minion.entry(self, user, spawn_point) == false then return end
    end

    game:step(mechanics.minion.spawn, minion, id, user, spawn_point)
end

function game:pick_card_to_play()

    local cards = self.gamestate:get(component.hand, constants.id.player)
    local memory = self.ui.card_select.memory or list()

    local valid_memory = memory:filter(function(card)
        return cards:argfind(card)
    end)

    local keymap = ui.keymap_from_list(cards, "left", "right")

    local state = {cursor = valid_memory:head()}

    self.ui.card_select("reset")
    self.ui.card_select("set_cards", cards)

    local move_cursor = self.ctx:listen("keypressed")
        :map(function(key)
            return ui.key(state.cursor or "default", keymap, key)
        end)
        :filter(identity)
        :collect()

    local confirm = self.ctx:listen("keypressed")
        :filter(function(key) return key == "space" and state.cursor end)
        :latest()

    local function handle_cursor(next_cursor)
        local nc = unpack(next_cursor)
        if not nc then return end
        state.cursor = nc
        self.ui.card_select("set_revealed", {[nc] = true})
    end

    handle_cursor{state.cursor}

    while self.ctx.alive and not confirm:peek() do
        move_cursor:pop():foreach(handle_cursor)

        self.ctx:yield()
    end

    self.ui.card_select.memory = list(
        state.cursor, keymap.right[state.cursor], keymap.left[state.cursor]
    )

    return state.cursor
end

function game:select_target(filter)
    return ui.target_select.interaction_with_gamestate(self, self.ui.target_select, filter)
end

function game:play_minion(card)
    if card.type ~= "minion" then return end

    local index = self:select_minion_spawn()
    if not index then return true end

    self:step(
        mechanics.combat.spawn_minion, card,
        constants.id.player, index
    )
end

function game:play_skill(card)
    if card.type ~= "skill" then return end

    if not card.effect then return end

    local was_interrupted = card.effect(self, constants.id.player, card)

    return was_interrupted
end

function game:play_card(card)
    local gs_before_play = self.gamestate

    self:step(mechanics.card.begin_card_play, constants.id.player, card)

    local play_methods = list(game.play_skill, game.play_minion)

    local was_interrupted = play_methods:reduce(function(interrupted, method)
        return interrupted or method(self, card)
    end, false)

    if not was_interrupted then
        self:step(mechanics.card.end_card_play, constants.id.player)
    else
        self:step(mechanics.combat.overwrite, gs_before_play)
    end
end

function game:setup_battle(player, enemy)
    self.gamestate = gamestate.state()

    local deck = player.deck or list()
    local draw = deck:map(instance):shuffle()

    self.gamestate = self.gamestate:set(component.draw, constants.id.player, draw)

    for i = 1, constants.initial_draw do
        self:step(mechanics.card.draw, constants.id.player)
    end
end

function game:battle_loop()
    self:step(
        mechanics.combat.spawn_minion, instance(cards.minions.fireskull),
        constants.id.player, 1
    )

    while self.ctx.alive do
        local card = self:pick_card_to_play()
        self:play_card(card)
    end
end

return game.create
