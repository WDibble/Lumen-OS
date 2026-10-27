local theme = require("src.theme")
local hint_bar = {}

local function draw_pill_badge(x, y, button, label, primary)
    local c = theme.colors
    local r = theme.radii

    -- Button badge
    love.graphics.setColor(primary and c.accent_dim or c.badge_bg)
    love.graphics.rectangle("fill", x, y, 24, 24, r.dot, r.dot)

    love.graphics.setColor(primary and c.accent or c.text_pri)
    love.graphics.printf(button, x, y + 4, 24, "center")

    -- Action label
    love.graphics.setColor(c.text_sec)
    love.graphics.print(label, x + 32, y + 4)

    return 32 + (#label * 9) + 20
end

function hint_bar.draw(in_game_list, current_index, total_count)
    local m = theme.metrics
    local c = theme.colors

    local bar_y = m.screen_h - m.hint_h

    -- Hint bar surface
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", 0, bar_y, m.screen_w, m.hint_h)

    -- Top hairline accent
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", 0, bar_y, m.screen_w, 1)

    -- Action Badges
    local x = 20
    local badge_y = bar_y + 12

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
    love.graphics.setColor(c.text_muted)
    love.graphics.printf(counter_str, m.screen_w - 140, badge_y + 4, 120, "right")
end

return hint_bar
