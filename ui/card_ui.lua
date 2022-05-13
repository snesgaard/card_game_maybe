local mechanics = require "mechanics"
local render = require "render"
local component = require "component"
local ui = require "ui"

local function split_hand(state, cards)
    local hand = state.hand:filter(function(c)
        return not state.selected:argfind(c)
    end)

    local select = state.hand:filter(function(c)
        return state.selected:argfind(c)
    end)

    return hand, select
end

local function compute_card_row(layout, mid, cards, cursor, dx)
    local count = #cards
    local dx = dx or 200
    local reveal_passed = false

    for index, card in ipairs(cards) do
        local is_cursor = card == cursor

        local index_offset = dx * vec2(index - count / 2 - 1, 0)
        local reveal_offset = reveal_passed and vec2(50, 0) or vec2()
        local cursor_offset = is_cursor and vec2(0, -50) or vec2()

        layout[card] = mid + index_offset + reveal_offset + cursor_offset

        reveal_passed = reveal_passed or is_cursor
    end
end

local function compute_layout(state)
    local hand, select = split_hand(state)
    local being_played = state.being_played
    local outgoing = state.outgoing
    local cursor = state.cursor

    local w, h = gfx.getWidth(), gfx.getHeight()
    local mid = vec2(w / 2, h - 400)

    local layout = {}

    compute_card_row(layout, mid, hand, cursor)
    compute_card_row(layout, vec2(w / 2, 100), select, cursor, 300)

    if being_played then layout[being_played] =  vec2(50, 50) end

    for _, card in ipairs(outgoing) do layout[card] = vec2(w, h) end

    return layout
end

local function compute_keymap(state)
    local hand, select = split_hand(state)

    local keymap = {
        left = {},
        right = {},
        up = {},
        down = {},
    }

    for i, card in ipairs(hand) do
        keymap.left[card] = hand[i - 1]
        keymap.right[card] = hand[i + 1]
        keymap.up[card] = select[i] or List.head(select)
    end

    for i, card in ipairs(select) do
        keymap.left[card] = select[i - 1]
        keymap.right[card] = select[i + 1]
        keymap.down[card] = hand[i] or List.head(hand)
    end

    keymap.left.default = List.tail(hand)
    keymap.right.default = List.head(hand)
    keymap.up.default = List.head(hand)
    keymap.down.default = List.head(select)

    return keymap
end

local card_ui = class()

function card_ui.init(id)
    return dict{
        id = id,
        hand = list(),
        cursor = nil,
        selected = list(),
        being_played = nil,
        outgoing = list(),
    }
end

card_ui[mechanics.card.draw] = function(ctx, state, gs, step)
    local next_hand = gs:get(component.hand, state.id)

    -- Set onscreen position to be initially out of bounds
    for _, card in ipairs(step.info.cards) do
        ctx:tween("position"):warp_to(card, vec2(-100, 1000))
    end

    return state:set("hand", next_hand)
end

card_ui[mechanics.card.discard] = function(ctx, state, gs, step)
    local next_outgoing = state.outgoing + step.info.cards

    return state:set("outgoing", next_outgoing)
end

function card_ui.keypressed(ctx, state, key)
    local keymap = compute_keymap(state)
    local next_cursor = ui.key(state.cursor or "default", keymap, key)

    if next_cursor then
        local next_state = state:set("cursor", next_cursor)
        return next_state, true
    end

    if key == "space" and state.cursor then
        local select_index = state.selected:argfind(state.cursor)
        local next_state = state

        if not select_index then
            next_state = state:set("selected", state.selected:insert(state.cursor))
        else
            next_state = state:set("selected", state.selected:erase(select_index))
        end

        local next_state = next_state
            :set(
                "cursor",
                keymap.right[state.cursor]
                or keymap.left[state.cursor]
                or keymap.up[state.cursor]
                or keymap.down[state.cursor]
            )

        return next_state, true
    end
end

function card_ui.peek(ctx, state)
    return nil, state.selected
end

function card_ui.pop(ctx, state)
    local s = state.selected
    local next_state = state:set("selected", list())
    return next_state, s
end

function card_ui.update(ctx, state)
    return state:set(
        "outgoing",
        state.outgoing:filter(function(card)
            return not ctx:tween("position"):done(card)
        end)
    )
end

function card_ui.draw(ctx, state)
    local layout = compute_layout(state)

    for _, card in ipairs(state.hand) do
        local pos = layout[card]
        local pos = ctx:tween("position"):move_to(card, pos, 0.1)
        render.draw_card(pos.x, pos.y, card)
    end
end

return card_ui
