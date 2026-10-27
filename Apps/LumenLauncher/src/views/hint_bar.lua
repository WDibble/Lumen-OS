local theme = require("src.theme")
local hint_bar = {}

local function draw_hint_pill(x, y, btn_text, action_text)
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    local btn_w = 32
    if #btn_text > 2 then btn_w = 48 end
    local btn_h = 24

    -- Button badge
    love.graphics.setColor(c.accent_dim)
    love.graphics.rectangle("fill", x, y, btn_w, btn_h, r.pill, r.pill)
    love.graphics.setColor(c.accent)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, btn_w, btn_h, r.pill, r.pill)

    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(c.accent)
    love.graphics.printf(btn_text, x, y + 4, btn_w, "center")

    -- Action label
    local label_x = x + btn_w + 8
    love.graphics.setColor(c.text_sec)
    love.graphics.print(action_text, label_x, y + 4)

    local label_w = f.tiny and f.tiny:getWidth(action_text) or 60
    return btn_w + 8 + label_w + 24
end

function hint_bar.draw(view_mode, current_index, total_count)
    local m = theme.metrics
    local c = theme.colors
    local f = theme.fonts

    local bar_y = m.screen_h - m.hint_h

    -- Background
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", 0, bar_y, m.screen_w, m.hint_h)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", 0, bar_y, m.screen_w, 1)

    -- Dynamic contextual hints
    local hx = 24
    local hy = bar_y + 12

    if view_mode == "carousel" then
        hx = hx + draw_hint_pill(hx, hy, "A", "OPEN")
        hx = hx + draw_hint_pill(hx, hy, "B", "BACK")
        hx = hx + draw_hint_pill(hx, hy, "L1/R1", "TABS")
        hx = hx + draw_hint_pill(hx, hy, "Y", "SYSTEM")
    elseif view_mode == "games" then
        hx = hx + draw_hint_pill(hx, hy, "A", "LAUNCH")
        hx = hx + draw_hint_pill(hx, hy, "B", "CONSOLES")
        hx = hx + draw_hint_pill(hx, hy, "X", "FAVORITE")
        hx = hx + draw_hint_pill(hx, hy, "Y", "MENU")
    elseif view_mode == "settings" then
        hx = hx + draw_hint_pill(hx, hy, "A", "SELECT")
        hx = hx + draw_hint_pill(hx, hy, "< >", "ADJUST")
        hx = hx + draw_hint_pill(hx, hy, "B", "BACK")
        hx = hx + draw_hint_pill(hx, hy, "X", "DEFAULT")
    elseif view_mode == "launch" then
        hx = hx + draw_hint_pill(hx, hy, "B", "EXIT GAME")
    end

    -- Right Tabular Counter chip
    if total_count and total_count > 0 then
        local counter_str = string.format("%d / %d", current_index or 1, total_count)
        if f.sub then love.graphics.setFont(f.sub) end
        local cw = f.sub and f.sub:getWidth(counter_str) or 60
        local cx = m.screen_w - 24 - cw
        love.graphics.setColor(c.text_muted)
        love.graphics.print(counter_str, cx, hy + 4)
    end
end

return hint_bar
