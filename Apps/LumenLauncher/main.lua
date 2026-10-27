local theme      = require("src.theme")
local audio      = require("src.audio")
local input      = require("src.input")
local roms       = require("src.roms")
local state      = require("src.state")
local dispatcher = require("src.dispatcher")

local status_bar    = require("src.views.status_bar")
local carousel      = require("src.views.carousel")
local two_pane      = require("src.views.two_pane")
local hint_bar      = require("src.views.hint_bar")
local options_modal = require("src.views.options_modal")
local search_modal  = require("src.views.search_modal")

local systems = {}
local panic_error = nil
local last_action = "NONE"
local last_event = "NONE"

function love.load()
    audio.init()
    theme.init_fonts()
    input.init()
    systems = roms.load_all()
    state.init(#systems)
end

local function on_action(action)
    last_action = action
    audio.play_click()

    -- 1. Modals have top-level focus
    if state.mode == state.MODE_OPTIONS then
        options_modal.handle_action(
            action,
            function()
                state.mode = state.prev_mode or state.MODE_CAROUSEL
                state.save()
            end,
            function()
                love.event.quit(0)
                os.execute("killall -9 love.aarch64 2>/dev/null; /usr/trimui/bin/MainUI &")
            end
        )
        return
    elseif state.mode == state.MODE_SEARCH then
        local current_sys = systems[state.system_index]
        search_modal.handle_action(
            action,
            function(letter)
                if state.prev_mode == state.MODE_CAROUSEL then
                    if letter == "ALL" then
                        state.system_index = 1
                    else
                        for idx, s in ipairs(systems) do
                            if s.label:upper():sub(1,1) == letter or s.id:upper():sub(1,1) == letter then
                                state.system_index = idx
                                break
                            end
                        end
                    end
                elseif state.prev_mode == state.MODE_GAME_LIST and current_sys then
                    if letter == "ALL" then
                        state.game_indices[state.system_index] = 1
                    else
                        for g_idx, g in ipairs(current_sys.games) do
                            if g.name:upper():sub(1,1) == letter then
                                state.game_indices[state.system_index] = g_idx
                                break
                            end
                        end
                    end
                end
                state.mode = state.prev_mode or state.MODE_CAROUSEL
                state.save()
            end,
            function()
                state.mode = state.prev_mode or state.MODE_CAROUSEL
                state.save()
            end
        )
        return
    end

    -- Global modal shortcuts
    if action == "MENU" then
        state.prev_mode = state.mode
        state.mode = state.MODE_OPTIONS
        state.save()
        return
    elseif action == "SECONDARY" then
        state.prev_mode = state.mode
        state.mode = state.MODE_SEARCH
        state.save()
        return
    end

    -- 2. Base View Navigation
    if state.mode == state.MODE_CAROUSEL then
        if action == "LEFT" then
            state.system_index = state.system_index - 1
            if state.system_index < 1 then state.system_index = #systems end
            state.save()
        elseif action == "RIGHT" then
            state.system_index = state.system_index + 1
            if state.system_index > #systems then state.system_index = 1 end
            state.save()
        elseif action == "CONFIRM" then
            state.mode = state.MODE_GAME_LIST
            state.save()
        end
    elseif state.mode == state.MODE_GAME_LIST then
        local current_sys = systems[state.system_index]
        local current_game_idx = state.game_indices[state.system_index] or 1
        local total_games = current_sys and #current_sys.games or 0

        if action == "UP" then
            if current_game_idx > 1 then
                state.game_indices[state.system_index] = current_game_idx - 1
                state.save()
            end
        elseif action == "DOWN" then
            if current_game_idx < total_games then
                state.game_indices[state.system_index] = current_game_idx + 1
                state.save()
            end
        elseif action == "BACK" then
            state.mode = state.MODE_CAROUSEL
            state.save()
        elseif action == "CONFIRM" then
            if current_sys and total_games > 0 then
                local selected_game = current_sys.games[current_game_idx]
                dispatcher.launch(current_sys, selected_game)
            end
        end
    end
end

function love.update(dt)
    if panic_error then return end

    input.update(dt, on_action)

    if state.mode == state.MODE_CAROUSEL then
        carousel.update(dt, state.system_index, #systems)
    elseif state.mode == state.MODE_GAME_LIST then
        local current_sys = systems[state.system_index]
        local g_idx = state.game_indices[state.system_index] or 1
        two_pane.update(dt, g_idx, current_sys and #current_sys.games or 0)
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

    local current_sys = systems[state.system_index]

    if state.mode == state.MODE_CAROUSEL or state.mode == state.MODE_OPTIONS or state.mode == state.MODE_SEARCH then
        carousel.draw(systems, state.system_index)
        status_bar.draw(current_sys, false)
        hint_bar.draw(false, state.system_index, #systems)
    elseif state.mode == state.MODE_GAME_LIST then
        local g_idx = state.game_indices[state.system_index] or 1
        two_pane.draw(current_sys, g_idx)
        status_bar.draw(current_sys, true)
        hint_bar.draw(true, g_idx, current_sys and #current_sys.games or 0)
    end

    -- Overlay Modals
    if state.mode == state.MODE_OPTIONS then
        options_modal.draw()
    elseif state.mode == state.MODE_SEARCH then
        local scope_name = (state.prev_mode == state.MODE_GAME_LIST and current_sys) and current_sys.label or "Consoles"
        local match_count = 0
        local sel_let = search_modal.letters[search_modal.current_index]
        if state.prev_mode == state.MODE_GAME_LIST and current_sys then
            for _, g in ipairs(current_sys.games) do
                if sel_let == "ALL" or g.name:upper():sub(1,1) == sel_let then
                    match_count = match_count + 1
                end
            end
        else
            for _, s in ipairs(systems) do
                if sel_let == "ALL" or s.label:upper():sub(1,1) == sel_let or s.id:upper():sub(1,1) == sel_let then
                    match_count = match_count + 1
                end
            end
        end
        search_modal.draw(scope_name, match_count)
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
