local theme = require("src.theme")
local options_modal = {
    selected_row = 1,
    settings = {
        {
            id = "brightness",
            label = "Screen Brightness",
            values = { "30%", "50%", "70%", "85%", "100%" },
            hw_vals = { "30", "50", "70", "85", "100" },
            current = 4
        },
        {
            id = "led",
            label = "Analog Stick LEDs",
            values = { "Cyan Breathe", "Solid Cyan", "Emerald Green", "Off" },
            hw_cmds = {
                "/mnt/SDCARD/System/bin/next-hw led --hex 38BDF8 --mode breathe 2>/dev/null &",
                "/mnt/SDCARD/System/bin/next-hw led --hex 38BDF8 2>/dev/null &",
                "/mnt/SDCARD/System/bin/next-hw led --hex 10B981 2>/dev/null &",
                "/mnt/SDCARD/System/bin/next-hw led --off 2>/dev/null &"
            },
            current = 1
        },
        {
            id = "cpu",
            label = "CPU Performance",
            values = { "Balanced (Ondemand)", "Turbo (1.6GHz)", "Battery Saver" },
            hw_cmds = {
                "/mnt/SDCARD/System/bin/next-hw cpu --profile normal 2>/dev/null &",
                "/mnt/SDCARD/System/bin/next-hw cpu --profile performance 2>/dev/null &",
                "/mnt/SDCARD/System/bin/next-hw cpu --profile powersave 2>/dev/null &"
            },
            current = 1
        },
        {
            id = "night",
            label = "Display Warmth",
            values = { "Neutral (6500K)", "Warm Night (5000K)" },
            hw_cmds = {
                "/mnt/SDCARD/System/bin/next-hw display --warmth 0 2>/dev/null &",
                "/mnt/SDCARD/System/bin/next-hw display --warmth 1 2>/dev/null &"
            },
            current = 1
        },
        {
            id = "mainui",
            label = "Stock MainUI Shell",
            values = { "Press A to Launch" },
            current = 1
        }
    }
}

function options_modal.apply(item_idx)
    local item = options_modal.settings[item_idx]
    if not item then return end

    if item.id == "brightness" then
        local val = item.hw_vals[item.current]
        os.execute(string.format("/mnt/SDCARD/System/bin/next-hw display --brightness %s 2>/dev/null &", val))
    elseif item.hw_cmds then
        local cmd = item.hw_cmds[item.current]
        if cmd then os.execute(cmd) end
    end
end

function options_modal.handle_action(action, on_close, on_switch_mainui)
    if action == "UP" then
        options_modal.selected_row = options_modal.selected_row - 1
        if options_modal.selected_row < 1 then
            options_modal.selected_row = #options_modal.settings
        end
    elseif action == "DOWN" then
        options_modal.selected_row = options_modal.selected_row + 1
        if options_modal.selected_row > #options_modal.settings then
            options_modal.selected_row = 1
        end
    elseif action == "LEFT" then
        local item = options_modal.settings[options_modal.selected_row]
        if item.values and #item.values > 1 then
            item.current = item.current - 1
            if item.current < 1 then item.current = #item.values end
            options_modal.apply(options_modal.selected_row)
        end
    elseif action == "RIGHT" then
        local item = options_modal.settings[options_modal.selected_row]
        if item.values and #item.values > 1 then
            item.current = item.current + 1
            if item.current > #item.values then item.current = 1 end
            options_modal.apply(options_modal.selected_row)
        end
    elseif action == "CONFIRM" then
        local item = options_modal.settings[options_modal.selected_row]
        if item.id == "mainui" and on_switch_mainui then
            on_switch_mainui()
        end
    elseif action == "BACK" or action == "MENU" then
        if on_close then on_close() end
    end
end

function options_modal.draw()
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    -- Dark backdrop tint
    love.graphics.setColor(0, 0, 0, 0.70)
    love.graphics.rectangle("fill", 0, 0, m.screen_w, m.screen_h)

    -- Modal Container (640 x 480)
    local mw, mh = 640, 490
    local mx = (m.screen_w - mw) / 2
    local my = (m.screen_h - mh) / 2

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", mx + 8, my + 12, mw, mh, r.card, r.card)

    -- Body
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", mx, my, mw, mh, r.card, r.card)

    love.graphics.setColor(c.accent)
    love.graphics.setLineWidth(2.0)
    love.graphics.rectangle("line", mx, my, mw, mh, r.card, r.card)

    -- Header bar
    love.graphics.setColor(c.accent)
    love.graphics.rectangle("fill", mx + 28, my + 26, 4, 22, r.dot, r.dot)

    if f.title then love.graphics.setFont(f.title) end
    love.graphics.setColor(c.text_pri)
    love.graphics.print("SYSTEM OPTIONS", mx + 42, my + 24)

    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_muted)
    love.graphics.print("TrimUI Smart Pro Hardware", mx + 42, my + 52)

    -- Divider
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", mx + 24, my + 80, mw - 48, 1)

    -- Rows
    local row_y = my + 94
    local row_h = 56

    for i, item in ipairs(options_modal.settings) do
        local is_sel = (i == options_modal.selected_row)
        local ry = row_y + (i - 1) * row_h

        if is_sel then
            love.graphics.setColor(c.card_active)
            love.graphics.rectangle("fill", mx + 20, ry, mw - 40, row_h - 6, r.sub, r.sub)

            love.graphics.setColor(c.accent)
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", mx + 20, ry, mw - 40, row_h - 6, r.sub, r.sub)

            love.graphics.rectangle("fill", mx + 20, ry + 6, 4, row_h - 18, r.dot, r.dot)
        else
            love.graphics.setColor(c.card)
            love.graphics.rectangle("fill", mx + 20, ry, mw - 40, row_h - 6, r.sub, r.sub)
        end

        -- Label
        if f.body then love.graphics.setFont(f.body) end
        love.graphics.setColor(is_sel and c.text_pri or c.text_sec)
        love.graphics.print(item.label, mx + 36, ry + 14)

        -- Value
        local val_str = item.values[item.current] or ""
        if #item.values > 1 then
            val_str = "<  " .. val_str .. "  >"
        end

        love.graphics.setColor(is_sel and c.accent or c.text_muted)
        love.graphics.printf(val_str, mx + mw - 320, ry + 14, 290, "right")
    end

    -- Bottom hint bar
    local hint_y = my + mh - 44
    love.graphics.setColor(c.card_border)
    love.graphics.rectangle("fill", mx + 24, hint_y - 12, mw - 48, 1)

    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(c.text_muted)
    love.graphics.printf("[D-PAD] NAVIGATE     [LEFT / RIGHT] ADJUST     [B] CLOSE", mx, hint_y, mw, "center")
end

return options_modal
