local gamestate = {}
gamestate.__index = gamestate

function gamestate.create(prev_state)
    local prev_state = prev_state or {}
    local next_state = {}
    for key, value in pairs(prev_state) do
        next_state[key] = value
    end
    return setmetatable(next_state, gamestate)
end

function gamestate:get(component, id)
    local c = self[component] or {}
    return c[id]
end

function gamestate:set(component, id, ...)
    local next_state = gamestate.create(self)
    local d = next_state[component] or dict()
    next_state[component] = d:set(id, component(...))
    return next_state
end

function gamestate:clear(id)
    local next_state = gamestate.create(self)
    for component, dict in pairs(next_state) do
        if dict:has(id) then next_state[component] = dict:set(id) end
    end
    return next_state
end

function gamestate:intersection(...)
    local components = {...}
    local entity_list = list()
    if #components == 0 then return entity_list end

    -- Retrieve component tables
    local component_tables = List.map(
        components,
        function(c) return self[c] or dict() end
    )
    -- Sort in order of ascending entity count
    table.sort(component_tables, function(a, b) return a:size() < b:size() end)

    -- Start counting how many times a given entity is observed in the
    -- different tables. We initialize the observation count using the table
    -- with the smallest member count. This is the smallest number of possible
    -- candidates that we need to check
    local observation_count = {}
    for entity, _ in pairs(component_tables:head()) do
        observation_count[entity] = 1
    end

    -- Run through all the other tables and count how many times each entity
    -- occurs
    for i = 2, #component_tables do
        local ct = component_tables[i]
        for entity, count in pairs(observation_count) do
            if ct[entity] then
                observation_count[entity] = count + 1
            end
        end
    end

    -- Entities which occurs in all tables are considered valid and written
    -- to the output list
    for entity, count in pairs(observation_count) do
        if count == #component_tables then
            table.insert(entity_list, entity)
        end
    end

    return entity_list
end

local history = {}
history.__index = history

function history.create(initial_gamestate)
    return setmetatable(
        {
            initial_gamestate = initial_gamestate or gamestate.create(),
            step_stack = stack(),
            steps = list()
        },
        history
    )
end

function history:set_react(react)
    self.react = react
    return self
end

function history:set_proact(proact)
    self.proact = proact
    return self
end

function history:tail()
    return #self.steps > 0 and self.steps:tail().gamestate or self.initial_gamestate
end

local function format_args_for_advance(first, second, ...)
    if type(first) == "function" then
        return first, {second, ...}
    else
        return second, {...}, first
    end
end

local function fetch_reaction(react, step)
    if not react then return end

    if type(react) == "function" then
        return react
    elseif type(react) == "table" then
        return react[step.func]
    else
        errorf("Unsupported type %s", type(react))
    end
end

function history:advance(...)
    local func, args, tag = format_args_for_advance(...)

    local next_gs, info = func(self:tail(), unpack(args))

    local step = {
        gamestate = next_gs or self:tail(),
        func = func,
        args = args,
        info = info or {},
        tag = tag,
        parent = self.step_stack:peek()
    }
    table.insert(self.steps, step)

    local react = fetch_reaction(self.react, step)

    if not react then return self end

    self.step_stack:push(step)
    react(self, step)
    self.step_stack:pop()
    return self
end

function history:map(func, ...)
    return func(self, ...) or self
end

function history:find(func, ...)
    for i = #self.steps, 1, -1 do
        local s = self.steps[i]
        if func(s, ...) then return s end
    end
end

function history:prune(max_size)
    local size = #self.steps
    self.steps = self.steps:sub(math.max(1, size - max_size), size)
    return self
end

return {state=gamestate.create, history=history.create}
