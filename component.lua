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

return component
