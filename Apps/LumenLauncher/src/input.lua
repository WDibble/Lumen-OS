local input = {
    repeat_delay = 0.35,
    repeat_rate  = 0.08,
    active_dir   = nil,
    timer        = 0,
    deadzone     = 0.38
}

local KEY_MAP = {
    left       = "LEFT",
    right      = "RIGHT",
    up         = "UP",
    down       = "DOWN",
    return_key = "CONFIRM",
    space      = "CONFIRM",
    escape     = "BACK",
    backspace  = "BACK",
    x          = "SECONDARY",
    y          = "MENU",
    tab        = "SELECT",
    lshift     = "L1",
    rshift     = "R1"
}

local BUTTON_MAP = {
    dpleft        = "LEFT",
    dpright       = "RIGHT",
    dpup          = "UP",
    dpdown        = "DOWN",
    a             = "CONFIRM",
    b             = "BACK",
    x             = "SECONDARY",
    y             = "MENU",
    leftshoulder  = "L1",
    rightshoulder = "R1",
    start         = "START",
    back          = "SELECT"
}

function input.update(dt, on_action)
    if not input.active_dir then return end

    input.timer = input.timer + dt
    if input.timer >= input.repeat_delay then
        on_action(input.active_dir)
        input.timer = input.repeat_delay - input.repeat_rate
    end
end

function input.handle_press(action, on_action)
    if not action then return end

    if action == "LEFT" or action == "RIGHT" or action == "UP" or action == "DOWN" then
        input.active_dir = action
        input.timer = 0
    end
    on_action(action)
end

function input.handle_release(action)
    if action == input.active_dir then
        input.active_dir = nil
        input.timer = 0
    end
end

function input.keypressed(key, on_action)
    local mapped = KEY_MAP[key]
    if key == "return" then mapped = "CONFIRM" end
    if mapped then
        input.handle_press(mapped, on_action)
    end
end

function input.keyreleased(key)
    local mapped = KEY_MAP[key]
    if key == "return" then mapped = "CONFIRM" end
    if mapped then
        input.handle_release(mapped)
    end
end

function input.gamepadpressed(joystick, button, on_action)
    local mapped = BUTTON_MAP[button]
    if mapped then
        input.handle_press(mapped, on_action)
    end
end

function input.gamepadreleased(joystick, button)
    local mapped = BUTTON_MAP[button]
    if mapped then
        input.handle_release(mapped)
    end
end

function input.joystickaxis(joystick, axis, value, on_action)
    if axis == 1 then -- Left Stick X
        if value < -input.deadzone then
            if input.active_dir ~= "LEFT" then input.handle_press("LEFT", on_action) end
        elseif value > input.deadzone then
            if input.active_dir ~= "RIGHT" then input.handle_press("RIGHT", on_action) end
        else
            if input.active_dir == "LEFT" or input.active_dir == "RIGHT" then
                input.handle_release(input.active_dir)
            end
        end
    elseif axis == 2 then -- Left Stick Y
        if value < -input.deadzone then
            if input.active_dir ~= "UP" then input.handle_press("UP", on_action) end
        elseif value > input.deadzone then
            if input.active_dir ~= "DOWN" then input.handle_press("DOWN", on_action) end
        else
            if input.active_dir == "UP" or input.active_dir == "DOWN" then
                input.handle_release(input.active_dir)
            end
        end
    end
end

return input
