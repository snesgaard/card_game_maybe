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
    if id == nil then error("Id was nil") end
    return c[id]
end

function gamestate:component(component)
    return self[component]
end

function gamestate:set(component, id, ...)
    local next_state = gamestate.create(self)
    local d = next_state[component] or dict()
    next_state[component] = d:set(id, component(...))
    return next_state
end

function gamestate:map(component, id, func, ...)
    local value = self:get(component, id)
    if not value then return self end
    local next_value = func(value, ...)
    return self:set(component, id, next_value)
end

function gamestate:clear(id)
    local next_state = gamestate.create(self)
    for component, dict in pairs(next_state) do
        if dict:has(id) then next_state[component] = dict:set(id) end
    end
    return next_state
end

function gamestate:ensure(component, id)
    return self:get(component, id) or component()
end

function gamestate:instance(id, components)
    local state = self

    for comp, args in pairs(components) do
        state = state:set(comp, id, unpack(args))
    end

    return state
end

function gamestate:populate(data)
    local state = self

    for id, components in pairs(data) do
        state = state:instance(id, components)
    end

    return state
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

return {state=gamestate.create}
