local nw = require "nodeworks"

local function square_distance(p1, x, y)
    local dx = p1.x - x
    local dy = p1.y - y

    return dx * dx + dy * dy
end

local animated_imgui = {}
animated_imgui.__index = animated_imgui

function animated_imgui.create()
    return setmetatable(
        {
            tweens = {
                position = {},
                color = {}
            }
        },
        animated_imgui
    )
end

function animated_imgui:move_to(id, x, y, ix, iy)
    local tween = self.tweens.position[id] or nw.component.tween(vec2(ix, iy), vec2(ix, iy), 1)

    if square_distance(tween:to(), x, y) < 1 then
        return tween:value(), tween:is_done()
    end

    local next_tween = nw.component.tween(
        tween:value(), vec2(x, y), 1, ease.inOutQuad
    )
    self.tweens.position[id] = next_tween

    return next_tween:value(), next_tween:is_done()
end

function animated_imgui:warp_to(id, position)
    self.tweens.position[id] = nw.component.tween(
        position, position, 1, ease.inOutQuad
    )
    return position
end

function animated_imgui:color(id, color)

end

local function apply_filter(tweens, func, ...)
    for id, _ in pairs(tweens) do
        if not func(id, ...) then tweens[id] = nil end
    end
end

function animated_imgui:fitler(func, ...)
    for _, tweens in pairs(self.tweens) do
        apply_filter(tweens, func, ...)
    end
end

function animated_imgui:clear(id)
    for _, tweens in pairs(self.tweens) do
        tweens[id] = nil
    end
end

function animated_imgui:update(dt)
    for _, tween in pairs(self.tweens.position) do tween:update(dt) end
    for _, tween in pairs(self.tweens.color) do tween:update(dt) end
end


return animated_imgui
