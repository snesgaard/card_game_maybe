local field_render = require "game.field_render"
local ui = require "ui"
local im_animation = require "tween.im_animation"
local render = require "render"

local function compute_targets(gamestate, filter)
    local position = field_render.compute_all_actor_position(gamestate)
    local targets = list()

    for id, _ in pairs(position) do
        if filter == nil or filter(gamestate, id) then table.insert(targets, id) end
    end

    return position, targets
end

local function compute_keymap(targets)
    local keymap = {left = {}, right = {}}

    for i, id in ipairs(targets) do
        keymap.left[id] = targets[i - 1]
        keymap.right[id] = targets[i + 1]
    end

    keymap.left.default = List.head(targets)
    keymap.right.default = List.tail(targets)

    return keymap
end

local function radius_animation(self)
    local enter_animation = {
        {radius = 0, dt=0.1},
        {radius = 8, dt=0.1},
        {radius = 2}
    }

    local stay_animation = {
        {radius = 2, dt=0.5},
        {radius = 8, dt=0.5},
        {radius = 2}
    }

    self.imanime:play_once("circle", enter_animation)
    while self.imanime:is_done("circle") do
        coroutine.yield(self.imanime:get("circle"))
    end

    self.imanime:play("circle", stay_animation)
    while true do
        coroutine.yield(self.imanime:get("circle"))
    end
end

local target_select = class()

function target_select.create(gamestate, targets)
    local this = setmetatable(
        {},
        target_select
    )
    return this
end

function target_select:configure(gamestate, filter)
    local positions, targets = compute_targets(gamestate, filter)
    self.state = dict()
        :set("gamestate", gamestate)
        :set("filter", filter)
        :set("keymap", compute_keymap(targets))
        :set("positions", positions)
        :set("cursor", targets:head())
        :set("time", 0)
end

function target_select:clear()
    self.state = nil
    return self
end

function target_select:keypressed(key)
    if not self.state then return end
    local next_cursor = ui.key(self.state.cursor, self.state.keymap, key)

    if next_cursor then
        self.state = self.state
            :set("cursor", next_cursor)
            :set("time", 0)
        return true
    end

    if key == "space" and self.state.cursor then
        self.state = self.state:set("done", true)
        return true
    end

    if key == "backspace" then
        self.state = self.state:set("done", true):set("cursor", nil)
        return true
    end
end

function target_select:is_done()
    local s = self.state or {}
    return s.done
end

function target_select:pop()
    local s = self.state
    self:clear()
    return s.cursor
end

function target_select:update(dt)
    if not self.state then return end
    self.state.time = self.state.time + dt
end

local function compute_size(time)
    local min, max = 3, 8
    local expand = 12
    local expand_time = 0.25

    if time < expand_time then
        local t = -math.cos(time * math.pi * 2 / expand_time) / 2 + 1
        return t * expand + (1 - t) * min
    end

    local dr = max - min
    local t = (-math.cos(time - expand_time) / 2 + 1)
    return t * max + (1 - t) * min
end

function target_select:draw()
    if not self.state then return end
    if not self.state.cursor then return end

    local c = self.state.cursor
    local p = self.state.positions[c]

    if not p then return end

    gfx.setColor(render.theme.red)
    gfx.circle("fill", p.x, p.y- 100, compute_size(self.state.time))
end


return target_select.create
