local combat = {}

function combat.attack(gamestate, attacker, defender, damage)
    local str = gamestate:get(component.strength, attacker)
    local def = gamestate:get(component.defense, defender)
    local actual_damage = math.max(0, damage + str - def)

    local next_gamestate, damage_info = epoch(combat.damage, defender, damage)

    local info = {
        attacker = attacker,
        defender = defender
        damage_info = damage_info
    }

    return epoch(next_gamestate, info)
        :chain(combat.damage, target, damage)
        :react(combat.thorns)
end

function combat.damage(gamestate, target, damage)
    local health = gamestate:get(component.health, target)
    local next_health = math.max(0, health - damage)
    local actual_damage = health - next_health

    local next_gamestate = gamestate:set(component.health, target, next_health)

    local info = {
        damage = actual_damage,
        target = target
    }

    local epoch = epoch(next_gamestate, info)

    if 0 < next_health then return epoch end

    return epoch:chain(combat.kill, target)
end

function combat.kill(gamestate, target)
    local next_gamestate = gamestate:set(component.dead, target, true)

    local info = {target = target}

    return epoch(next_gamestate, info)
end

function combat.thorns(gamestate, source, target)
    local thorns = gamestate:get(component.thorns, target)

    if not thorns then return end

    local info = {
        source = source,
        target = target,
        thorns = thorns
    }

    return epoch(gamestate, info):chain(combat.damage, source, thorns)
end

function combat.vampire(gamestate, user, damage)
    local vampire = gamestate:get(component.vampire, user)

    if not vampire then return end

    return epoch(gamestate):chain(combat.heal, user, damage)
end

reaction[combat.attack] = function(epoch, gamestate)
    local attack_info = epoch[combat.attack]
    local damage_info = epoch[combat.damage]

    return epoch(gamestate)
        :chain(combat.thorns, attack_info.user, attack_info.target)
        :chain(combat.vampire, attack_info.user, damage_info.damage)
end

return combat
