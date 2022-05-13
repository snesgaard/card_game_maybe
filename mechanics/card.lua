local component = require "component"

local card_mechanics = {}

function card_mechanics.draw(gs, user, num_cards)
    local draw = gs:get(component.draw, user) or list()
    local hand = gs:get(component.hand, user) or list()

    local cards_to_add = draw:sub(1, num_cards)
    local draw_left = draw:sub(num_cards + 1, #draw)

    local info = {cards = cards_to_add}
    local next_gs = gs
        :set(component.hand, user, hand + cards_to_add)
        :set(component.draw, user, draw_left)

    return next_gs, info
end

function card_mechanics.discard(gs, user, card)
    local hand = gs:get(component.hand, user) or list()
    local discard = gs:get(component.graveyard, user) or list()
    local index = hand:argfind(card)

    if not index then return end

    local info = {cards = list(card)}
    local next_gs = gs
        :set(component.hand, user, hand:erase(index))
        :set(component.graveyard, user, discard:insert(card))

    return next_gs, info
end

function card_mechanics.begin_card_play(gs, user, card)
    local hand = gs:get(component.hand, user)
    local draw = gs:get(component.draw, user)
    local graveyard = gs:get(component.graveyard, user)

    local card_being_played = gs:get(component.card_being_played, user)

    local function is_not_card(c) return c ~= card end

    return gs
        :set(component.hand, user, hand:filter(is_not_card))
        :set(component.draw, user, draw:filter(is_not_card))
        :set(component.graveyard, user, graveyard:filter(is_not_card))
        :set(component.card_being_played, user, card)
end

function card_mechanics.end_card_play(gs, user, was_skipped)
    local graveyard = gs:get(component.graveyard, user)
    local hand = gs:get(component.hand, user)
    local card = gs:get(component.card_being_played, user)

    if was_skipped then
        return gs
            :set(component.hand, user, hand:insert(card))
            :set(component.card_being_played, user, nil)
    else
        return gs
            :set(component.graveyard, user, graveyard:insert(card))
            :set(component.card_being_played, user, nil)
    end
end

return card_mechanics
