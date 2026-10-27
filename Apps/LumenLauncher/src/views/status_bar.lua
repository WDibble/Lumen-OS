local theme = require("src.theme")
local status_bar = {}

local function get_battery_info()
    local capacity = 100
    local f = io.open("/sys/class/power_supply/battery/capacity", "r")
    if f then
        local val = f:read("*l")
        f:close()
        if val then capacity = tonumber(val) or 100 end
    end
    return capacity
end

function status_bar.draw(breadcrumb_title, breadcrumb_sub)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    -- Status bar background
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", 0, 0, m.screen_w, m.status_h)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", 0, m.status_h - 1, m.screen_w, 1)

    -- Left Brand Mark: Vertical accent dot + LUMEN
    love.graphics.setColor(c.accent)
    love.graphics.rectangle("fill", 24, 12, 4, 24, r.dot, r.dot)

    if f.header then love.graphics.setFont(f.header) end
    love.graphics.setColor(c.accent)
    love.graphics.print("L U M E N", 38, 13)

    -- Hardware Chip Badge: TRIMUI PRO
    love.graphics.setColor(c.badge_bg)
    love.graphics.rectangle("fill", 154, 14, 110, 20, r.pill, r.pill)
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("line", 154, 14, 110, 20, r.pill, r.pill)
    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(c.text_sub)
    love.graphics.printf("TRIMUI PRO", 154, 17, 110, "center")

    -- Dynamic Breadcrumbs
    local bc_x = 280
    if breadcrumb_title then
        love.graphics.setColor(c.text_muted)
        love.graphics.print("›", bc_x, 16)
        love.graphics.setColor(c.accent)
        love.graphics.print(breadcrumb_title:upper(), bc_x + 16, 16)
        bc_x = bc_x + 16 + (f.sub and f.sub:getWidth(breadcrumb_title:upper()) or 100) + 8
    end

    if breadcrumb_sub then
        love.graphics.setColor(c.text_muted)
        love.graphics.print("›", bc_x, 16)
        love.graphics.setColor(c.text_pri)
        love.graphics.print(breadcrumb_sub:upper(), bc_x + 16, 16)
    end

    -- Right Status Indicators: Wi-Fi, Battery, Clock
    local rx = m.screen_w - 24
    local time_str = os.date("%H:%M")
    local battery_pct = get_battery_info()

    if f.body then love.graphics.setFont(f.body) end
    local clock_w = f.body and f.body:getWidth(time_str) or 48
    rx = rx - clock_w
    love.graphics.setColor(c.text_pri)
    love.graphics.print(time_str, rx, 14)

    -- Battery pill & icon
    local bat_str = string.format("%d%%", battery_pct)
    if f.sub then love.graphics.setFont(f.sub) end
    local bat_w = f.sub and f.sub:getWidth(bat_str) or 36
    rx = rx - bat_w - 28
    love.graphics.setColor(battery_pct <= 20 and c.badge_red or c.badge_green)
    love.graphics.rectangle("line", rx + bat_w + 8, 18, 16, 11, 2, 2)
    love.graphics.rectangle("fill", rx + bat_w + 10, 20, 12 * (battery_pct / 100), 7)
    love.graphics.setColor(c.text_sec)
    love.graphics.print(bat_str, rx, 16)

    -- Wi-Fi Pill
    rx = rx - 80
    love.graphics.setColor(c.badge_bg)
    love.graphics.rectangle("fill", rx, 14, 68, 20, r.pill, r.pill)
    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(c.accent)
    love.graphics.printf("ONLINE", rx, 17, 68, "center")
end

return status_bar
