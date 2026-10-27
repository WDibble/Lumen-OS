local theme = require("src.theme")
local two_pane = {
    scroll_y = 0,
    target_scroll_y = 0
}

function two_pane.update(dt, selected_game_idx, total_games)
    local m = theme.metrics
    local visible_rows = math.floor(m.right_h / m.row_h)

    -- Auto-scroll target calculation
    local top_idx = math.floor(two_pane.target_scroll_y / m.row_h) + 1
    local bottom_idx = top_idx + visible_rows - 1

    if selected_game_idx > bottom_idx then
        two_pane.target_scroll_y = (selected_game_idx - visible_rows) * m.row_h
    elseif selected_game_idx < top_idx then
        two_pane.target_scroll_y = (selected_game_idx - 1) * m.row_h
    end

    local max_scroll = math.max(0, (total_games * m.row_h) - m.right_h)
    two_pane.target_scroll_y = math.max(0, math.min(two_pane.target_scroll_y, max_scroll))

    -- Kinetic scroll interpolation
    two_pane.scroll_y = two_pane.scroll_y + (two_pane.target_scroll_y - two_pane.scroll_y) * (1.0 - math.exp(-18.0 * dt))
end

function two_pane.draw(system, selected_game_idx)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii

    local games = system.games
    local total_games = #games
    local selected_game = games[selected_game_idx]

    -------------------------------------------------------------------------
    -- LEFT PANE: 440px Hero Preview & Platform Details
    -------------------------------------------------------------------------
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", m.left_x, m.left_y, m.left_w, m.left_h, r.card, r.card)
    love.graphics.setColor(c.card_border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", m.left_x, m.left_y, m.left_w, m.left_h, r.card, r.card)

    -- Hero Artwork Placeholder Stage
    local art_x = m.left_x + 24
    local art_y = m.left_y + 24
    local art_w = m.left_w - 48
    local art_h = 280

    love.graphics.setColor(c.card)
    love.graphics.rectangle("fill", art_x, art_y, art_w, art_h, r.sub, r.sub)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("line", art_x, art_y, art_w, art_h, r.sub, r.sub)

    -- Hero System Tag & Glow
    love.graphics.setColor(c.accent)
    love.graphics.printf(system.id, art_x, art_y + 110, art_w, "center")
    love.graphics.setColor(c.text_muted)
    love.graphics.printf("BOX ART PREVIEW", art_x, art_y + 144, art_w, "center")

    -- Title & Info
    if selected_game then
        love.graphics.setColor(c.text_pri)
        love.graphics.printf(selected_game.name, art_x, art_y + art_h + 24, art_w, "left")

        love.graphics.setColor(c.accent)
        love.graphics.print(system.label, art_x, art_y + art_h + 80)

        love.graphics.setColor(c.text_muted)
        love.graphics.print("File: " .. (selected_game.file or ""), art_x, art_y + art_h + 110)
        love.graphics.print("Platform: " .. system.manufacturer .. " (" .. system.year .. ")", art_x, art_y + art_h + 134)
    end

    -------------------------------------------------------------------------
    -- RIGHT PANE: 780px Virtualized Game List
    -------------------------------------------------------------------------
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", m.right_x, m.right_y, m.right_w, m.right_h, r.card, r.card)
    love.graphics.setColor(c.card_border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", m.right_x, m.right_y, m.right_w, m.right_h, r.card, r.card)

    -- Scissor clipping for 60 FPS zero-reflow virtual list
    love.graphics.setScissor(m.right_x, m.right_y, m.right_w, m.right_h)

    local start_row = math.max(1, math.floor(two_pane.scroll_y / m.row_h))
    local end_row = math.min(total_games, math.ceil((two_pane.scroll_y + m.right_h) / m.row_h))

    for idx = start_row, end_row do
        local game = games[idx]
        local row_y = m.right_y + ((idx - 1) * m.row_h) - two_pane.scroll_y
        local is_selected = (idx == selected_game_idx)

        if is_selected then
            -- Active row highlight
            love.graphics.setColor(c.card_active)
            love.graphics.rectangle("fill", m.right_x + 8, row_y + 4, m.right_w - 24, m.row_h - 8, r.pill, r.pill)

            -- Cyan indicator pill
            love.graphics.setColor(c.accent)
            love.graphics.rectangle("fill", m.right_x + 8, row_y + 8, 4, m.row_h - 16, r.dot, r.dot)

            love.graphics.setColor(c.text_pri)
        else
            love.graphics.setColor(c.text_sec)
        end

        -- Game Title
        love.graphics.print(game.name, m.right_x + 24, row_y + 16)

        -- File Extension / Rom Tag
        local ext = game.file and game.file:match("%.(%w+)$") or "ROM"
        love.graphics.setColor(is_selected and c.accent or c.text_muted)
        love.graphics.printf(ext:upper(), m.right_x + m.right_w - 90, row_y + 16, 60, "right")
    end

    love.graphics.setScissor()

    -- Scrollbar thumb
    if total_games > 0 then
        local scrollbar_track_h = m.right_h - 16
        local thumb_h = math.max(24, scrollbar_track_h * (m.right_h / math.max(m.right_h, total_games * m.row_h)))
        local max_scroll = math.max(1, (total_games * m.row_h) - m.right_h)
        local thumb_y = m.right_y + 8 + ((two_pane.scroll_y / max_scroll) * (scrollbar_track_h - thumb_h))

        love.graphics.setColor(c.card_border)
        love.graphics.rectangle("fill", m.right_x + m.right_w - 10, thumb_y, 4, thumb_h, r.dot, r.dot)
    end
end

return two_pane
