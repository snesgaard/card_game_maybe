local combat = {}

function combat.thorns(epoch, gamestate, target, damage)
    epoch(mechanics.damage, target, damage)
end

function combat.attack(epoch, gamestate, user, target, damage)
    local str = gamestate:get(component.strength, user)
    local def = gamestate:get(component.defense, target)

    local actual_damage = math.max(0, damage + str - def)

    epoch(combat.damage, target, damage)

    local thorns = gamestate:get(component.thorns, target)
    if thorns then epoch(combat.thorns, user, thorns) end
end

function combat.damage(epoch, gamestate, target, damage)
    local health = gamestate:get(component.health, target)

    if not health then return end

    local next_health = math.max(0, health - damage)
    local real_damage = health - next_health

    local next_gamestate = gamestate
        :set(component.health, target, next_health)

    local info = {
        target = target,
        damage = real_damage
    }

    if next_health <= 0 then epoch(mechanics.die, target) end

    return next_gamestate, info, transforms
end

function combat.die(epoch, gamestate, target)
    local next_gamestate = gamestate
        :set(component.dead, target, true)

    local info = {
        target = target
    }

    epoch(combat.remove_minion, taget)

    return next_gamestate, info
end

function combat.remove_minion(epoch, gamestate, target)
    local type = next_gamestate:get(component.type, target)
    local master = next_gamestate:get(component.master, target)

    if type ~= "minion" or not master then return end

    local formation = gamestate:ensure(component.formation, master)

    local function is_not_target(id) return id ~= target end

    local next_gamestate = gamestate
        :set(component.formation, master, formation:filter(is_not_target))

    local info = {
        target = target
    }

    return next_gamestate, info
end

function combat.spawn_minion(epoch, gamestate, master, minion, position)
    local formation = gamestate:ensure(component.formation, master)
    local id = {}

    local next_gamestate = gamestate
        :instance(id, minion)
        :set(component.master, master)
        :set(component.type, "minion")
        :set(component.base, minion)
        :set(component.formation, master, formation:set(position, id))

    local info = {
        id = id,
        minion = minion,
        position = position
    }

    return next_gamestate, info
end

return combat
