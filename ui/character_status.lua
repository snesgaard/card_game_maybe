local imtween = require "tween.im_tween"
local field_render = require "game.field_render"
local component = require "component"
local constants = require "game.constants"
local render = require "render"

local character_status = {}
character_status.__index = character_status

function character_status:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end
end

function character_status:gamestate_step(gamestate)
    self.gamestate = gamestate
end

function character_status:draw_actor(index, id)
    local pos = field_render.actor_position(index)
    local bar = spatial(pos.x, pos.y, 0, 0):down(0, 15):expand(150, 15)
    local text_box = bar:right(0, 0, 76, 35, "center")

    local hp = self.gamestate:get(component.health, id)
    local max_hp = self.gamestate:get(component.max_health, id)

    if not hp or not max_hp then return end

    local tween_hp = self.tweens.health:move_to(id, hp, 0.1)

    local s = tween_hp / max_hp

    gfx.setColor(render.theme.dark_red)
    gfx.rectangle("fill", bar:expand(6):unpack(4))
    gfx.setColor(render.theme.red)
    if s > 0 then
        gfx.rectangle("fill", bar.x, bar.y, bar.w * s, bar.h, 4)
    end

    local str = string.format("%s/%s", hp, max_hp)
    gfx.setColor(render.theme.white)
    render.draw_text(str, bar.x, bar.y, bar.w, bar.h, self.text_opt, sx, sy)
end

function character_status:draw()
    if not self.gamestate then return end

    local party_order = self.gamestate:get(component.party_order, constants.field)
    local enemy_order = self.gamestate:get(component.enemy_order, constants.field)

    for index, id in pairs(party_order) do self:draw_actor(-index, id) end
    for index, id in pairs(enemy_order) do self:draw_actor(index, id) end
end

return function()
    return setmetatable(
        {
            tweens = {
                health = imtween():set_speed(20),
            },
            text_opt = {
                font = render.create_font(20),
                align = "center",
                valign = "center"
            }
        },
        character_status
    )
end
