local gamestate = require "gamestate"

local function bar_component(v)
    return v
end

local function write_foo(gs, value)
    return gs:set(bar_component, "foo", value), "foobar"
end

local function write_foo_double(gs, value)
    return gs:set(bar_component, "foo", value * 2), "2xfoobar"
end

local function map_foo(hist, value)
    return hist:advance(write_foo, value)
end

local function react_on_foo_double(hist, step)
    if step.func == write_foo then
        return hist:advance(write_foo_double, 50)
    end
end

T("gamestate", function(T)
    local gs = gamestate.state()
    local hist = gamestate.history(gs)
        :advance(write_foo, 22)

    T("one advance", function(T)
        T:assert(#hist.steps == 1)
        T:assert(hist:tail():get(bar_component, "foo") == 22)

        local last_step = hist.steps:tail()
        T:assert(last_step)
        T:assert(last_step.info == "foobar")
        T:assert(last_step.func == write_foo)
    end)

    T("test find", function(T)
        hist:advance(write_foo_double, 10)

        local step = hist:find(function(step)
            return step.func == write_foo
        end)

        T:assert(step)
        T:assert(step.func == write_foo)

        local step2x = hist:find(function(step)
            return step.info == "2xfoobar"
        end)

        T:assert(step2x)
        T:assert(step2x.func == write_foo_double)
    end)

    T("test map", function(T)
        hist:map(map_foo, 3)

        T:assert(#hist.steps == 2)
        T:assert(hist:tail():get(bar_component, "foo") == 3)
    end)

    T("test react", function(T)
        hist
            :set_react(react_on_foo_double)
            :advance(write_foo, 2)

        T:assert(#hist.steps == 3)
        T:assert(hist.steps:tail().func == write_foo_double)
        T:assert(hist.steps:tail().parent ~= nil)
    end)

    T("test tag", function(T)
        hist:advance("distag", write_foo, 5)
        local last_step = hist.steps:tail()

        T:assert(last_step.tag == "distag")
    end)
end)
