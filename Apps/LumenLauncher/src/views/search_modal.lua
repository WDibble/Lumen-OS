local theme = require("src.theme")
local search_modal = {
    letters = { "ALL", "#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" },
    current_index = 1
}

function search_modal.handle_action(action, on_jump, on_close)
    if action == "LEFT" then
        search_modal.current_index = search_modal.current_index - 1
        if search_modal.current_index < 1 then
            search_modal.current_index = #search_modal.letters
        end
    elseif action == "RIGHT" then
        search_modal.current_index = search_modal.current_index + 1
        if search_modal.current_index > #search_modal.letters then
            search_modal.current_index = 1
        end
    elseif action == "CONFIRM" then
        local chosen_letter = search_modal.letters[search_modal.current_index]
        if on_jump then on_jump(chosen_letter) end
    elseif action == "BACK" or action == "SECONDARY" then
        if on_close then on_close() end
    end
end

function search_modal.draw(current_target_name, match_count)
    local m = theme.metrics
    local c = theme.colors
    local r = theme.radii
    local f = theme.fonts

    -- Dimmed background
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, m.screen_w, m.screen_h)

    -- Container
    local mw, mh = 760, 240
    local mx = (m.screen_w - mw) / 2
    local my = (m.screen_h - mh) / 2

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", mx + 8, my + 10, mw, mh, r.card, r.card)

    -- Surface
    love.graphics.setColor(c.surface)
    love.graphics.rectangle("fill", mx, my, mw, mh, r.card, r.card)

    love.graphics.setColor(c.accent)
    love.graphics.setLineWidth(2.0)
    love.graphics.rectangle("line", mx, my, mw, mh, r.card, r.card)

    -- Title
    love.graphics.setColor(c.accent)
    love.graphics.rectangle("fill", mx + 28, my + 22, 4, 20, r.dot, r.dot)

    if f.title then love.graphics.setFont(f.title) end
    love.graphics.setColor(c.text_pri)
    love.graphics.print("QUICK JUMP & SEARCH", mx + 42, my + 20)

    if f.sub then love.graphics.setFont(f.sub) end
    love.graphics.setColor(c.text_muted)
    local scope_str = current_target_name and ("Browsing: " .. current_target_name) or "All Library Titles"
    love.graphics.print(scope_str, mx + 42, my + 48)

    -- Alphabet Ribbon
    local ribbon_y = my + 90
    local letter_w = 48
    local letter_h = 44
    local sel_letter = search_modal.letters[search_modal.current_index]

    -- Draw visible letters window centered around current_index
    local center_ribbon_x = mx + (mw / 2)
    for offset = -6, 6 do
        local idx = search_modal.current_index + offset
        if idx >= 1 and idx <= #search_modal.letters then
            local lx = center_ribbon_x + (offset * (letter_w + 6)) - (letter_w / 2)
            local is_curr = (offset == 0)

            if is_curr then
                love.graphics.setColor(c.card_active)
                love.graphics.rectangle("fill", lx, ribbon_y, letter_w, letter_h, r.pill, r.pill)

                love.graphics.setColor(c.accent)
                love.graphics.setLineWidth(1.5)
                love.graphics.rectangle("line", lx, ribbon_y, letter_w, letter_h, r.pill, r.pill)

                if f.header then love.graphics.setFont(f.header) end
                love.graphics.printf(search_modal.letters[idx], lx, ribbon_y + 8, letter_w, "center")
            else
                love.graphics.setColor(c.card)
                love.graphics.rectangle("fill", lx, ribbon_y, letter_w, letter_h, r.pill, r.pill)

                if f.body then love.graphics.setFont(f.body) end
                love.graphics.setColor(c.text_muted)
                love.graphics.printf(search_modal.letters[idx], lx, ribbon_y + 11, letter_w, "center")
            end
        end
    end

    -- Match preview & Footer
    local footer_y = my + mh - 42
    if f.sub then love.graphics.setFont(f.sub) end
    local info_str = string.format("Filter: [ %s ]   Matching: %s titles", sel_letter, tostring(match_count or 0))
    love.graphics.setColor(c.accent)
    love.graphics.printf(info_str, mx, my + 154, mw, "center")

    if f.tiny then love.graphics.setFont(f.tiny) end
    love.graphics.setColor(c.text_muted)
    love.graphics.printf("[LEFT / RIGHT] SELECT LETTER     [A] JUMP     [B] CANCEL", mx, footer_y, mw, "center")
end

return search_modal
