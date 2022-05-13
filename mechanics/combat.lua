local component = require "component"
local constants = require "game.constants"

local combat = {}

function combat.damage(gs, user, target, dmg)
    local str = gs:get(component.strength, user) or 0
    local def = gs:get(component.defense, target) or 0
    local charge = gs:get(component.charge, user) or 0
    local shield = gs:get(component.shield, target) or 0
    local health = gs:get(component.health, target) or 0

    local adj_dmg = dmg + str

    if charge > 0 then adj_dmg = adj_dmg * 2 end

    adj_dmg = adj_dmg - def

    if shield > 0 then adj_dmg = 0 end

    adj_dmg = math.max(adj_dmg, 0)

    local next_health = math.max(health - adj_dmg, 0)
    local actual_damage = health - next_health

    local info = {
        charge_used = charge,
        shield_used = shield,
        damage = actual_damage
    }

    local next_gs = gs
        :set(component.charge, user)
        :set(component.shield, target)
        :set(component.health, target, next_health)

    return next_gs, info
end

function combat.heal(gs, target, heal)
    local health = gs:get(component.health, target)
    local max_health = gs:get(component.max_health, target)
    local next_health = math.min(max_health, health + heal)
    local actual_heal = next_health - health

    local info = {
        heal = actual_heal
    }

    local next_gs = gs:set(component.health, target, next_health)

    return next_gs, info
end

function combat.spawn_minion(gs, minion, id, master, spawn_point)
    print(minion, id, master, spawn_point)
    local formation = gs:ensure(component.formation, constants.field)
    local prev_id = formation[spawn_point]

    print(spawn_point, id, constants.field)
    if prev_id then return end

    local next_gs = gs
        :set(component.health, id, minion.health or 0)
        :set(component.max_health, id, minion.health or 0)
        :set(component.attack, id, minion.attack or 0)
        :set(component.type, id, minion)
        :set(component.master, id, master)
        :set(component.formation, constants.field, formation:set(spawn_point, id))


    local info = {
        type = minion,
        master = master,
        id = id
    }

    return next_gs, info
end

return combat
