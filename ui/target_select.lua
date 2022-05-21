local field_render = require "game.field_render"
local ui_glob = require "ui"
local im_animation = require "tween.im_animation"
local render = require "render"
local constants = require "game.constants"
local component = require "component"

local ui = {}

function ui.init()
    return dict{}
end

function ui.set_targets(ctx, state, targets)
    return state:set("targets", targets)
end

function ui.set_position(ctx, state, position)
    return state:set("position", position)
end

function ui.set_highlight(ctx, state, highlight)
    return state:set("highlight", highlight)
end

function ui.clear() return dict{} end

function ui.draw(ctx, state)
    if not state.targets then return end
    if not state.position then return end
    local highlight = state.highlight or {}

    gfx.setColor(1, 1, 1)
    for _, id in ipairs(state.targets) do
        local pos = state.position[id]
        local radius = highlight[id] and 10 or 2
        if pos then gfx.circle("fill", pos.x, pos.y, radius) end
    end
end

local function interaction(game, ui, targets, positions)
    if #targets == nil then return end

    ui:action("set_targets", targets)
    ui:action("set_highlight", {})
    ui:action("set_position", positions)

    local keymap = ui_glob.keymap_from_list(targets, "left", "right")

    local state = {
        cursor = List.head(targets),
    }

    local confirm = game.ctx:listen("keypressed")
        :map(function(key)
            local km = {space=true, backspace=false}
            return km[key]
        end)
        :filter(function(v) return v ~= nil end)
        :latest()

    local cursor = game.ctx:listen("keypressed")
        :map(function(key)
            return ui_glob.key(state.cursor or "default", keymap, key)
        end)
        :filter(identity)
        :foreach(function(cursor) state.cursor = cursor end)

    local highlight = cursor
        :map(function(cursor) return {[cursor] = true} end)
        :latest()

    cursor:emit{state.cursor}

    while game.ctx.alive and confirm:empty() do
        ui("set_highlight", highlight:peek())
        game.ctx:yield()
    end

    ui("clear")

    if confirm:peek() then return state.cursor end
end

local function interaction_with_gamestate(game, ui, filter)
    local formation = game.gamestate:ensure(
        component.formation, constants.id.field
    )
    local filter = filter or function() return true end

    if formation:size() == 0 then return end

    local all_positions = field_render.compute_all_actor_position(game.gamestate)

    local targets = formation:values():filter(filter):sort(function(a, b)
        local pos_a = all_positions[a] or vec2()
        local pos_b = all_positions[b] or vec2()

        return pos_a.x < pos_b.x
    end)

    return interaction(game, ui, targets, all_positions)
end

return {
    ui = ui,
    interaction = interaction,
    interaction_with_gamestate = interaction_with_gamestate
}
