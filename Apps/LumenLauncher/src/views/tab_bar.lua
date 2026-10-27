local theme = require("src.theme")
local tab_bar = {}

local TABS = { "CONSOLES", "APPS", "FAVORITES", "SETTINGS" }

function tab_bar.draw(current_tab)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    local bar_y = m.status_h
    local bar_h = m.tab_h

    -- Bar background
    love.graphics.setColor(c.bg)
    love.graphics.rectangle("fill", 0, bar_y, m.screen_w, bar_h)

    -- Bottom border hairline
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", 0, bar_y + bar_h - 1, m.screen_w, 1)

    -- Left shoulder pill [L1]
    love.graphics.setColor(c.card)
    love.graphics.rectangle("fill", 24, bar_y + 12, 44, 32, r.pill, r.pill)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("line", 24, bar_y + 12, 44, 32, r.pill, r.pill)
    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(c.text_muted)
    love.graphics.printf("L1", 24, bar_y + 20, 44, "center")

    -- Right shoulder pill [R1]
    love.graphics.setColor(c.card)
    love.graphics.rectangle("fill", m.screen_w - 68, bar_y + 12, 44, 32, r.pill, r.pill)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("line", m.screen_w - 68, bar_y + 12, 44, 32, r.pill, r.pill)
    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(c.text_muted)
    love.graphics.printf("R1", m.screen_w - 68, bar_y + 20, 44, "center")

    -- Centered Tab Pills
    local total_tabs = #TABS
    local tab_w = 170
    local tab_gap = 16
    local total_tabs_w = (total_tabs * tab_w) + ((total_tabs - 1) * tab_gap)
    local start_x = (m.screen_w - total_tabs_w) / 2

    for i, name in ipairs(TABS) do
        local x = start_x + (i - 1) * (tab_w + tab_gap)
        local y = bar_y + 8
        local is_active = (i == current_tab)

        if is_active then
            -- Active glow & background
            love.graphics.setColor(c.accent_glow)
            love.graphics.rectangle("fill", x - 2, y - 2, tab_w + 4, 40, r.pill + 2, r.pill + 2)

            love.graphics.setColor(c.card_active)
            love.graphics.rectangle("fill", x, y, tab_w, 36, r.pill, r.pill)

            love.graphics.setColor(c.accent)
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", x, y, tab_w, 36, r.pill, r.pill)

            love.graphics.setColor(c.text_pri)
        else
            love.graphics.setColor(c.card)
            love.graphics.rectangle("fill", x, y, tab_w, 36, r.pill, r.pill)

            love.graphics.setColor(c.card_border)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", x, y, tab_w, 36, r.pill, r.pill)

            love.graphics.setColor(c.text_muted)
        end

        if f.sub then love.graphics.setFont(f.sub) end
        love.graphics.printf(name, x, y + 10, tab_w, "center")
    end
end

return tab_bar
