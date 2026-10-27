local theme = require("src.theme")
local carousel = {
    current_x = 0,
    target_x  = 0,
    speed     = 14.0
}

local image_cache = {}

local function get_cached_image(item_id)
    if image_cache[item_id] ~= nil then
        return image_cache[item_id]
    end

    local candidate_paths = {
        "/mnt/SDCARD/Emus/" .. item_id .. "/icon.png",
        "../../Emus/" .. item_id .. "/icon.png",
        "/mnt/SDCARD/Apps/" .. item_id .. "/icon.png",
        "../../Apps/" .. item_id .. "/icon.png"
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

function carousel.update(dt, selected_index, total_items)
    local m = theme.metrics
    carousel.target_x = -((selected_index - 1) * m.card_pitch)
    carousel.current_x = carousel.current_x + (carousel.target_x - carousel.current_x) * (1.0 - math.exp(-carousel.speed * dt))
end

function carousel.draw(items, selected_index)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    local center_screen_x = m.screen_w / 2
    local center_screen_y = m.stage_y + (m.stage_h / 2)

    if #items == 0 then
        -- Empty State Card
        local ew, eh = 440, 280
        local ex = center_screen_x - (ew / 2)
        local ey = center_screen_y - (eh / 2)
        love.graphics.setColor(c.card)
        love.graphics.rectangle("fill", ex, ey, ew, eh, r.card, r.card)
        love.graphics.setColor(c.card_border)
        love.graphics.rectangle("line", ex, ey, ew, eh, r.card, r.card)
        if f.header then love.graphics.setFont(f.header) end
        love.graphics.setColor(c.text_pri)
        love.graphics.printf("NO ITEMS AVAILABLE", ex, ey + 90, ew, "center")
        if f.sub then love.graphics.setFont(f.sub) end
        love.graphics.setColor(c.text_muted)
        love.graphics.printf("Copy games or apps to the SD Card.", ex, ey + 130, ew, "center")
        return
    end

    for i, item in ipairs(items) do
        local card_center_x = center_screen_x + carousel.current_x + ((i - 1) * m.card_pitch)

        if card_center_x > -260 and card_center_x < m.screen_w + 260 then
            local is_selected = (i == selected_index)
            local dist = math.abs(card_center_x - center_screen_x)
            local norm_dist = math.min(1.0, dist / m.card_pitch)

            local scale = is_selected and 1.0 or (0.92 - (norm_dist * 0.04))
            local w = m.card_w * scale
            local h = m.card_h * scale
            local x = card_center_x - (w / 2)
            local y = center_screen_y - (h / 2)

            local item_color = item.color and theme.hex_to_color(item.color) or c.accent

            -- Drop Shadow
            love.graphics.setColor(c.shadow)
            love.graphics.rectangle("fill", x + 4, y + 10, w, h, r.card, r.card)

            -- Card Surface
            love.graphics.setColor(is_selected and c.card_active or c.card)
            love.graphics.rectangle("fill", x, y, w, h, r.card, r.card)

            -- Border
            if is_selected then
                love.graphics.setColor(item_color)
                love.graphics.setLineWidth(2.5)
                love.graphics.rectangle("line", x, y, w, h, r.card, r.card)
                love.graphics.rectangle("fill", x + 32, y + 2, w - 64, 4, r.dot, r.dot)
            else
                love.graphics.setColor(c.card_border)
                love.graphics.setLineWidth(1.0)
                love.graphics.rectangle("line", x, y, w, h, r.card, r.card)
            end

            -- Artwork Stage & Ambient Radial Glow
            local stage_center_y = y + 130 * scale
            if is_selected then
                local glow_col = item.color and theme.hex_to_color(item.color, 0.20) or c.accent_glow
                love.graphics.setColor(glow_col)
                love.graphics.circle("fill", card_center_x, stage_center_y, 90 * scale)
            end

            local img = get_cached_image(item.id or item.name)
            if img then
                love.graphics.setColor(1, 1, 1, is_selected and 1.0 or 0.65)
                local iw, ih = img:getDimensions()
                local target_size = (is_selected and 180 or 150) * scale
                local img_scale = target_size / math.max(iw, ih)
                local ix = card_center_x - (iw * img_scale / 2)
                local iy = stage_center_y - (ih * img_scale / 2)
                love.graphics.draw(img, ix, iy, 0, img_scale, img_scale)
            else
                local glyph_box_y = y + 36 * scale
                love.graphics.setColor(c.badge_bg)
                love.graphics.rectangle("fill", x + 30 * scale, glyph_box_y, w - 60 * scale, 160 * scale, r.sub, r.sub)
                if f.title then love.graphics.setFont(f.title) end
                love.graphics.setColor(is_selected and item_color or c.text_sec)
                love.graphics.printf(item.id or item.name:sub(1,6), x, glyph_box_y + 60 * scale, w, "center")
            end

            -- Title & Metadata
            local label_y = y + 246 * scale
            if f.header then love.graphics.setFont(f.header) end
            love.graphics.setColor(is_selected and c.text_pri or c.text_sec)
            love.graphics.printf(item.label or item.name, x + 16, label_y, w - 32, "center")

            local meta_str = item.desc or string.format("%s • %s", item.maker or "System", item.year or "2024")
            if f.sub then love.graphics.setFont(f.sub) end
            love.graphics.setColor(c.text_muted)
            love.graphics.printf(meta_str, x + 16, label_y + 36 * scale, w - 32, "center")

            -- Bottom Pill Badge
            local badge_w = 140 * scale
            local badge_h = 32 * scale
            local badge_x = card_center_x - (badge_w / 2)
            local badge_y = y + h - (52 * scale)

            local count_str = item.games and string.format("%d TITLES", #item.games) or (item.category or "SYSTEM")

            love.graphics.setColor(is_selected and c.accent_dim or c.badge_bg)
            love.graphics.rectangle("fill", badge_x, badge_y, badge_w, badge_h, r.pill, r.pill)

            if is_selected then
                love.graphics.setColor(item_color)
                love.graphics.setLineWidth(1.0)
                love.graphics.rectangle("line", badge_x, badge_y, badge_w, badge_h, r.pill, r.pill)
            end

            if f.tiny then love.graphics.setFont(f.tiny) end
            love.graphics.setColor(is_selected and item_color or c.text_sec)
            love.graphics.printf(count_str, badge_x, badge_y + 8 * scale, badge_w, "center")
        end
    end
end

return carousel
