local render = require "render"

local confirm = {}
confirm.__index = confirm

function confirm:is_done()
    return self.done
end

function confirm:keypressed(key)
    if key == "left" then
        self.state = true
        return true
    elseif key == "right" then
        self.state = false
        return true
    elseif key == "space" then
        self.done = true
        return true
    elseif key == "backspace" then
        self.state = false
        self.done = true
        return true
    end

    return false
end

function confirm:pop()
    return self.state
end

local message_opt = {
    font = gfx.newFont("art/fonts/smol.ttf", 50),
    align = "center",
    valign = "center"
}

message_opt.font:setFilter("nearest", "nearest")

local option_opt = {
    font = gfx.newFont("art/fonts/smol.ttf", 22),
    align = "center",
    valign = "center"
}

local theme = {}

function theme.normal_body() return render.theme.dark end
function theme.normal_text() return render.theme.white end
function theme.select_body() return theme.normal_text() end
function theme.select_text() return theme.normal_body() end

function confirm:draw(x, y)
    local layout = self:compute_layout()
    local margin = 5
    gfx.push("all")
    gfx.translate(x, y)

    gfx.setColor(theme.normal_body())
    gfx.rectangle("fill", layout.center:unpack(margin))
    if self.state == true then
        gfx.setColor(theme.select_body())
    else
        gfx.setColor(theme.normal_body())
    end
    gfx.rectangle("fill", layout.yes:unpack(margin))
    if self.state == false then
        gfx.setColor(theme.select_body())
    else
        gfx.setColor(theme.normal_body())
    end
    gfx.rectangle("fill", layout.no:unpack(margin))

    if self.state == true then
        gfx.setColor(theme.select_text())
    else
        gfx.setColor(theme.normal_text())
    end
    render.draw_text(
        "Confirm", layout.yes.x, layout.yes.y, layout.yes.w, layout.yes.h,
        option_opt
    )
    if self.state == false then
        gfx.setColor(theme.select_text())
    else
        gfx.setColor(theme.normal_text())
    end
    render.draw_text(
        "Cancel", layout.no.x, layout.no.y, layout.no.w, layout.no.h,
        option_opt
    )
    if self.message then
        local width = message_opt.font:getWidth(self.message)
        local sx = math.min(1, layout.center_text.w / width)
        gfx.setColor(theme.normal_text())
        render.draw_text(
            self.message, layout.center_text:unpack(message_opt, sx)
        )
    end


    gfx.pop()
end

function confirm:compute_layout()
    if self.layout then return self.layout end

    local center_box = spatial(0, 0, 0, 0):expand(400, 100)
    local yes = center_box:down(0, 0, 150, 50)
    local no = center_box:down(0, 0, 150, 50, "right")

    self.layout = {
        center = center_box:expand(100, 0),
        center_text = center_box:expand(-10, -10),
        yes = yes,
        no = no
    }

    return self:compute_layout()
end

function confirm:set_message(message)
    self.message = message
    return self
end

return function()
    return setmetatable({state = true, done = false}, confirm)
end
