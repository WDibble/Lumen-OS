local theme      = require("src.theme")
local audio      = require("src.audio")
local input      = require("src.input")
local roms       = require("src.roms")
local state      = require("src.state")
local dispatcher = require("src.dispatcher")

local status_bar = require("src.views.status_bar")
local carousel   = require("src.views.carousel")
local two_pane   = require("src.views.two_pane")
local hint_bar   = require("src.views.hint_bar")

local systems = {}
local panic_error = nil

function love.load()
    audio.init()
    systems = roms.load_all()
    state.init(#systems)
end

local function on_action(action)
    audio.play_click()

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

    if state.mode == state.MODE_CAROUSEL then
        carousel.draw(systems, state.system_index)
        status_bar.draw(current_sys, false)
        hint_bar.draw(false, state.system_index, #systems)
    elseif state.mode == state.MODE_GAME_LIST then
        local g_idx = state.game_indices[state.system_index] or 1
        two_pane.draw(current_sys, g_idx)
        status_bar.draw(current_sys, true)
        hint_bar.draw(true, g_idx, current_sys and #current_sys.games or 0)
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

function love.joystickaxis(joystick, axis, value)
    input.joystickaxis(joystick, axis, value, on_action)
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
