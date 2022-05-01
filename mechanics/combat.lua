local combat = {}

function combat.damage(gs, user, target, dmg)
    local str = gs:get(component.strength, user)
    local def = gs:get(component.defense, target)
    local charge = gs:get(component.charge, user)
    local shield = gs:get(component.shield, target)
    local health = gs:get(component.health, target)

    local adj_dmg = dmg + str

    if charge then adj_dmg = adj_dmg * 2 end

    adj_dmg = adj_dmg - def

    if shield then adj_dmg = 0 end

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

return combat
