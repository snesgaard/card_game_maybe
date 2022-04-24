local nw = require "nodeworks"

local function compute_square_distance(a, b)
    if type(a) == "table" and type(b) == "table" then
        local sum = 0
        for key, value in pairs(a) do
            local d = value - b[key]
            sum = sum + d * d
        end
        return sum
    elseif type(a) == "number" and type(b) == "number" then
        local d = a - b
        return d * d
    else
        errorf("Unsupported types %s and %s", type(a), type(b))
    end
end

local im_tween = {}
im_tween.__index = im_tween

function im_tween.create(default_value)
    return setmetatable(
        {
            default_value = default_value,
            speed = 1,
            min_distance = 1,
            tweens = {},

        },
        im_tween
    )
end

function im_tween:get(id)
    local t = self.tweens[id]
    return t ~= nil and t:value() or self.default_value
end

function im_tween:set_speed(speed)
    self.speed = speed
    return self
end

function im_tween:set_ease(ease)
    self.ease = ease
    return self
end

function im_tween:set_min_distance(min_distance)
    self.min_distance = min_distance
    return self
end

function im_tween:set(id, from, to, duration, ease)
    self.tweens[id] = nw.component.tween(from, to, duration, ease)
    return self
end

function im_tween:move_to(id, value)
    local t = self.tweens[id]
    if not t then return self:warp_to(id, value) end

    local to = t:to()
    local sq_dist = compute_square_distance(to, value)
    local min_dist = self.min_distance
    if sq_dist < min_dist * min_dist then return t:value() end

    local from = t:value()
    local to = value
    local sq_dist = compute_square_distance(from, to)
    local time = math.sqrt(sq_dist) / self.speed
    self:set(id, from, to, time, self.ease)
    return self:get(id)
end

function im_tween:warp_to(id, value)
    self:set(id, value, value, 1)
    return self:get(id)
end

function im_tween:get(id)
    local t = self.tweens[id]
    if not t then return end
    return t:value()
end

function im_tween:is_done(id)
    local t = self.tweens[id]
    if not t then return true end
    return t:is_done()
end

function im_tween:ensure(id, default_value)
    local value = self:get(id)
    if value then return value end
    return self:move_to(id, default_value)
end

function im_tween:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end
end

return im_tween.create
