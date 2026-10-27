local theme = require("src.theme")
local two_pane = {
    scroll_y = 0,
    target_scroll_y = 0
}

local image_cache = {}

local function get_cached_image(item_id)
    if image_cache[item_id] ~= nil then
        return image_cache[item_id]
    end

    local candidate_paths = {
        "/mnt/SDCARD/Emus/" .. item_id .. "/icon.png",
        "../../Emus/" .. item_id .. "/icon.png"
    }

    for _, path in ipairs(candidate_paths) do
        local f = io.open(path, "rb")
        if f then
            local bytes = f:read("*a")
            f:close()
            local ok, file_data = pcall(love.filesystem.newFileData, bytes, "icon.png")
            if ok and file_data then
                local ok2, img_data = pcall(love.image.newImageData, file_data)
                if ok2 and img_data then
                    local ok3, img = pcall(love.graphics.newImage, img_data)
                    if ok3 and img then
                        image_cache[item_id] = img
                        return img
                    end
                end
            end
        end
    end

    image_cache[item_id] = false
    return false
end

function two_pane.update(dt, selected_game_idx, total_games)
    local m = theme.metrics
    local visible_rows = math.floor(m.right_h / m.row_h)

    local top_idx = math.floor(two_pane.target_scroll_y / m.row_h) + 1
    local bottom_idx = top_idx + visible_rows - 1

    if selected_game_idx > bottom_idx then
        two_pane.target_scroll_y = (selected_game_idx - visible_rows) * m.row_h
    elseif selected_game_idx < top_idx then
        two_pane.target_scroll_y = (selected_game_idx - 1) * m.row_h
    end

    local max_scroll = math.max(0, (total_games * m.row_h) - m.right_h)
    two_pane.target_scroll_y = math.max(0, math.min(two_pane.target_scroll_y, max_scroll))
    two_pane.scroll_y = two_pane.scroll_y + (two_pane.target_scroll_y - two_pane.scroll_y) * (1.0 - math.exp(-18.0 * dt))
end

