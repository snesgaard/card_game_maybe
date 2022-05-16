local nw = require "nodeworks"
local game = require "game"
local mechanics = require "mechanics"
local minion = require "minion"

return function(ctx)
    ctx.game = game(ctx)

    local draw = ctx:listen("draw")
        :foreach(function() ctx.game:draw() end)

    local update = ctx:listen("update")
        :foreach(function(dt) ctx.game:update(dt) end)

    ctx.game:step(mechanics.card.draw, ctx.game.id.player, 4)
    --ctx.game:spawn_minion(minion.fireskull, "player")
    ctx.game:select_minion_spawn("player")

    while ctx.alive do
        --ctx.game:pick_card(3, true)
        --ctx.game.ui.instruction:set_message("Pick a card")
        --local card = ctx.game:pick_card_from_hand(1, false):unpack()
        --if ctx.game:press_to_confirm("Play card?") then
        --ctx.game:play_card(ctx.game.id.player, card)
    --    end
        ctx:yield()
    end
end
