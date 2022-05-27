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

local transform = {}

function transform.foo(gs)
    return gamestate.epoch(gs):chain(transform.bar)
end

function transform.bar(gs)
    return gamestate.epoch(gs):chain(transform.baz)
end

function transform.baz(gs)
    return gamestate.epoch(gs)
end

T("epoch", function(T)
    local gs = gamestate.state()

    T("foo", function(T)
        local epoch = gamestate.epoch(gs):chain(transform.foo)

        T:assert(epoch.timeline:size() == 3)
        T:assert(epoch.tags[transform.foo])
        T:assert(epoch.tags[transform.bar])
        T:assert(epoch.tags[transform.baz])

        local order = {transform.foo, transform.bar, transform.baz}

        for index, trans in ipairs(order) do
            T:assert(epoch.timeline[index].transform == trans)
        end
    end)

    T("bar", function(T)
        local epoch = gamestate.epoch(gs):chain(transform.bar)

        T:assert(epoch.timeline:size() == 2)
        T:assert(epoch.tags[transform.bar])
        T:assert(epoch.tags[transform.baz])
    end)

end)
