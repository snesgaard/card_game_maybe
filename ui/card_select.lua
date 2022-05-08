local imtween = require "tween.im_tween"
local ui = require "ui"
local render = require "render"
local component = require "component"
local mechanics = require "mechanics"

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
    local next_state = state:set("cursor", next_cursor)

    if is_select then
        local next_select = state.select:filter(function(card)
            return card ~= state.cursor
        end)
        return next_state:set("select", next_select)
    elseif #state.select < state.count  then
        local next_select = state.select:insert(state.cursor)
        return next_state:set("select", next_select)
    end
end

local function handle_key_navigation(state, keymap, key)
    local next_cursor = ui.key(state.cursor or "default", keymap, key)
    if next_cursor then
        return state:set("cursor", next_cursor)
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

local function compute_layout(tweens, state, gamestate)
    local hand, select = split_cards(state, gamestate.hand)
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
        local dst = tweens.position:move_to(card, vec2(x, 150) + ox, 0.1)
        layout[card] = card_size:move(dst.x, dst.y)
        if card == state.cursor then rx = 50 end
    end

    if gamestate.card_being_played then
        local card = gamestate.card_being_played
        local dst = tweens.position:move_to(card, vec2(50, 50), 0.2)
        layout[card] = card_size:move(dst.x, dst.y)
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
        state = dict{
            cursor = nil,
            select = list(),
            count = 1,
        },
        gamestate = {
            hand = {},
            card_being_played = nil
        },
        id = player_id
    }
    return setmetatable(this, card_select)
end

function card_select:configure(opt)
    self.state = self.state
        :set("cursor", nil)
        :set("select", list())
        :set("count", opt.count or 1)
        :set("slack", opt.slack)
        :set("message", opt.message)
end

function card_select:done()
    return self.state.slack or self.state.count == #self.state.select
end

function card_select:pop()
    local s = self.state.select:filter(function(c)
        return self.gamestate.hand:argfind(c)
    end)

    if #s == 1 then
        self.state = self.state:set("cursor", s[1])
    end

    return s
end

function card_select:gamestate_step(gamestate, step)
    self.gamestate.hand = gamestate:get(component.hand, self.id)
    self.gamestate.card_being_played = gamestate:get(component.card_being_played, self.id)

    if not step then return step end

    if step.func == mechanics.card.draw then
        for _, card in ipairs(step.info.cards) do
            self.tweens.position:warp_to(card, vec2(-300, 1000))
        end
    end
end

function card_select:keypressed(key)
    local keymap = compute_keymap(self.state, self.gamestate.hand)

    local next_state = handle_key_navigation(self.state, keymap, key)

    if next_state then
        self.state = next_state
        return true
    end

    if key == "space" then
        self.state = handle_confirm(self.state, self.gamestate.hand, keymap) or self.state
        return true
    end

    if key == "k" then
        self.state.cursor = nil
    end

    return false
end

function card_select:mousemoved(x, y)
    local hand = self.gamestate.hand

    local layout = compute_layout(self.tweens, self.state, self.gamestate)

    for i = #hand, 1, -1 do
        local card = hand[i]
        local pos = layout[card]
        if pos:point_inside(x, y) then
            self.state = self.state:set("cursor", card)
            return true
        end
    end

    return false
end

function card_select:mousepressed(x, y, button)
    if button ~= 1 then return end

    if self:mousemoved(x, y) then
        local keymap = compute_keymap(self.state, self.gamestate.hand)
        self.state = handle_confirm(self.state, self.gamestate.hand, keymap)
    end
end

function card_select:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end
end

local text_opt = {
    font = gfx.newFont("art/fonts/smol.ttf", 50),
    align = "center",
    valign = "center"
}

function card_select:draw()
    local layout = compute_layout(self.tweens, self.state, self.gamestate)

    gfx.setColor(1, 1, 1, 0.5)
    gfx.rectangle(
        "fill",
        spatial(gfx.getWidth() / 2, 0, 0, gfx.getHeight()):expand(6, 0):unpack()
    )

    if self.gamestate.card_being_played then
        local card = self.gamestate.card_being_played
        local pos = layout[card]
        gfx.setColor(1, 1, 1)
        render.draw_card(pos.x, pos.y, card)
    end

    if self.state.message then
        gfx.setColor(1, 1, 1, 0.5)
        local area = spatial(0, 150, gfx.getWidth(), render.card_size().h)
            :expand(-400, 50)
        local text = area:up(0, 0, 600, 100, "center")
        gfx.rectangle("fill", area:unpack(20))
        gfx.rectangle("fill", text:unpack(10))
        gfx.setColor(render.theme.dark)
        render.draw_text(
            self.state.message, text.x, text.y, text.w, text.h, text_opt
        )
    end

    gfx.setColor(1, 1, 1)
    local hand, select = split_cards(self.state, self.gamestate.hand)
    local card_size = render.card_size()

    local cards_to_draw = hand + select

    for _, card in ipairs(cards_to_draw) do
        local pos = layout[card]

        if card == self.state.cursor then
            gfx.setColor(0.2, 0.8, 0.2)
            gfx.rectangle("fill", pos:expand(20, 20):unpack())
            gfx.setColor(1, 1, 1)
        end

        render.draw_card(pos.x, pos.y, card)

        gfx.rectangle("line", pos:unpack())
    end
end

return card_select.create
