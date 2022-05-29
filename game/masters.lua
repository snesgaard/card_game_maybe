local component = require "component"
local cards = require "cards"

local masters = {}

local atlas = get_atlas("art/characters")

masters.gravedigger = {
    name = "Grave Digger",
    health = 10,
    deck = list(
        cards.skills.shovel, cards.skills.shovel, cards.skills.shovel,
        cards.skills.shovel, cards.skills.shovel,
        cards.skills.potion, cards.skills.potion, cards.minions.fireskull,
        cards.minions.fireskull, cards.minions.fireskull
    ),
    sprite = {
        idle = atlas:get_animation("chibdigger")
    }
}

return masters
