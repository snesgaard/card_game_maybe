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

local function unpack_args(args)
    if type(args) == "table" then
        return unpack(args)
    else
        return args
    end
end

function gamestate:instance(id, components)
    local state = self

    for comp, args in pairs(components) do
        state = state:set(comp, id, unpack_args(args))
    end

    return state
end

function gamestate:populate(entities)
    local state = self

    for id, components in pairs(entities) do
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

local epoch = {}
epoch.__index = epoch

function epoch.create(gamestate, info, timeline)
    return setmetatable(
        {
            gamestate = gamestate,
            info = info or {},
            timeline = timeline or list(),
            tags = {}
        },
        epoch
    )
end

function epoch:set(tag, info)
    self.tags[tag] = info
    return self
end

function epoch:get(tag)
    return self.tags[tag]
end

function epoch:chain(step_func, ...)
    local next_epoch = step_func(self:tail(), ...)

    if not next_epoch then return self end

    local step = {
        transform = step_func,
        args = {...},
        info = next_epoch.info,
        gamestate = next_epoch.gamestate,
        epoch = self
    }

    self:set(step_func, next_epoch.info)

    for tag, info in pairs(next_epoch.tags) do
        self:set(tag, info)
    end

    self.timeline = self.timeline + list(step) + next_epoch.timeline

    return self:react(step)
end

function epoch:react(step)
    if not self.reaction then return self end
    local r = self.reaction[step.transform]
    if not r then return self end

    local reaction_epoch = r(self, self:tail())

    if not reaction_epoch then return self end

    self.timeline = self.timeline + reaction_epoch.timeline

    return self
end

function epoch:tail()
    local t = self.timeline:tail()
    return t and t.gamestate or self.gamestate
end


return {state=gamestate.create, epoch=epoch.create}
