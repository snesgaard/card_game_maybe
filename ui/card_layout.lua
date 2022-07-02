local layout_render = require "ui.layout_render"
local render = require "render"

local card_layout = inherit(layout_render)

local function compute_card_raw(layout, mid, cards, revealed, dx)
    if #cards == 0 then return end


end

function card_layout.draw_card(ctx, state, rect, id)
    render.draw_card(x, y, card_data)
end

function card_layout.draw(ctx, state)

end

return card_layout
