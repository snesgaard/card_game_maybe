local mechanics = require "mechanics.combat"

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
    effect = function(history, game, user)
        game:select_target({user})
        game:advance(mechanics.draw_card, user, card.graceful_charity.draw)

        local discards = game:select_cards_from_hand(
            user, card.graceful_charity.discard
        )
        game:advance(mechanics.discard_cards, user, discard)
    end,
    text = {
        theme.key, "Draw ",
        theme.normal, function(card)
            return string.format(" %i cards.\n", card.graceful_charity.draw)
        end,
        theme.key, "Discard",
        theme.normal, function(card)
            return string.format(" %i cards.", cards.graceful_charity.discard)
        end
    }
}

return card
