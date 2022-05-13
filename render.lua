local nw = require "nodeworks"
local constants = require "constants"

local read = {}

function read.position(entity)
    local pos = entity % nw.component.position
    if pos then return pos.x, pos.y end
    return 0, 0
end

function read.scale(entity)
    local scale = entity % nw.component.scale
    if scale then return scale.x, scale.y end
    return 1, 1
end

function read.rotation(entity)
    return (entity % nw.component.rotation) or 0
end

function read.body_slice(entity)
    local body_slice_name = entity % nw.component.body_slice
    local slices = entity % nw.component.slices
    if not body_slice_name or not slices then return 0, 0 end
    local b = slices[body_slice_name]
    if not b then return 0, 0 end
    return b.x + b.w * 0.5, b.y + b.h
end

function read.origin(entity)
    local origin = (entity % nw.component.origin)
    if origin then return origin.x, origin.y end
    return 0, 0
end

function read.draw_args(entity)
    local x, y = read.position(entity)
    local sx, sy = read.scale(entity)
    local r = read.rotation(entity)
    local ox, oy = read.origin(entity)
    local bx, by = read.body_slice(entity)

    return x, y, r, sx, sy, ox + bx, oy + by
end

local push = {}

function push.shader(entity)
    local shader = entity % nw.component.shader

    if not shader then
        gfx.setShader()
        return
    end

    gfx.setShader(shader)

    local shader_uniforms = entity % nw.component.shader_uniforms

    if not shader_uniforms then return end

    for field, value in pairs(shader_uniforms) do
        if shader:hasUniform(field) then shader:send(field, value) end
    end
end

function push.color(entity)
    local color = entity % nw.component.color
    if color then
        gfx.setColor(color[1], color[2], color[3], color[4])
    else
        gfx.setColor(1, 1, 1)
    end
end

function push.blend_mode(entity)
    local blend_mode = entity % nw.component.blend_mode
    if blend_mode then
        gfx.setBlendMode(blend_mode)
    else
        gfx.setBlendMode("alpha")
    end
end

function push.transform(entity)
    gfx.translate(read.position(entity))
    gfx.rotate(read.rotation(entity))
    gfx.scale(read.scale(entity))
end

function push.state(entity)
    push.shader(entity)
    push.color(entity)
    push.blend_mode(entity)
end

local layer_type = {}

function layer_type.image(layer)
    local frame = layer:get(nw.component.image)
    if not frame then return end
    gfx.push("all")
    push.state(layer)
    push.transform(layer)
    frame:draw()
    gfx.pop()
end

function layer_type.color(layer)
    gfx.push("all")
    push.state(layer)
    push.transform(layer)
    local hb = layer:get(nw.component.rectangle) or spatial(0, 0, gfx.getWidth(), gfx.getHeight())
    gfx.rectangle("fill", hb:unpack())
    gfx.pop()
end

function layer_type.pool(layer)
    local pool = layer:get(nw.component.layer_pool)
    if not pool then return end

    gfx.push("all")
    push.state(layer)
    push.transform(layer)

    for _, entity in ipairs(pool) do
        local func = entity:get(nw.component.drawable)
        if func then
            gfx.push("all")
            push.state(entity)
            push.transform(entity)
            func(entity)
            gfx.pop()
        end
    end

    gfx.pop()
end

local function draw_layer(layer, ...)
    local func = layer:get(nw.component.layer_type)
    if not func then return end
    func(layer, ...)
end

local function render(layers, ...)
    for _, layer in ipairs(layers) do draw_layer(layer, ...) end
end

local function compute_vertical_offset(valign, font_h, h)
    if valign == "top" then
		return 0
	elseif valign == "bottom" then
		return h - font_h
    else
        return (h - font_h) / 2
	end
end

local function draw_text(text, x, y, w, h, opt, sx, sy)
    local opt = opt or {}
    if opt.font then gfx.setFont(opt.font) end

    local sx = sx or 1
    local sy = sy or sx

    local dy = compute_vertical_offset(
        opt.valign, gfx.getFont():getHeight() * sy, h
    )

    gfx.printf(text, x, y + dy, w / sx, opt.align or "left", 0, sx, sy)
end

local card_font = gfx.newFont("art/fonts/smol.ttf", 20)
local title_font = gfx.newFont("art/fonts/smol.ttf", 22)
local stat_font = gfx.newFont("art/fonts/smol.ttf", 22)

local function create_font(...)
    return gfx.newFont("art/fonts/smol.ttf", ...)
end

local function draw_card(x, y, card_data)
    local frame = get_atlas("art/characters"):get_frame("card/minion")
    local image = get_atlas("art/characters"):get_frame("fireskull")
    local s = constants.scale
    gfx.push()
    gfx.translate(x, y)
    gfx.scale(s)


    local bg_color = gfx.hex2color("9567c1")
    gfx.setColor(bg_color)
    gfx.rectangle("fill", frame.slices.image:unpack())
    gfx.setColor(1, 1, 1)
    image:draw(frame.slices.image.x, frame.slices.image.y)
    frame:draw(0, 0)

    local text_slice = frame.slices.text
    local black = gfx.hex2color("f2eee3")
    local key = gfx.hex2color("a9dc54")
    local text = List.map(card_data.text, function(block)
        if type(block) == "function" then return block(card_data) end

        return block
    end)
    gfx.setFont(card_font)

    gfx.setColor(1, 1, 1)
    gfx.printf(
        text, text_slice.x, text_slice.y, text_slice.w * s,
        "center", 0, 1 / s
    )

    local title_slice = frame.slices.title
    local title = card_data.title or "NaN"
    draw_text(
        title, title_slice.x, title_slice.y, title_slice.w , title_slice.h,
        {font=title_font, align="center", valign="middle"}, 1 / s
    )

    local attack_slice = frame.slices.attack
    local attack = 6
    draw_text(
        attack, attack_slice.x, attack_slice.y, attack_slice.w , attack_slice.h,
        {font=stat_font, align="center", valign="middle"}, 1 / s
    )

    local defend_slice = frame.slices.defend
    local defend = 2
    draw_text(
        defend, defend_slice.x, defend_slice.y, defend_slice.w , defend_slice.h,
        {font=stat_font, align="center", valign="middle"}, 1 / s
    )

    gfx.pop()
end

local function card_size()
    local frame = get_atlas("art/characters"):get_frame("card")
    local s = constants.scale
    return frame.slices.body:scale(s)
end

local theme = {
    white = gfx.hex2color("f2eee3"),
    green = gfx.hex2color("a9dc54"),
    dark = gfx.hex2color("461d3f"),
    red =  gfx.hex2color("a03683"),
    dark_red = gfx.hex2color("641f4c"),
    light_red = gfx.hex2color("c36e89")
}

return {
    layer_type = layer_type,
    render = render,
    draw_layer = draw_layer,
    push = push,
    draw_card = draw_card,
    fonts = fonts,
    draw_text = draw_text,
    card_size = card_size,
    theme = theme,
    create_font = create_font
}