function two_pane.draw(system, selected_game_idx)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    local games = system.games or {}
    local total_games = #games
    local selected_game = games[selected_game_idx]
    local sys_color = system.color and theme.hex_to_color(system.color) or c.accent

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
    local glow_col = system.color and theme.hex_to_color(system.color, 0.22) or c.accent_glow
    love.graphics.setColor(glow_col)
    love.graphics.circle("fill", ped_x, ped_y, 90)

    local img = get_cached_image(system.id)
    if img then
        love.graphics.setColor(1, 1, 1, 1.0)
        local iw, ih = img:getDimensions()
        local img_scale = 180 / math.max(iw, ih)
        local ix = ped_x - (iw * img_scale / 2)
        local iy = ped_y - (ih * img_scale / 2)
        love.graphics.draw(img, ix, iy, 0, img_scale, img_scale)
    else
        if f.title then love.graphics.setFont(f.title) end
        love.graphics.setColor(sys_color)
        love.graphics.printf(system.id, art_x, art_y + 90, art_w, "center")
    end

    -- System Info & Badge
    local sys_info_y = art_y + art_h + 16
    if f.title then love.graphics.setFont(f.title) end
    love.graphics.setColor(c.text_pri)
    love.graphics.printf(system.label, art_x, sys_info_y, art_w, "center")

    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_muted)
    love.graphics.printf(string.format("%s • %s", system.maker or "System", system.year or "2024"), art_x, sys_info_y + 32, art_w, "center")

    -- Installed Titles Count Badge
    local count_badge_w = 200
    local count_badge_x = art_x + (art_w - count_badge_w) / 2
    local count_badge_y = sys_info_y + 64
    love.graphics.setColor(c.accent_dim)
    love.graphics.rectangle("fill", count_badge_x, count_badge_y, count_badge_w, 28, r.pill, r.pill)
    love.graphics.setColor(sys_color)
    love.graphics.rectangle("line", count_badge_x, count_badge_y, count_badge_w, 28, r.pill, r.pill)
    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.printf(string.format("%d TITLES INSTALLED", total_games), count_badge_x, count_badge_y + 7, count_badge_w, "center")

    -- Selected Game Detail Box
    if selected_game then
        local detail_y = count_badge_y + 44
        local detail_h = m.left_h - (detail_y - m.left_y) - 16
        love.graphics.setColor(c.card)
        love.graphics.rectangle("fill", art_x, detail_y, art_w, detail_h, r.sub, r.sub)
        love.graphics.setColor(c.card_border)
        love.graphics.rectangle("line", art_x, detail_y, art_w, detail_h, r.sub, r.sub)

        if f.header then love.graphics.setFont(f.header) end
        love.graphics.setColor(c.text_pri)
        love.graphics.printf(selected_game.name, art_x + 12, detail_y + 12, art_w - 24, "left")

        if f.sub then love.graphics.setFont(f.sub) end
        love.graphics.setColor(sys_color)
        love.graphics.print(string.format("%s • %s", selected_game.genre or "ROM", selected_game.year or system.year), art_x + 12, detail_y + 68)

        if f.tiny then love.graphics.setFont(f.tiny) end
        love.graphics.setColor(c.text_muted)
        love.graphics.printf(selected_game.file or "", art_x + 12, detail_y + 92, art_w - 24, "left")
    end

    -------------------------------------------------------------------------
    -- RIGHT PANE: 780px Virtualized Game List with 76px Rows
    -------------------------------------------------------------------------
    love.graphics.setScissor(m.right_x, m.right_y, m.right_w, m.right_h)

    for i, g in ipairs(games) do
        local row_y = m.right_y + ((i - 1) * m.row_h) - two_pane.scroll_y

        if row_y > m.right_y - m.row_h and row_y < m.right_y + m.right_h then
            local is_selected = (i == selected_game_idx)
            local row_x = m.right_x + (is_selected and 8 or 0)
            local row_w = m.right_w - (is_selected and 8 or 0)
            local rh = m.row_h - 10

            -- Row Background & Border
            if is_selected then
                love.graphics.setColor(c.card_active)
                love.graphics.rectangle("fill", row_x, row_y, row_w, rh, r.card, r.card)
                love.graphics.setColor(sys_color)
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
            love.graphics.setColor(is_selected and sys_color or c.text_muted)
            love.graphics.printf(string.format("%02d", i), row_x + 16, row_y + 22, 32, "left")

            -- Title & Subtitle (2-line layout)
            local text_x = row_x + 60
            local text_max_w = row_w - 260
            if f.header then love.graphics.setFont(f.header) end
            love.graphics.setColor(is_selected and c.text_pri or c.text_sec)
            love.graphics.printf(g.name, text_x, row_y + 12, text_max_w, "left")

            if f.tiny then love.graphics.setFont(f.tiny) end
            love.graphics.setColor(c.text_muted)
            local sub_meta = string.format("%s • %s • %s", g.genre or "ROM", g.year or system.year, g.file or "")
            love.graphics.printf(sub_meta, text_x, row_y + 40, text_max_w, "left")

            -- Focused Row: "PRESS (A) TO LAUNCH" Pill Badge
            if is_selected then
                local launch_pill_w = 170
                local launch_pill_h = 32
                local launch_pill_x = row_x + row_w - launch_pill_w - 16
                local launch_pill_y = row_y + (rh - launch_pill_h) / 2

                love.graphics.setColor(sys_color)
                love.graphics.rectangle("fill", launch_pill_x, launch_pill_y, launch_pill_w, launch_pill_h, r.pill, r.pill)

                if f.tiny then love.graphics.setFont(f.tiny) end
                love.graphics.setColor(c.bg)
                love.graphics.printf("PRESS (A) TO LAUNCH", launch_pill_x, launch_pill_y + 8, launch_pill_w, "center")
            else
                -- Unfocused: subtle ROM extension chip
                local ext = (g.file or ""):match("%.(%w+)$") or "ROM"
                local ext_w = 56
                local ext_x = row_x + row_w - ext_w - 16
                local ext_y = row_y + (rh - 24) / 2
                love.graphics.setColor(c.badge_bg)
                love.graphics.rectangle("fill", ext_x, ext_y, ext_w, 24, r.pill, r.pill)
                if f.tiny then love.graphics.setFont(f.tiny) end
                love.graphics.setColor(c.text_muted)
                love.graphics.printf(ext:upper(), ext_x, ext_y + 5, ext_w, "center")
            end
        end
    end

    love.graphics.setScissor()
end

return two_pane
