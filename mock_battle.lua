local nw = require "nodeworks"
local gamestate = require "gamestate"

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
            break
        end
        ctx:yield()
    end
end

local function ai_action(ctx)
    print("the ai did something")
end

return function(ctx)
    while ctx.alive do
        player_action(ctx)
        ai_action(ctx)
    end
end
