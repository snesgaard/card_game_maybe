local ui = require "ui"
local constants = require "game.constants"
local component = require "component"

local player_action_pick = class()

function player_action_pick.create(ctx)
    local this = {
        state = {cursor = nil, focus = true},
        ui = {
            cards = gui(ui.card_select_better)
        },
        observable = {},
        ctx = ctx
    }

    local obs = this.observable
    obs.cards = ctx:listen("step")
        :map(function(gs) return gs:ensure(component.hand, constants.id.player) end)

    obs.keymap = obs.cards
        :map(function(cards)
            return ui.keymap_from_list(cards, "left", "right")
        end)
        :latest()

    obs.key_cursor = ctx:listen("keypressed")
        :filter(function() return this.state.focus end)
        :map(function(key)
            return ui.key(this.state.cursor or "default", obs.keymap:peek(), key)
        end)
        :filter()

    obs.keymap_reset_cursor = obs.keymap
        :filter(function(keymap)
            local c = this.state.cursor
            return not keymap.left[c] or not keymap.right[c]
        end)
        :map(function() return end)

    obs.cursor = obs.key_cursor:merge(obs.keymap_reset_cursor)
        :foreach(function(next_cursor)
            this.state.cursor = next_cursor
            if next_cursor then
                this.ui.cards("set_revealed", {[next_cursor] = true})
            else
                this.ui.cards("set_revealed", {})
            end
        end)

    return setmetatable(this, player_action_pick)
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

function player_action_pick:pick_card()
    self.state.focus = true

    local confirm = self.ctx:listen("keypressed")
        :map(function(key) return key == "space" and self.state.cursor end)
        :latest()

    while not confirm:peek() do self.ctx:yield() end

    self.state.memory = self.state.cursor

    return self.state.cursor
end

return player_action_pick.create
