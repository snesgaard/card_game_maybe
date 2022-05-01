local imtween = require "tween.im_tween"
local ui = require "ui"
local render = require "render"
local component = require "component"

local function compute_keymap(cards)
    local keymap = {left = {}, right = {}}
    for i, card in ipairs(cards) do
        keymap.left[card] = cards[i - 1]
        keymap.right[card] = cards[i + 1]
    end

    local head = List.head(cards)
    local tail = List.tail(cards)

    keymap.left[head] = tail
    keymap.right[tail] = head

    keymap.left.default = tail
    keymap.right.default = head

    return keymap
end

local function compute_layout(state, hand)
    local count = #hand
    local w, h = gfx.getWidth(), gfx.getHeight()
    local size = render.card_size()
    local mid = spatial(w * 0.5, h, 0, 0):move(0, -200)

    local layout = {}

    local ox = 0
    for index, card in ipairs(hand) do
        local i = index - count / 2 - 1
        local dx = 150
        local y = card == state.index and -150 or 0
        layout[card] = mid:move(dx * i + ox, y)
        ox = card == state.index and (size.w - dx + 10) or ox
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
            index = nil,
            is_selected = nil,
            keymap = {}
        },
        hand = {},
        id = player_id
    }
    return setmetatable(this, card_select)
end

function card_select:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end
end

function card_select:gamestate_step(gamestate, step)
    local hand = gamestate:get(component.hand, self.id) or {}
    self.hand = hand
    self.state.keymap = compute_keymap(hand)

    for card, rect in pairs(compute_layout(self.state, hand)) do
        self.tweens.position:move_to(card, vec2(rect.x, rect.y))
    end
end

function card_select:keypressed(key)
    local next = ui.key(self.state.index or "default", self.state.keymap, key)
    self.state.index = next or self.state.index

    for card, rect in pairs(compute_layout(self.state, self.hand)) do
        self.tweens.position:move_to(card, vec2(rect.x, rect.y), 0.1)
    end
    return next
end

function card_select:draw()
    local mid = spatial(gfx.getWidth() / 2, 0, 0, gfx.getHeight()):expand(6, 0)
    local card_size = render.card_size()

    gfx.setColor(1, 1, 1, 0.5)
    gfx.rectangle("fill", mid:unpack())
    gfx.setColor(1, 1, 1)
    for index, card in ipairs(self.hand) do
        local pos = self.tweens.position:get(card)

        if self.state.index == card then
            gfx.setColor(0.2, 0.8, 0.2, 0.8)
            gfx.rectangle(
                "fill", card_size:move(pos.x, pos.y):expand(20, 20):unpack(5)
            )
            gfx.setColor(1, 1, 1)
        end

        render.draw_card(pos.x, pos.y, card)
    end
end

return card_select.create
