local render = require "render"

local instruction = class()

local default_opt = {
    font = gfx.newFont("art/fonts/smol.ttf", 50),
    align = "center"
}

function instruction:draw()
    if not self.msg or not self.shape then return end

    local opt = self.opt or default_opt
    local s = self.shape
    if self.bg_color then
        gfx.setColor(self.bg_color)
        gfx.rectangle("fill", s:unpack())
    end
    gfx.setColor(render.theme.dark)
    render.draw_text(self.msg, s.x, s.y, s.w, s.h, opt)
end

function instruction:set_message(msg)
    self.msg = msg
    return self
end

function instruction:set_opt(opt)
    self.opt = opt
    return self
end

function instruction:set_shape(shape)
    self.shape = shape
    return self
end

function instruction:set_bg_color(color)
    self.bg_color = color
    return self
end


return function()
    local this = {}

    return setmetatable(this, instruction)
end
