local component = {}

function component.health(hp) return hp end

function component.max_health(hp) return hp end

function component.party_order(order) return order or {} end

function component.enemy_order(order) return order or {} end

return component
