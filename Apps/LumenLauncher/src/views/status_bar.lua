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

function status_bar.draw(current_system, in_game_list)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii

    -- Top bar background
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", 0, 0, m.screen_w, m.status_h)

    -- Bottom border accent line
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", 0, m.status_h - 1, m.screen_w, 1)

    -- Left Brand Mark: "|  L U M E N"
    love.graphics.setColor(c.accent)
    love.graphics.rectangle("fill", 20, 14, 4, 20, r.dot, r.dot)

    love.graphics.setColor(c.text_pri)
    love.graphics.print("L U M E N", 32, 16)

    -- Center Breadcrumbs
    love.graphics.setColor(c.text_muted)
    love.graphics.print("SYSTEMS", 180, 16)

    if in_game_list and current_system then
        love.graphics.setColor(c.accent)
        love.graphics.print(">", 256, 16)
        love.graphics.setColor(c.text_pri)
        love.graphics.print(current_system.label:upper(), 274, 16)
    end

    -- Right Status: Battery and Clock
    local time_str = os.date("%H:%M")
    local battery_pct = get_battery_info()
    local right_str = string.format("%d%%  |  %s", battery_pct, time_str)

    love.graphics.setColor(c.text_sec)
    love.graphics.printf(right_str, m.screen_w - 220, 16, 200, "right")
end

return status_bar
