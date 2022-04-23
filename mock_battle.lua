local nw = require "nodeworks"
local gamestate = require "gamestate"
local component = require "component"
local imtween = require "im_tween"

local id = {player="player", bad_guy="bad_guy"}

local player_options = {a = "attack", d = "defend", h = "heal"}

local function print_player_options(ctx)
    print("")
    print("select an action:")
    for key, action in pairs(player_options) do
        printf("%s :: %s", key, action)
    end
end

local function handle_player_input(ctx)
    for _, event in ipairs(ctx:read_event("keypressed")) do
        local key = event:unpack()
        local action = player_options[key]
        if action then
            return action
        else
            --printf("key %s does not map to action", key)
        end
    end
end

local function player_action(ctx)
    print_player_options(ctx)
    while ctx.alive do
        local action = handle_player_input(ctx)
        if action then
            print("Player did a thing:", action)
            return action
        end
        ctx:yield()
    end
end

local function ai_action(ctx)
    print("the ai did something")
end

local function initial_gamestate()
    return gamestate.state()
        :set(component.health, id.player, 5)
        :set(component.max_health, id.player, 10)
        :set(component.health, id.bad_guy, 10)
        :set(component.max_health, id.bad_guy, 10)
end

local function layout()
    local w, h = gfx.getWidth(), gfx.getHeight()
    local mid = spatial(w * 0.5, h, 0, 0)
        :move(0, -40)
        :expand(50, 200, "center", "bottom")

    return {
        [id.player] = mid:move(-200, 0),
        [id.bad_guy] = mid:move(200, 0)
    }
end

local function draw_scene(ctx)
    local pos_tween = ctx.visual_state.tweens.position

    local layout = layout()
    local bad_offset = pos_tween:ensure(id.bad_guy, vec2())
    local player_offset = pos_tween:ensure(id.player, vec2())

    gfx.setColor(0.8, 0.4, 0.2)
    gfx.rectangle(
        "fill", layout[id.bad_guy]:move(bad_offset.x, bad_offset.y):unpack()
    )
    gfx.setColor(0.2, 0.4, 0.8)
    gfx.rectangle(
        "fill", layout[id.player]:move(player_offset.x, player_offset.y):unpack()
    )
end


local function update(ctx, dt)
    for _, tween in pairs(ctx.visual_state.tweens) do
        tween:update(dt)
    end
end

local function reponse(ctx, visual_state)
    ctx.visual_state = visual_state
    while ctx.alive do
        ctx:visit_event("update", update)
        ctx:visit_event("draw", draw_scene)
        ctx:yield()
    end
end

return function(ctx)
    ctx.gamestate = initial_gamestate()

    ctx.visual_state = {
        tweens = {
            position = imtween()
        }
    }

    ctx:fork(require "ui.healthbar", id.player)
    ctx:fork(reponse, ctx.visual_state)

    while ctx.alive do
        ctx:emit("gamestate_step", ctx.gamestate)

        local action = player_action(ctx)
        ctx.gamestate = ctx.gamestate:map(
            component.health, id.player, function(hp) return hp - 1 end
        )
        ai_action(ctx)
    end
end
