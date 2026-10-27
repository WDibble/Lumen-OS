local theme = require("src.theme")
local launch_view = {}

function launch_view.draw(payload)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    -- Fullscreen black backdrop
    love.graphics.setColor(0.02, 0.03, 0.04, 1.0)
    love.graphics.rectangle("fill", 0, 0, m.screen_w, m.screen_h)

    -- Centered Terminal Box
    local box_w = 760
    local box_h = 380
    local box_x = (m.screen_w - box_w) / 2
    local box_y = (m.screen_h - box_h) / 2

    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, r.card, r.card)
    love.graphics.setColor(c.card_border)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", box_x, box_y, box_w, box_h, r.card, r.card)

    -- Terminal Header Bar
    local head_h = 44
    love.graphics.setColor(c.card)
    love.graphics.rectangle("fill", box_x, box_y, box_w, head_h, r.card, r.card)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", box_x, box_y + head_h - 1, box_w, 1)

    -- Brand & Title
    if f.header then love.graphics.setFont(f.header) end
    love.graphics.setColor(c.accent)
    love.graphics.print("L U M E N", box_x + 20, box_y + 11)

    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_muted)
    love.graphics.print("POSIX DISPATCH TERMINAL", box_x + 150, box_y + 14)

    -- Terminal Output Lines
    local text_x = box_x + 24
    local line_y = box_y + 64

    local title_str = payload and payload.title or "Interactive Runtime"
    local target_str = payload and (payload.rom_path ~= "" and payload.rom_path or payload.target_script) or "/mnt/SDCARD/..."

    if f.body then love.graphics.setFont(f.body) end
    love.graphics.setColor(c.text_pri)
    love.graphics.print(string.format("Target: %s", title_str), text_x, line_y)

    line_y = line_y + 36
    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_muted)
    love.graphics.print("[System/scripts/launch.sh] Initializing hardware dispatcher...", text_x, line_y)

    line_y = line_y + 28
    love.graphics.setColor(c.badge_green)
    love.graphics.print("[next-hw] Setting CPU governor to performance (1608 MHz)", text_x, line_y)

    line_y = line_y + 28
    love.graphics.setColor(c.accent)
    love.graphics.print("[next-hw] Activating analog RGB LED ring sync (Cyan Pulse)", text_x, line_y)

    line_y = line_y + 28
    love.graphics.setColor(c.badge_green)
    love.graphics.print(string.format("[Kernel] Spawning runtime: %s", target_str), text_x, line_y)

    -- Bottom Banner Pill
    local banner_y = box_y + box_h - 60
    local banner_w = box_w - 48
    love.graphics.setColor(c.card_active)
    love.graphics.rectangle("fill", text_x, banner_y, banner_w, 40, r.pill, r.pill)
    love.graphics.setColor(c.accent)
    love.graphics.rectangle("line", text_x, banner_y, banner_w, 40, r.pill, r.pill)

    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_pri)
    love.graphics.printf("🎮 RUNTIME ACTIVE • Press [B] or [Esc] to return to Lumen OS", text_x, banner_y + 11, banner_w, "center")
end

return launch_view
