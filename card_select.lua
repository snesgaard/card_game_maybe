local nw = require "nodeworks"
local animated_imgui = require "animated_imgui"
local imtween = require "im_tween"
local ui = require "ui"
local imanime = require "im_animation"

local animation = {
    {1, 0, 0, dt = 0.5},
    {0, 1, 0, dt = 0.5},
    {0, 0, 1, dt = 0.5},
    ease = {ease.linear, ease.linear, ease.linear}
}

local function draw_card(x, y, color)
    gfx.setColor(color or {0.5, 0.5, 0.5})
    gfx.rectangle("fill", x, y, 100, 200)
    gfx.setColor(1, 1, 1)
    gfx.rectangle("line", x, y, 100, 200)
end

local function compute_layout(ctx)
    local layout = {}

    local dx = 60
    for index, card in ipairs(ctx.hand) do
        local x, y = dx, 200
        local dy = ctx.selected == card and -20 or 0
        local offset = ctx.selected == card and 100 or 60
        dx = dx + offset
        local pos = ctx.tweens.position:move_to(card, vec2(x, y + dy))
        layout[card] = spatial(pos.x, pos.y, 100, 200)
    end

    return layout
end

local function compute_button_layout(ctx)
    local keymap = {
        left = {},
        right = {},
    }

    for index, card in ipairs(ctx.hand) do
        keymap.left[card] = ctx.hand[index - 1]
        keymap.right[card] = ctx.hand[index + 1]
    end

    keymap.left[ctx.hand:head()] = ctx.hand:tail()
    keymap.right[ctx.hand:tail()] = ctx.hand:head()

    keymap.left.default = ctx.hand:tail()
    keymap.right.default = ctx.hand:head()

    return keymap
end

local function draw_cards(ctx)
    local layout = ctx.layout
    if not layout then return end

    local card_draw_order = List.sort(
        ctx.hand,
        function(a, b)
            local ax = ctx.selected == a and math.huge or layout[a].x
            local bx = ctx.selected == b and math.huge or layout[b].x
            return ax < bx
        end
    )

    local color = ctx.imanime:play("colors", animation)
    for index, card in ipairs(ctx.hand) do
        local s = layout[card]
        draw_card(s.x, s.y, color)
    end
end

local function update(ctx, dt)
    ctx.layout = compute_layout(ctx)
    ctx.imgui:update(dt)
    for _, tween in pairs(ctx.tweens) do tween:update(dt) end
    ctx.imanime:update(dt)
end

local function keypressed(ctx, key)
    local next_selected = ui.key(
        ctx.selected or "default", compute_button_layout(ctx), key
    )
    ctx.selected = next_selected or ctx.selected
end


return function(ctx)
    ctx.hand = list()
    ctx.visual_state = dict()
    ctx.imgui = animated_imgui.create()
    ctx.imanime = imanime()
    ctx.tweens = {
        position = imtween():set_speed(250)
    }

    for i = 1, 10 do
        local card = ctx:entity()
        table.insert(ctx.hand, card)
    end

    ctx.selected = ctx.hand[5]

    while ctx.alive do
        ctx:visit_event("keypressed", keypressed)
        ctx:visit_event("update", update)
        ctx:visit_event("draw", draw_cards)
        ctx:yield()
    end
end
