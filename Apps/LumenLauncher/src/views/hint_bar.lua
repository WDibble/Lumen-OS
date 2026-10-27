local theme = require("src.theme")
local hint_bar = {}

local function draw_pill_badge(x, y, button, label, primary)
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    -- Button badge
    love.graphics.setColor(primary and c.accent_dim or c.badge_bg)
    love.graphics.rectangle("fill", x, y, 26, 26, r.pill, r.pill)

    if primary then
        love.graphics.setColor(c.accent)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x, y, 26, 26, r.pill, r.pill)
    end

    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(primary and c.accent or c.text_pri)
    love.graphics.printf(button, x, y + 5, 26, "center")

    -- Action label
    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_sec)
    love.graphics.print(label, x + 34, y + 4)

    local str_w = f.sub and f.sub:getWidth(label) or (#label * 9)
    return 34 + str_w + 24
end

function hint_bar.draw(in_game_list, current_index, total_count)
    local m = theme.metrics
    local c = theme.colors
    local f = theme.fonts

    local bar_y = m.screen_h - m.hint_h

    -- Hint bar surface
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", 0, bar_y, m.screen_w, m.hint_h)

    -- Top hairline accent
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", 0, bar_y, m.screen_w, 1)

    -- Action Badges
    local x = 24
    local badge_y = bar_y + 11

    if not in_game_list then
        x = x + draw_pill_badge(x, badge_y, "A", "OPEN", true)
        x = x + draw_pill_badge(x, badge_y, "X", "SEARCH", false)
        x = x + draw_pill_badge(x, badge_y, "Y", "OPTIONS", false)
    else
        x = x + draw_pill_badge(x, badge_y, "A", "LAUNCH", true)
        x = x + draw_pill_badge(x, badge_y, "B", "BACK", false)
        x = x + draw_pill_badge(x, badge_y, "X", "FAVORITE", false)
    end

    -- Tabular Right Counter
    local counter_str = string.format("%d / %d", current_index, total_count)
    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_muted)
    love.graphics.printf(counter_str, m.screen_w - 160, badge_y + 4, 140, "right")
end

return hint_bar
