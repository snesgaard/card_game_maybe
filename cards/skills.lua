local card = require "cards"

local atlas = get_atlas("art/characters")

local skills = {}

skills.shovel = card.skill{
    title = "Shovel",
    damage = 5,
    text = {
        card.theme.normal, "deal ",
        card.theme.normal, function() return skills.shovel.damage end,
        card.theme.normal, " damage."
    },
    image = atlas:get_frame("shovel2")
}

skills.potion = card.skill{
    title = "Potion",
    text = "Heal 5.",
    image = atlas:get_frame("potion")
}

return skills
