local ui = require "ui"
local constants = require "game.constants"
local component = require "component"
local nw = require "nodeworks"

local player_action_pick = class()

function player_action_pick:listen(topic)
    local obs = self.topics[topic]

    if not obs then
        obs = nw.ecs.promise.observable()
        self.topics[topic] = obs
    end

    return obs
end

function player_action_pick.create(ctx)
    local self = {
        state = {cursor = nil, focus = true, memory = {}},
        ui = {
            cards = gui(ui.card_select_better)
        },
        observable = {},
        topics = {},
        ctx = ctx
    }
    setmetatable(self, player_action_pick)

    local obs = self.observable
    obs.cards = self:listen("step")
        :map(function(gs) return gs:ensure(component.hand, constants.id.player) end)
        :latest()

    obs.memory = obs.cards
        :map(function(cards)
            for _, mem in ipairs(self.state.memory) do
                if cards:argfind(mem) then return mem end
            end
        end)

    obs.keymap = obs.cards
        :map(function(cards)
            return ui.keymap_from_list(cards, "left", "right")
        end)
        :latest()

    obs.key_cursor = ctx:listen("keypressed")
        :filter(function() return self.state.focus end)
        :map(function(key)
            return ui.key(self.state.cursor or "default", obs.keymap:peek(), key)
        end)
        :filter()

    obs.keymap_reset_cursor = obs.keymap
        :filter(function(keymap)
            local c = self.state.cursor
            return not keymap.left[c] or not keymap.right[c]
        end)
        :map(function() return end)

    obs.cursor = obs.key_cursor:merge(obs.keymap_reset_cursor, obs.memory)
        :foreach(function(next_cursor)
            self.state.cursor = next_cursor
            if next_cursor and self.state.focus then
                self.ui.cards("set_revealed", {[next_cursor] = true})
            else
                self.ui.cards("set_revealed", {})
            end
        end)

    return self
end

function player_action_pick:__call(event, ...)
    for _, ui in pairs(self.ui) do ui(event, ...) end
end

function player_action_pick:draw()
    self.ui.cards:draw()
end

function player_action_pick:update(dt)
    for _, ui in pairs(self.ui) do ui:update(dt) end
end

function player_action_pick:focus(value)
    self.state.focus = value
    self.observable.cursor:emit{self.state.cursor}
end

function player_action_pick:pick_card()
    --self.state.focus = true
    self.state.cursor = nil

    local cards = self.observable.cards:peek()
    for _, mem in ipairs(self.state.memory or list()) do
        if cards:argfind(mem) then
            self.observable.cursor:emit{mem}
            break
        end
    end

    local confirm = self.ctx:listen("keypressed")
        :map(function(key) return key == "space" and self.state.cursor end)
        :latest()

    while not confirm:peek() do self.ctx:yield() end

    local keymap = self.observable.keymap:peek()

    local c = self.state.cursor
    self.state.memory = list(c, keymap.left[c], keymap.right[c])

    return self.state.cursor
end

function player_action_pick:__call(event, ...)
    local obs = self.topics[event]
    if not obs then return end
    obs:emit{...}
end

return player_action_pick.create
