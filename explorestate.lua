explore_state = {
    [health] = {
        player = 10
    },
    [deck] = {
        player = {},
        explore = {},
    },
    [discard] = {
        explore = {}
    }
    [boss] = {
        explore = {}
    },
    [potions] = {
        player = {}
    }
}

explore_state = {
    [id.player] = {
        [component.health] = 10,
        [component.deck] = {},
        [component.potions] = {}
    },
    [id.explore] = {
        [component.deck] = {},
        [component.discard] = {},
        [component.boss] = something
    }
}

epoch = epoch {
    gamestate = gamestate,
    transform = mechanics.combat.damage,
    args = {foe, id, 1},
    react = reaction,
    proact = proaction
}

local epoch = gamestate:epoch{
    transform = mechanics.combat.damage,
    args = {1, 2, 3},
    react = reaction,
    proact = proaction
}
