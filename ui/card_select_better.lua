local component = require "component"
local constants = require "game.constants"
local render = require "render"
local mechanics =  require "mechanics"

local function compute_card_row(layout, mid, cards, revealed, dx)
    if #cards == 0 then return end

    local count = #cards
    local dx = dx or 200
    local reveal_passed = 0
    local cw = render.card_size().w

    local min_x = math.huge
    local max_x = -math.huge

    for index, card in ipairs(cards) do
        local is_cursor = revealed[card]

        local index_offset = dx * vec2(index - count / 2 - 1, 0)
        local reveal_offset = reveal_passed * vec2(75, 0)
        local cursor_offset = is_cursor and vec2(0, -50) or vec2()

        local pos = mid + index_offset + reveal_offset + cursor_offset
        layout[card] = pos

        min_x = math.min(pos.x, min_x)
        max_x = math.max(pos.x + cw, max_x)
        if is_cursor then reveal_passed = reveal_passed + 1 end

    end

    local mean_x = (max_x + min_x) / 2

    for _, card in ipairs(cards) do
        --layout[card].x = layout[card].x + mid.x - mean_x
    end
end

local function compute_layout(cards, selected, revealed, being_played)
    local cards = cards or {}
    local selected = selected or {}
    local revealed = revealed or {}

    local hand = List.filter(cards, function(c) return not selected[c] end)
    local select = List.filter(cards, function(c) return selected[c] end)

    local w, h = gfx.getWidth(), gfx.getHeight()

    local layout = dict()

    compute_card_row(layout, vec2(w / 2, h - 400), hand, revealed)
    compute_card_row(layout, vec2(w / 2, 100), select, revealed)

    if being_played then
        local cw = render.card_size().w
        layout[being_played] = vec2(w / 2 - cw / 2, 25)
    end

    return layout
end

local function layout_from_state(state)
    return compute_layout(
        state.cards or {}, state.selected or {}, state.revealed or {}
    )
end

local hand_render = {}

function hand_render.init()
    return dict{cards = {}, selected = {}, revealed = {}, layout = {}}
end

function hand_render.set_cards(ctx, state, cards)
    return state
        :set("cards", cards)
        :set("layout", compute_layout(cards, state.selected, state.revealed))
end

function hand_render.reset(ctx, state)
    return state
        :set("selected", {})
        :set("revealed", {})
        :set("layout", compute_layout(state.cards, state.selected, state.revealed))
end

hand_render[mechanics.card.draw] = function(ctx, state, gamestate, step)
    if step.info.card then
        ctx:tween("position"):warp_to(step.info.card, vec2(-100, 1000))
    end
end

function hand_render.step(ctx, state, gamestate)
    local cards = gamestate:get(component.hand, constants.id.player)
    local being_played = gamestate:get(component.card_being_played, constants.id.player)
    return state
        :set("cards", cards)
        :set("being_played", being_played)
        :set("layout", compute_layout(cards, state.selected, state.revealed, being_played))
end

function hand_render.set_selected(ctx, state, selected)
    return state
        :set("selected", selected)
        :set("layout", compute_layout(state.cards, selected, state.revealed, state.being_played))
end

function hand_render.set_revealed(ctx, state, revealed)
    return state
        :set("revealed", revealed)
        :set("layout", compute_layout(state.cards, state.selected, revealed, state.being_played))
end

function hand_render.draw(ctx, state)
    local cards = state.cards
    local layout = state.layout

    if not cards then return end

    for  _, card in ipairs(cards) do
        local pos = layout[card]
        if pos then
            local pos = ctx:tween("position"):move_to(card, pos, 0.1)
            render.draw_card(pos.x, pos.y, card, gamestate)
        end
    end

    local being_played = state.being_played

    if not being_played then return end

    local pos = layout[being_played]
    local pos = ctx:tween("position"):move_to(being_played, pos, 0.1)
    render.draw_card(pos.x, pos.y, being_played)
end

return hand_render
