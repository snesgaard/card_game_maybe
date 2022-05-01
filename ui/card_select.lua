local imtween = require "tween.im_tween"
local ui = require "ui"
local render = require "render"
local component = require "component"

local function split_cards(state, cards)
    local hand = cards:filter(function(c)
        return not state.select:argfind(c)
    end)

    local select = cards:filter(function(c)
        return state.select:argfind(c)
    end)

    return hand, select
end

local function compute_keymap(state, cards)
    local hand, select = split_cards(state, cards)

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

local function handle_confirm(state, cards, keymap)
    local is_hand = cards:argfind(state.cursor)
    local is_select = state.select:argfind(state.cursor)

    if not is_hand then return end

    local next_cursor = keymap.left[state.cursor] or keymap.right[state.cursor]

    if not is_select then
        return {
            cursor = next_cursor,
            select = state.select:insert(state.cursor)
        }
    else
        return {
            cursor = next_cursor,
            select = state.select:filter(function(card)
                return card ~= state.cursor
            end)
        }
    end
end

local function handle_key_navigation(state, keymap, key)
    local next_cursor = ui.key(state.cursor or "default", keymap, key)
    if next_cursor then
        return {
            cursor = next_cursor,
            select = state.select
        }
    end
end

local function compute_x_cards(index, count, past_selected  )
    local mid = gfx.getWidth() / 2
    local dx = 200

    local i = index - count / 2 - 1

    return dx * i + mid
end

local function cursor_offset(card, cursor)
    if card == cursor then return vec2(0, -50) end
    return vec2()
end

local function reveal_offset(card, cursor)
    if card == cursor then return 50 end
end

local function compute_layout(tweens, state, cards)
    local hand, select = split_cards(state, cards)
    local card_size = render.card_size()

    local layout = {}

    local rx = nil
    for i, card in ipairs(hand) do
        local x = compute_x_cards(i, #hand) + (rx or 0)
        local ox = cursor_offset(card, state.cursor)
        local dst = tweens.position:move_to(card, vec2(x, 800) + ox, 0.1)
        layout[card] = card_size:move(dst.x, dst.y)

        if card == state.cursor then rx = 50 end
    end

    local rx = nil
    for i, card in ipairs(select) do
        local x = compute_x_cards(i, #select) + (rx or 0)
        local ox = cursor_offset(card, state.cursor)
        local dst = tweens.position:move_to(card, vec2(x, 100) + ox, 0.1)
        layout[card] = card_size:move(dst.x, dst.y)
        if card == state.cursor then rx = 50 end
    end

    return layout
end

local card_select = {}
card_select.__index = card_select

function card_select.create(player_id)
    local this = {
        tweens = {
            position = imtween():set_speed(1000)
        },
        state = {
            cursor = nil,
            select = list(),
        },
        hand = {},
        id = player_id
    }
    return setmetatable(this, card_select)
end

function card_select:gamestate_step(gamestate)
    self.hand = gamestate:get(component.hand, self.id)
end

function card_select:keypressed(key)
    local keymap = compute_keymap(self.state, self.hand)

    local next_state = handle_key_navigation(self.state, keymap, key)

    if next_state then
        self.state = next_state
        return true
    end

    if key == "space" then
        self.state = handle_confirm(self.state, self.hand, keymap) or self.state
        return true
    end

    if key == "k" then
        self.state.cursor = nil
    end

    return false
end

function card_select:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end
end

function card_select:draw()
    gfx.setColor(1, 1, 1, 0.5)
    gfx.rectangle("fill", spatial(gfx.getWidth() / 2, 0, 0, gfx.getHeight()):expand(6, 0):unpack())
    gfx.setColor(1, 1, 1)

    local hand, select = split_cards(self.state, self.hand)
    local card_size = render.card_size()
    local layout = compute_layout(self.tweens, self.state, self.hand)

    local cards_to_draw = hand + select

    for _, card in ipairs(cards_to_draw) do
        local pos = layout[card]

        if card == self.state.cursor then
            gfx.setColor(0.2, 0.8, 0.2)
            gfx.rectangle("fill", pos:expand(20, 20):unpack())
            gfx.setColor(1, 1, 1)
        end

        render.draw_card(pos.x, pos.y, card)
    end
end

return card_select.create
