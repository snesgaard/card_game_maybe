local component = require "component"

local card_mechanics = {}

function card_mechanics.discard(gs, user, card)
    local hand = gs:get(component.hand, user) or list()
    local discard = gs:get(component.graveyard, user) or list()
    local index = hand:argfind(card)

    if not index then return end

    return gs
        :set(component.hand, user, hand:erase(index))
        :set(component.graveyard, user, discard:insert(card))
end

return card_mechanics
