local function minion(tab)
    tab.type = "minion"
    return tab
end

local minions = {}

minions.fireskull = minion{
    attack = 6,
    defend = 2,
    entry = function(game, id)
        local target = game:select_target()
        if not target then return false end
        game:step(mechanics.combat.damage, user, target, 6)
    end,
    animation = {
        idle = "fireskull.sprite"
    }
}

return minions
