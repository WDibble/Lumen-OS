local theme      = require("src.theme")
local audio      = require("src.audio")
local input      = require("src.input")
local catalog    = require("src.catalog")
local state      = require("src.state")
local dispatcher = require("src.dispatcher")

local status_bar    = require("src.views.status_bar")
local tab_bar       = require("src.views.tab_bar")
local carousel      = require("src.views.carousel")
local two_pane      = require("src.views.two_pane")
local settings_view = require("src.views.settings_view")
local launch_view   = require("src.views.launch_view")
local hint_bar      = require("src.views.hint_bar")

local systems   = {}
local apps      = {}
local favorites = {}
local settings  = {}
local panic_error = nil

local function get_active_tab_items()
    if state.current_tab == state.TAB_CONSOLES then
        return systems
    elseif state.current_tab == state.TAB_APPS then
        return apps
    elseif state.current_tab == state.TAB_FAVORITES then
        return favorites
    elseif state.current_tab == state.TAB_SETTINGS then
        return settings
    end
    return systems
end

local function update_active_accent()
    if state.active_view == state.VIEW_CAROUSEL then
        local items = get_active_tab_items()
        local idx = state.carousel_indices[state.current_tab] or 1
        local item = items[idx]
        if item and item.color then
            theme.set_accent(item.color)
            state.active_accent = item.color
        end
    elseif state.active_view == state.VIEW_GAMES then
        local sys_idx = state.carousel_indices[state.TAB_CONSOLES] or 1
        local cur_sys = systems[sys_idx]
        if cur_sys and cur_sys.color then
            theme.set_accent(cur_sys.color)
            state.active_accent = cur_sys.color
        end
    elseif state.active_view == state.VIEW_SETTINGS then
        local accent_setting = settings[1]
        if accent_setting and accent_setting.values then
            local col = accent_setting.values[accent_setting.selected]
            if col then
                theme.set_accent(col)
                state.active_accent = col
            end
        end
    end
end

