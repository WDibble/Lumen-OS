local theme = require("src.theme")
local settings_view = {
    scroll_y = 0,
    target_scroll_y = 0
}

function settings_view.update(dt, selected_row, total_rows)
    local m = theme.metrics
    local visible_rows = math.floor(m.right_h / m.row_h)

    local top_idx = math.floor(settings_view.target_scroll_y / m.row_h) + 1
    local bottom_idx = top_idx + visible_rows - 1

    if selected_row > bottom_idx then
        settings_view.target_scroll_y = (selected_row - visible_rows) * m.row_h
    elseif selected_row < top_idx then
        settings_view.target_scroll_y = (selected_row - 1) * m.row_h
    end

    local max_scroll = math.max(0, (total_rows * m.row_h) - m.right_h)
    settings_view.target_scroll_y = math.max(0, math.min(settings_view.target_scroll_y, max_scroll))
    settings_view.scroll_y = settings_view.scroll_y + (settings_view.target_scroll_y - settings_view.scroll_y) * (1.0 - math.exp(-18.0 * dt))
end

function settings_view.draw(settings_list, selected_row)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    local total_settings = #settings_list
    local selected_item = settings_list[selected_row]

    -------------------------------------------------------------------------
    -- LEFT PANE: 440px Hero Pedestal
    -------------------------------------------------------------------------
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", m.left_x, m.left_y, m.left_w, m.left_h, r.card, r.card)
    love.graphics.setColor(c.card_border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", m.left_x, m.left_y, m.left_w, m.left_h, r.card, r.card)

    -- Artwork Stage
    local art_x = m.left_x + 24
    local art_y = m.left_y + 24
    local art_w = m.left_w - 48
    local art_h = 240

    love.graphics.setColor(c.card)
    love.graphics.rectangle("fill", art_x, art_y, art_w, art_h, r.sub, r.sub)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("line", art_x, art_y, art_w, art_h, r.sub, r.sub)

    local ped_x = art_x + (art_w / 2)
    local ped_y = art_y + (art_h / 2)
    love.graphics.setColor(c.accent_glow)
    love.graphics.circle("fill", ped_x, ped_y, 90)

    -- High-tech Concentric Gear Vector Glyph
    love.graphics.setColor(c.accent)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", ped_x, ped_y, 44)
    love.graphics.circle("fill", ped_x, ped_y, 18)
    for angle = 0, 7 do
        local a = angle * (math.pi / 4)
        local tx = ped_x + math.cos(a) * 44
        local ty = ped_y + math.sin(a) * 44
        love.graphics.circle("fill", tx, ty, 7)
    end

    -- Title & Subtitle
    local info_y = art_y + art_h + 16
    if f.title then love.graphics.setFont(f.title) end
    love.graphics.setColor(c.text_pri)
    love.graphics.printf("LUMEN SETTINGS", art_x, info_y, art_w, "center")

    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_muted)
    love.graphics.printf("TrimUI Smart Pro Hardware Config", art_x, info_y + 32, art_w, "center")

    -- Stepper Active Badge
    local badge_w = 210
    local badge_x = art_x + (art_w - badge_w) / 2
    local badge_y = info_y + 64
    love.graphics.setColor(c.accent_dim)
    love.graphics.rectangle("fill", badge_x, badge_y, badge_w, 28, r.pill, r.pill)
    love.graphics.setColor(c.accent)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", badge_x, badge_y, badge_w, 28, r.pill, r.pill)
    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.printf("D-PAD STEPPERS ACTIVE", badge_x, badge_y + 7, badge_w, "center")

    -- Selected Setting Explanation Box
    if selected_item then
        local detail_y = badge_y + 44
        local detail_h = m.left_h - (detail_y - m.left_y) - 16
        love.graphics.setColor(c.card)
        love.graphics.rectangle("fill", art_x, detail_y, art_w, detail_h, r.sub, r.sub)
        love.graphics.setColor(c.card_border)
        love.graphics.rectangle("line", art_x, detail_y, art_w, detail_h, r.sub, r.sub)

        if f.header then love.graphics.setFont(f.header) end
        love.graphics.setColor(c.accent)
        love.graphics.printf(selected_item.name, art_x + 16, detail_y + 14, art_w - 32, "left")

        if f.body then love.graphics.setFont(f.body) end
        love.graphics.setColor(c.text_pri)
        local cur_val = selected_item.options[selected_item.selected] or ""
        love.graphics.print(string.format("Current: %s", cur_val), art_x + 16, detail_y + 46)

        if f.sub then love.graphics.setFont(f.sub) end
        love.graphics.setColor(c.text_muted)
        love.graphics.printf(selected_item.desc, art_x + 16, detail_y + 76, art_w - 32, "left")
    end

    -------------------------------------------------------------------------
    -- RIGHT PANE: 780px List of 9 Settings with Steppers
    -------------------------------------------------------------------------
    love.graphics.setScissor(m.right_x, m.right_y, m.right_w, m.right_h)

    for i, s in ipairs(settings_list) do
        local row_y = m.right_y + ((i - 1) * m.row_h) - settings_view.scroll_y

        if row_y > m.right_y - m.row_h and row_y < m.right_y + m.right_h then
            local is_selected = (i == selected_row)
            local row_x = m.right_x + (is_selected and 8 or 0)
            local row_w = m.right_w - (is_selected and 8 or 0)
            local rh = m.row_h - 10

            -- Row Box
            if is_selected then
                love.graphics.setColor(c.card_active)
                love.graphics.rectangle("fill", row_x, row_y, row_w, rh, r.card, r.card)
                love.graphics.setColor(c.accent)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", row_x, row_y, row_w, rh, r.card, r.card)
            else
                love.graphics.setColor(c.card)
                love.graphics.rectangle("fill", row_x, row_y, row_w, rh, r.card, r.card)
                love.graphics.setColor(c.card_border)
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", row_x, row_y, row_w, rh, r.card, r.card)
            end

            -- Index Number
            if f.body then love.graphics.setFont(f.body) end
            love.graphics.setColor(is_selected and c.accent or c.text_muted)
            love.graphics.printf(string.format("%02d", i), row_x + 16, row_y + 22, 32, "left")

            -- Setting Name & Description
            local text_x = row_x + 60
            local text_max_w = row_w - 360
            if f.header then love.graphics.setFont(f.header) end
            love.graphics.setColor(is_selected and c.text_pri or c.text_sec)
            love.graphics.printf(s.name, text_x, row_y + 12, text_max_w, "left")

            if f.tiny then love.graphics.setFont(f.tiny) end
            love.graphics.setColor(c.text_muted)
            love.graphics.printf(s.desc, text_x, row_y + 40, text_max_w, "left")

            -- Stepper Control (◄ [ Option Pill ] ►)
            local stepper_w = 260
            local stepper_h = 36
            local stepper_x = row_x + row_w - stepper_w - 16
            local stepper_y = row_y + (rh - stepper_h) / 2

            -- Left Arrow (Vector Triangle)
            love.graphics.setColor(is_selected and c.accent or c.text_muted)
            love.graphics.polygon("fill",
                stepper_x + 24, stepper_y + 11,
                stepper_x + 12, stepper_y + 18,
                stepper_x + 24, stepper_y + 25
            )

            -- Center Option Pill
            local pill_x = stepper_x + 36
            local pill_w = stepper_w - 72
            love.graphics.setColor(c.card_border)
            love.graphics.rectangle("fill", pill_x, stepper_y, pill_w, stepper_h, r.pill, r.pill)

            if is_selected then
                love.graphics.setColor(c.accent)
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", pill_x, stepper_y, pill_w, stepper_h, r.pill, r.pill)
            end

            local cur_opt = s.options[s.selected] or ""
            if f.tiny then love.graphics.setFont(f.tiny) end
            love.graphics.setColor(is_selected and c.text_pri or c.text_sec)
            love.graphics.printf(cur_opt, pill_x + 4, stepper_y + 10, pill_w - 8, "center")

            -- Right Arrow (Vector Triangle)
            love.graphics.setColor(is_selected and c.accent or c.text_muted)
            love.graphics.polygon("fill",
                stepper_x + stepper_w - 24, stepper_y + 11,
                stepper_x + stepper_w - 12, stepper_y + 18,
                stepper_x + stepper_w - 24, stepper_y + 25
            )
        end
    end

    love.graphics.setScissor()
end

return settings_view
