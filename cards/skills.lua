local mechanics = require "mechanics"

local card = require "cards"

local atlas = get_atlas("art/characters")

local skills = {}

skills.shovel = card.skill{
    title = "Shovel",
    damage = 5,
    target = function(game, user, card)
        return game:select_target()
    end,
    text = {
        card.theme.normal, "deal ",
        card.theme.normal, function() return skills.shovel.damage end,
        card.theme.normal, " damage."
    },
    effect = function(game, user, card, target)
        game:step(mechanics.combat.damage, user, target, card.damage or 0)
    end,
    image = atlas:get_frame("shovel2")
}

skills.potion = card.skill{
    title = "Potion",
    text = "Heal 5.",
    target = function(game, user, card)
        return game:select_target()
    end,
    effect = function(game, user, card, target)
        game:step(mechanics.combat.heal, target, 2)
    end,
    image = atlas:get_frame("potion")
}

return skills
