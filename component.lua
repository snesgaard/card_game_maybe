local component = {}

function component.health(hp) return hp end

function component.max_health(hp) return hp end

function component.party_order(order) return order or {} end

function component.enemy_order(order) return order or {} end

function component.gamestate(gs) return gs end

function component.hand(hand) return hand or {} end

function component.graveyard(graveyard) return graveyard or {} end

function component.draw(draw) return draw or {} end

function component.card_being_played(card) return card or nil end

function component.strength(str) return str or 0 end

function component.defense(def) return def or 0 end

function component.charge(c) return c or 0 end

function component.shield(s) return s or 0 end

function component.formation(f) return f or dict() end

function component.type(t) return t end

function component.master(m) return m end

function component.attack(a) return a or 0 end

return component