function love.load()
    audio.init()
    theme.init_fonts()
    input.init()

    systems   = catalog.load_systems()
    apps      = catalog.APPS
    favorites = catalog.FAVORITES
    settings  = catalog.SETTINGS

    state.init(#systems)
    theme.set_accent(state.active_accent)
    update_active_accent()
end

local function on_action(action)
    audio.play_click()

    -- 1. Global Tab Switching via L1 / R1 / Q / E / 1-4
    if action == "PREV_TAB" then
        state.cycle_tab(-1)
        update_active_accent()
        return
    elseif action == "NEXT_TAB" then
        state.cycle_tab(1)
        update_active_accent()
        return
    elseif action == "TAB_1" then
        state.set_tab(state.TAB_CONSOLES)
        update_active_accent()
        return
    elseif action == "TAB_2" then
        state.set_tab(state.TAB_APPS)
        update_active_accent()
        return
    elseif action == "TAB_3" then
        state.set_tab(state.TAB_FAVORITES)
        update_active_accent()
        return
    elseif action == "TAB_4" then
        state.set_tab(state.TAB_SETTINGS)
        update_active_accent()
        return
    end

    -- 2. View-specific Navigation & Action Handling
    if state.active_view == state.VIEW_CAROUSEL then
        local items = get_active_tab_items()
        local count = #items
        local cur_idx = state.carousel_indices[state.current_tab] or 1

        if action == "LEFT" then
            if count > 0 then
                cur_idx = cur_idx - 1
                if cur_idx < 1 then cur_idx = count end
                state.carousel_indices[state.current_tab] = cur_idx
                state.save()
                update_active_accent()
            end
        elseif action == "RIGHT" then
            if count > 0 then
                cur_idx = cur_idx + 1
                if cur_idx > count then cur_idx = 1 end
                state.carousel_indices[state.current_tab] = cur_idx
                state.save()
                update_active_accent()
            end
        elseif action == "CONFIRM" then
            if state.current_tab == state.TAB_CONSOLES then
                state.active_view = state.VIEW_GAMES
                state.save()
                update_active_accent()
            elseif state.current_tab == state.TAB_APPS and count > 0 then
                local app = items[cur_idx]
                local payload = dispatcher.prepare_payload("APP", app)
                state.launch_context = payload
                state.prev_view = state.VIEW_CAROUSEL
                state.active_view = state.VIEW_LAUNCH
                dispatcher.execute(payload)
            elseif state.current_tab == state.TAB_FAVORITES and count > 0 then
                local fav = items[cur_idx]
                local payload = dispatcher.prepare_payload("FAVORITE", fav)
                state.launch_context = payload
                state.prev_view = state.VIEW_CAROUSEL
                state.active_view = state.VIEW_LAUNCH
                dispatcher.execute(payload)
            end
        elseif action == "MENU" then
            state.set_tab(state.TAB_SETTINGS)
            update_active_accent()
        end

    elseif state.active_view == state.VIEW_GAMES then
        local sys_idx = state.carousel_indices[state.TAB_CONSOLES] or 1
        local cur_sys = systems[sys_idx]
        local g_idx = state.game_indices[sys_idx] or 1
        local total_games = cur_sys and #cur_sys.games or 0

        if action == "UP" then
            if g_idx > 1 then
                state.game_indices[sys_idx] = g_idx - 1
                state.save()
            end
        elseif action == "DOWN" then
            if g_idx < total_games then
                state.game_indices[sys_idx] = g_idx + 1
                state.save()
            end
        elseif action == "LEFT" then
            state.game_indices[sys_idx] = math.max(1, g_idx - 5)
            state.save()
        elseif action == "RIGHT" then
            state.game_indices[sys_idx] = math.min(total_games, g_idx + 5)
            state.save()
        elseif action == "BACK" then
            state.active_view = state.VIEW_CAROUSEL
            state.save()
            update_active_accent()
        elseif action == "CONFIRM" then
            if cur_sys and total_games > 0 then
                local selected_game = cur_sys.games[g_idx]
                local payload = dispatcher.prepare_payload("ROM", cur_sys, selected_game)
                state.launch_context = payload
                state.prev_view = state.VIEW_GAMES
                state.active_view = state.VIEW_LAUNCH
                dispatcher.execute(payload)
            end
        elseif action == "MENU" then
            state.set_tab(state.TAB_SETTINGS)
            update_active_accent()
        end

    elseif state.active_view == state.VIEW_SETTINGS then
        local total_s = #settings
        local cur_row = state.settings_row_index
        local item = settings[cur_row]

        if action == "UP" then
            if cur_row > 1 then
                state.settings_row_index = cur_row - 1
                state.save()
            end
        elseif action == "DOWN" then
            if cur_row < total_s then
                state.settings_row_index = cur_row + 1
                state.save()
            end
        elseif action == "LEFT" then
            if item then
                if item.clamped then
                    item.selected = math.max(1, item.selected - 1)
                else
                    item.selected = ((item.selected - 2 + #item.options) % #item.options) + 1
                end
                if item.id == "accent" then
                    theme.set_accent(item.values[item.selected])
                    state.active_accent = item.values[item.selected]
                end
            end
        elseif action == "RIGHT" or action == "CONFIRM" then
            if item then
                if item.clamped then
                    item.selected = math.min(#item.options, item.selected + 1)
                else
                    item.selected = (item.selected % #item.options) + 1
                end
                if item.id == "accent" then
                    theme.set_accent(item.values[item.selected])
                    state.active_accent = item.values[item.selected]
                end
            end
        elseif action == "BACK" then
            state.set_tab(state.TAB_CONSOLES)
            update_active_accent()
        end

    elseif state.active_view == state.VIEW_LAUNCH then
        if action == "BACK" or action == "CONFIRM" then
            state.active_view = state.prev_view or state.VIEW_CAROUSEL
            update_active_accent()
        end
    end
end

function love.update(dt)
    if panic_error then return end

    input.update(dt, on_action)

    if state.active_view == state.VIEW_CAROUSEL then
        local items = get_active_tab_items()
        local idx = state.carousel_indices[state.current_tab] or 1
        carousel.update(dt, idx, #items)
    elseif state.active_view == state.VIEW_GAMES then
        local sys_idx = state.carousel_indices[state.TAB_CONSOLES] or 1
        local cur_sys = systems[sys_idx]
        local g_idx = state.game_indices[sys_idx] or 1
        two_pane.update(dt, g_idx, cur_sys and #cur_sys.games or 0)
    elseif state.active_view == state.VIEW_SETTINGS then
        settings_view.update(dt, state.settings_row_index, #settings)
    end
end

function love.draw()
    if panic_error then
        love.graphics.clear(0.05, 0.05, 0.08)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.print("LUMEN LAUNCHER CRASH RECOVERY", 40, 40)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf(panic_error, 40, 80, 1200)
        return
    end

    local c = theme.colors
    love.graphics.clear(c.bg)

    local sys_idx = state.carousel_indices[state.TAB_CONSOLES] or 1
    local cur_sys = systems[sys_idx]

    if state.active_view == state.VIEW_CAROUSEL then
        local items = get_active_tab_items()
        local idx = state.carousel_indices[state.current_tab] or 1
        local tab_names = { "CONSOLES", "APPS", "FAVORITES", "SETTINGS" }

        carousel.draw(items, idx)
        tab_bar.draw(state.current_tab)
        status_bar.draw(tab_names[state.current_tab], nil)
        hint_bar.draw("carousel", idx, #items)

    elseif state.active_view == state.VIEW_GAMES then
        local g_idx = state.game_indices[sys_idx] or 1
        two_pane.draw(cur_sys, g_idx)
        status_bar.draw("CONSOLES", cur_sys and cur_sys.label)
        hint_bar.draw("games", g_idx, cur_sys and #cur_sys.games or 0)

    elseif state.active_view == state.VIEW_SETTINGS then
        settings_view.draw(settings, state.settings_row_index)
        status_bar.draw("SETTINGS", nil)
        hint_bar.draw("settings", state.settings_row_index, #settings)

    elseif state.active_view == state.VIEW_LAUNCH then
        launch_view.draw(state.launch_context)
        status_bar.draw("LAUNCHING", nil)
        hint_bar.draw("launch", 1, 1)
    end
end

function love.keypressed(key)
    input.keypressed(key, on_action)
end

function love.keyreleased(key)
    input.keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    input.gamepadpressed(joystick, button, on_action)
end

function love.gamepadreleased(joystick, button)
    input.gamepadreleased(joystick, button)
end

function love.joystickpressed(joystick, button)
    if joystick and joystick:isGamepad() then return end
    input.joystickpressed(joystick, button, on_action)
end

function love.joystickreleased(joystick, button)
    if joystick and joystick:isGamepad() then return end
    input.joystickreleased(joystick, button)
end

function love.joystickhat(joystick, hat, direction)
    if joystick and joystick:isGamepad() then return end
    input.joystickhat(joystick, hat, direction, on_action)
end

function love.joystickaxis(joystick, axis, value)
    if joystick and joystick:isGamepad() then return end
    input.joystickaxis(joystick, axis, value, on_action)
end

function love.gamepadaxis(joystick, axis, value)
    if axis == "leftx" then
        input.joystickaxis(joystick, 1, value, on_action)
    elseif axis == "lefty" then
        input.joystickaxis(joystick, 2, value, on_action)
    end
end

function love.errorhandler(msg)
    panic_error = tostring(msg) .. "\n" .. debug.traceback()
    print("FATAL ERROR: " .. panic_error)
    return function()
        love.event.pump()
        for e, a, b, c in love.event.poll() do
            if e == "quit" or e == "keypressed" or e == "gamepadpressed" then
                return 1
            end
        end
        love.draw()
        love.timer.sleep(0.016)
    end
end
