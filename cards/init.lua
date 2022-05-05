local mechanics = require "mechanics"

local card = {}

function card.instance(card_type)
    card_type.__index = card_type
    return setmetatable({}, card_type)
end

local theme = {
    normal = gfx.hex2color("f2eee3"),
    key = gfx.hex2color("a9dc54")
}

card.shovel = {
    title = "Shovel",
    damage = 5,
    map = function(history, user, target)
        return history
            :advance(mechanics.combat.damage, user, target, card.shovel.damage)
    end,
    text = {
        theme.normal,  function() return string.format("Deal %i", card.shovel.damage) end,
        theme.key, " damage."
    }
}

card.cure = {
    title = "Cure",
    heal = 5,
    effect = function(history, user, target)
        local target = game:select_target()
        game:advance(mechanics.combat.heal, user, target, card.cure.heal)
    end,
    text = {
        theme.key, "Heal",
        theme.normal, function() return string.format(" %i.", card.cure.heal) end
    }
}

card.graceful_charity = {
    title = "Graceful Charity",
    discard = 2,
    draw = 3,
    effect = function(game, user)
        game:step(mechanics.card.draw, user, 3)

        local function pick_discards()
            while true do
                local discards = game:pick_card_from_hand(
                    2, false, "Discard 2 cards"
                )
                if game:press_to_confirm("Discard these cards?") then
                    return discards
                end
            end
        end


        for _, card in ipairs(pick_discards()) do
            game:step(mechanics.card.discard, user, card)
        end
    end,
    text = {
        theme.key, "Draw",
        theme.normal, function()
            return string.format(" %i cards.\n", card.graceful_charity.draw)
        end,
        theme.key, "Discard",
        theme.normal, function()
            return string.format(" %i cards.", card.graceful_charity.discard)
        end
    }
}

return card
