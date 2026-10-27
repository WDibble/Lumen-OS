local theme = require("src.theme")
local carousel = {
    current_x = 0,
    target_x  = 0,
    speed     = 14.0
}

local console_cache = {}

local function get_console_image(sys_id)
    if console_cache[sys_id] ~= nil then
        return console_cache[sys_id]
    end
    local candidate_paths = {
        "/mnt/SDCARD/Emus/" .. sys_id .. "/icon.png",
        "../../Emus/" .. sys_id .. "/icon.png"
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
                        console_cache[sys_id] = img
                        return img
                    end
                end
            end
        end
    end
    console_cache[sys_id] = false
    return false
end

function carousel.update(dt, selected_index, total_systems)
    local m = theme.metrics
    local card_pitch = m.card_w + m.card_gap
    carousel.target_x = -((selected_index - 1) * card_pitch)

    -- Kinetic spring smoothing (exponential critically damped decay)
    carousel.current_x = carousel.current_x + (carousel.target_x - carousel.current_x) * (1.0 - math.exp(-carousel.speed * dt))
end

function carousel.draw(systems, selected_index)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    local center_screen_x = m.screen_w / 2
    local center_screen_y = m.stage_y + (m.stage_h / 2)
    local card_pitch = m.card_w + m.card_gap

    for i, sys in ipairs(systems) do
        local card_center_x = center_screen_x + carousel.current_x + ((i - 1) * card_pitch)

        -- Cull cards completely outside visible horizontal bounds
        if card_center_x > -240 and card_center_x < m.screen_w + 240 then
            local is_selected = (i == selected_index)
            local dist = math.abs(card_center_x - center_screen_x)
            local norm_dist = math.min(1.0, dist / card_pitch)

            -- Geometric depth transforms
            local scale = 1.0 - (norm_dist * 0.12)
            local w = m.card_w * scale
            local h = m.card_h * scale
            local x = card_center_x - (w / 2)
            local y = center_screen_y - (h / 2)

            -- Card Drop Shadow
            love.graphics.setColor(c.shadow)
            love.graphics.rectangle("fill", x + 4, y + 10, w, h, r.card, r.card)

            -- Card Body
            if is_selected then
                love.graphics.setColor(c.card_active)
            else
                love.graphics.setColor(c.card)
            end
            love.graphics.rectangle("fill", x, y, w, h, r.card, r.card)

            -- Card Border & Glow
            if is_selected then
                love.graphics.setColor(c.accent)
                love.graphics.setLineWidth(2.5)
                love.graphics.rectangle("line", x, y, w, h, r.card, r.card)

                -- Top accent line
                love.graphics.rectangle("fill", x + 32, y + 2, w - 64, 4, r.dot, r.dot)
            else
                love.graphics.setColor(c.card_border)
                love.graphics.setLineWidth(1.0)
                love.graphics.rectangle("line", x, y, w, h, r.card, r.card)
            end

            -- Console Stage Artwork & Ambient Radial Glow
            local stage_center_y = y + 130 * scale
            if is_selected then
                love.graphics.setColor(56/255, 189/255, 248/255, 0.16)
                love.graphics.circle("fill", card_center_x, stage_center_y, 90 * scale)
            end

            local img = get_console_image(sys.id)
            if img then
                love.graphics.setColor(1, 1, 1, is_selected and 1.0 or 0.65)
                local iw, ih = img:getDimensions()
                local target_size = (is_selected and 180 or 150) * scale
                local img_scale = target_size / math.max(iw, ih)
                local img_x = card_center_x - (iw * img_scale / 2)
                local img_y = stage_center_y - (ih * img_scale / 2)
                love.graphics.draw(img, img_x, img_y, 0, img_scale, img_scale)
            else
                -- Fallback icon box
                local glyph_box_y = y + 36 * scale
                love.graphics.setColor(c.badge_bg)
                love.graphics.rectangle("fill", x + 30 * scale, glyph_box_y, w - 60 * scale, 160 * scale, r.sub, r.sub)

                if f.title then love.graphics.setFont(f.title) end
                love.graphics.setColor(is_selected and c.accent or c.text_sec)
                love.graphics.printf(sys.id, x, glyph_box_y + 60 * scale, w, "center")
            end

            -- System Name & Metadata
            local label_y = y + 250 * scale
            if f.header then love.graphics.setFont(f.header) end
            love.graphics.setColor(is_selected and c.text_pri or c.text_sec)
            love.graphics.printf(sys.label, x + 16, label_y, w - 32, "center")

            local meta_str = string.format("%s  -  %s", sys.manufacturer, sys.year)
            if f.sub then love.graphics.setFont(f.sub) end
            love.graphics.setColor(c.text_muted)
            love.graphics.printf(meta_str, x + 16, label_y + 36 * scale, w - 32, "center")

            -- Game Count Pill Badge
            local count_str = string.format("%d TITLES", #sys.games)
            local badge_w = 120 * scale
            local badge_h = 30 * scale
            local badge_x = card_center_x - (badge_w / 2)
            local badge_y = y + h - (50 * scale)

            love.graphics.setColor(is_selected and c.accent_dim or c.badge_bg)
            love.graphics.rectangle("fill", badge_x, badge_y, badge_w, badge_h, r.pill, r.pill)

            if is_selected then
                love.graphics.setColor(c.accent)
                love.graphics.setLineWidth(1.0)
                love.graphics.rectangle("line", badge_x, badge_y, badge_w, badge_h, r.pill, r.pill)
            end

            if f.tiny then love.graphics.setFont(f.tiny) end
            love.graphics.setColor(is_selected and c.accent or c.text_sec)
            love.graphics.printf(count_str, badge_x, badge_y + 7 * scale, badge_w, "center")
        end
    end
end

return carousel
