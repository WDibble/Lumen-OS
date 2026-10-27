local theme = require("src.theme")
local carousel = {
    current_x = 0,
    target_x  = 0,
    speed     = 14.0
}

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

    local center_screen_x = m.screen_w / 2
    local center_screen_y = m.stage_y + (m.stage_h / 2)
    local card_pitch = m.card_w + m.card_gap

    for i, sys in ipairs(systems) do
        local card_center_x = center_screen_x + carousel.current_x + ((i - 1) * card_pitch)

        -- Cull cards completely outside visible horizontal bounds
        if card_center_x > -200 and card_center_x < m.screen_w + 200 then
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
            love.graphics.rectangle("fill", x + 4, y + 8, w, h, r.card, r.card)

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
                love.graphics.rectangle("fill", x + 24, y + 2, w - 48, 3, r.dot, r.dot)
            else
                love.graphics.setColor(c.card_border)
                love.graphics.setLineWidth(1.0)
                love.graphics.rectangle("line", x, y, w, h, r.card, r.card)
            end

            -- System Icon Glyph / Hero Badge
            local glyph_box_y = y + 36 * scale
            love.graphics.setColor(c.badge_bg)
            love.graphics.rectangle("fill", x + 30 * scale, glyph_box_y, w - 60 * scale, 160 * scale, r.sub, r.sub)

            love.graphics.setColor(is_selected and c.accent or c.text_sec)
            love.graphics.printf(sys.id, x, glyph_box_y + 60 * scale, w, "center")

            -- System Name & Metadata
            local label_y = y + 220 * scale
            love.graphics.setColor(is_selected and c.text_pri or c.text_sec)
            love.graphics.printf(sys.label, x + 20, label_y, w - 40, "center")

            local meta_str = string.format("%s  -  %s", sys.manufacturer, sys.year)
            love.graphics.setColor(c.text_muted)
            love.graphics.printf(meta_str, x + 20, label_y + 36 * scale, w - 40, "center")

            -- Game Count Pill Badge
            local count_str = string.format("%d TITLES", #sys.games)
            local badge_w = 110 * scale
            local badge_h = 28 * scale
            local badge_x = card_center_x - (badge_w / 2)
            local badge_y = y + h - (46 * scale)

            love.graphics.setColor(is_selected and c.accent_dim or c.badge_bg)
            love.graphics.rectangle("fill", badge_x, badge_y, badge_w, badge_h, r.pill, r.pill)

            love.graphics.setColor(is_selected and c.accent or c.text_sec)
            love.graphics.printf(count_str, badge_x, badge_y + 6 * scale, badge_w, "center")
        end
    end
end

return carousel
