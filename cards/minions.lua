local card = require "cards"

local atlas = get_atlas("art/characters")

local minions = {}

minions.fireskull = card.minion{
    title = "Fire Skull",
    attack = 1,
    health = 3,
    image = atlas:get_frame("fireskull"),
    sprite = {
        idle = atlas:get_animation("fireskull.sprite"),
    },
    text = "foobar"
}

return minions
