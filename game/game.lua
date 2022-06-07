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
            actor_status = gui(ui.actor_status),
            actor_field = gui(ui.actor_in_field),
            actor_particles = gui(ui.actor_particles),
            action_pick = ui.player_action_pick(ctx)
        },
        ctx = ctx
    }

    for _, ui in pairs(this.ui) do
        if ui.gamestate_step then ui:gamestate_step(this.gamestate) end
    end



    return setmetatable(this, game)
end

function game:step(func, ...)
    local next_gs, info = func(self.gamestate, ...)

    local step = {
        gamestate = next_gs or self:tail(),
        func = func,
        args = args,
        info = info or {},
    }

    self.gamestate = step.gamestate

    for _, ui in pairs(self.ui) do
        ui(step.func, step.gamestate, step)
        self.ctx:emit(step.func, step.gamestate, step)
        ui("step", step.gamestate, step)
        self.ctx:emit("step", step.gamestate, step)
    end

    return info
end

function game:draw()
    local w, h = gfx.getWidth(), gfx.getHeight()
    gfx.setColor(0.5, 0.5, 0.5, 0.5)
    gfx.rectangle("fill", 0, 0, w, h)
    gfx.setColor(1, 1, 1)
    self.ui.actor_field:draw()
    self.ui.actor_status:draw()
    self.ui.actor_particles:draw()
    self.ui.target_select:draw()
    --self.ui.card_select:draw()
    self.ui.action_pick:draw()
end

function game:update(dt)
    for _, ui in pairs(self.ui) do if ui.update then ui:update(dt) end end
end

function game:select_minion_spawn(user)
    local indices = {-3, -2, -1}
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
        if next_cursor == nil then return end
        state.cursor = next_cursor
        self.ui.card_select("set_revealed", {[next_cursor] = true})
    end

    handle_cursor(state.cursor)

    while self.ctx.alive and not confirm:peek() do
        move_cursor:pop():foreach(handle_cursor)

        self.ctx:yield()
    end

    self.ui.card_select.memory = list(
        state.cursor, keymap.right[state.cursor], keymap.left[state.cursor]
    )

    return state.cursor
end

function game:pick_card_to_play()
    self.ui.action_pick:focus(true)
    return self.ui.action_pick:pick_card()
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
    self.ui.action_pick:focus(false)

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

    self.ui.action_pick:focus(true)
end

function game:minion_phase(player_turn)
    local formation = self.gamestate:get(component.formation, constants.id.field)

    local player_side = list()
    local enemy_side = list()

    for i = 1, constants.max_positions do
        table.insert(player_side, formation[-i])
        table.insert(enemy_side, formation[i])
    end

    local attackers = player_turn and player_side or enemy_side
    local defenders = player_turn and enemy_side or player_side

    local function is_alive(id)
        return self.gamestate:ensure(component.health, id) > 0
    end

    local attackers = attackers:filter(is_alive)

    table.insert(defenders, player_turn and constants.id.enemy or constants.id.player)

    for _, id in ipairs(attackers) do
        local defenders = defenders:filter(is_alive)
        local target = defenders:head()
        if target then
            local promise = self.ui.actor_field("animate_attack", id)
            self:wait_until(promise)

            local attack = self.gamestate:ensure(component.attack, id)
            self:step(mechanics.combat.damage, id, target, attack)
            self.ui.actor_particles("impact", target)
            self.ui.actor_field("reset_position", id)
            self:wait(0.5)
        end
    end
end

function game:wait(time)
    local state = {time=time}
    local update = self.ctx:listen("update")
        :foreach(function(dt)
            state.time = state.time - dt
        end)

    while state.time > 0 do self.ctx:yield() end
end

function game:random_pick(...)
    local options = list(...)
    if options:empty() then return end
    local i = self:rng(1, options:size())
    return options[i]
end

function game:wait_until(condition)
    while not condition() do self.ctx:yield() end
end

function game:setup_battle(player, enemy)
    self.gamestate = gamestate.state()

    self:step(mechanics.combat.intialize_battle, player, enemy)

    local deck = player.deck or list()
    local draw = deck:map(instance):shuffle()

    --self.gamestate = self.gamestate:set(component.draw, constants.id.player, draw)

    for i = 1, constants.initial_draw do
        self:step(mechanics.card.draw, constants.id.player)
    end
end

function game:battle_loop()
    self:step(
        mechanics.combat.spawn_minion, instance(cards.minions.fireskull),
        constants.id.enemy, 1
    )
    self:step(
        mechanics.combat.spawn_minion, instance(cards.minions.fireskull),
        constants.id.player, -1
    )
    self:step(
        mechanics.combat.spawn_minion, instance(cards.minions.fireskull),
        constants.id.player, -2
    )

    --self:minion_phase(true)
    --self:minion_phase(false)

    while self.ctx.alive do
        local card = self:pick_card_to_play()
        self:play_card(card)
        self:minion_phase(true)
    end
end

function game:battle()
    self:battle_begin()

    while not self:done() do
        self:round_begin()

        self:player_turn()
        self:enemy_turn()

        self:round_end()
    end

    return self:battle_end()
end

function game:round_begin()
    self:step(mechanics.ai.determine_next_move, constants.id.enemy)
    self:step(mechanics.turn.increase_turn_counter)
end

function game:enemy_turn()
    local ai = self:get_ai()
end

function game:enemy_turn()
    local ai_move = mechanics.ai.get_ai_move(self.gamestate)
    self:activate_all_minions(constants.id.enemy)
    if ai_move then ai_move(self, self.gamestate, constants.id.enemy) end
    self:step(mechanics.ai.clear_next_move, constants.id.enemy)
end

return game.create
