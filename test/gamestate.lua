local gamestate = require "gamestate"

local component = {}

function component.foo() return "foo" end

function component.bar() return "bar" end

local ids = {
    player = "player",
    other = "other"
}

T("gamestate", function(T)
    local gamestate = gamestate.state()

    T("set", function(T)
        local next_gamestate = gamestate
            :set(component.foo, ids.player)

        T:assert(not gamestate:get(component.foo, ids.player))
        T:assert(next_gamestate:get(component.foo, ids.player) == component.foo())
    end)

    T("instance", function(T)
        local data = {
            [component.bar] = {},
            [component.foo] = {}
        }

        local next_gs = gamestate
            :instance(ids.player, data)

        T:assert(next_gs:get(component.bar, ids.player) == component.bar())
        T:assert(next_gs:get(component.foo, ids.player) == component.foo())
    end)

    T("populate", function(T)
        local data = {
            [ids.player] = {
                [component.bar] = {}
            },
            [ids.other] = {
                [component.foo] = {},
                [component.bar] = {}
            }
        }

        local next_gs = gamestate:populate(data)

        for id, components in pairs(data) do
            for comp, _ in pairs(components) do
                T:assert(next_gs:get(comp, id))
                T:assert(not gamestate:get(comp, id))
            end
        end
    end)
end)

local component = {}

function component.health(hp) return hp or 0 end

local transforms = {}

function transforms.heal(epoch, gs, target, heal)
    if heal <= 0 then return end

    local next_gs = gs
        :map(component.health, target, function(hp) return hp + heal end)

    epoch(transforms.heal, target, heal - 1)
end

T("epoch", function(T)
    local data = {
        [ids.player] = {
            [component.health] = {10}
        },
        [ids.other] = {
            [component.health] = {5}
        }
    }

    local gs = gamestate.state():populate(data)

    local epoch = gamestate.epoch(gs)

     T("heal", function(T)
         epoch(transforms.heal, target, 3)
     end)
end)
