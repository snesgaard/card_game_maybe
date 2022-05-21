local nw = require "nodeworks"
local game = require "game"
local mechanics = require "mechanics"
local minion = require "minion"
local cards = require "cards"
local component = require "component"
local constants = require "game.constants"

return function(ctx)
    ctx.game = game(ctx)

    local draw = ctx:listen("draw")
        :foreach(function() ctx.game:draw() end)

    local update = ctx:listen("update")
        :foreach(function(dt) ctx.game:update(dt) end)

    local player = {
        deck = List.duplicate(cards.skills.shovel, 5)
            + List.duplicate(cards.skills.potion, 5)
            + List.duplicate(cards.minions.fireskull, 5),
    }

    print(player.deck:map(function(c) return c.title end))

    ctx.game:setup_battle(player)
    print(ctx.game.gamestate:get(component.hand, constants.id.player):map(function(c) return c.title end))
    ctx.game:battle_loop()
end
