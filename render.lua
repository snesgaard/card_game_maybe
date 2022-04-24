local nw = require "nodeworks"

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

local function draw_layer(layer)
    local func = layer:get(nw.component.layer_type)
    if not func then return end
    func(layer)
end

local function render(layers)
    for _, layer in ipairs(layers) do draw_layer(layer) end
end

return {
    layer_type = layer_type,
    render = render,
    draw_layer = draw_layer
}
