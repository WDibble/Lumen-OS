local input = {
    repeat_delay = 0.45,
    repeat_rate  = 0.14,
    active_dir   = nil,
    timer        = 0,
    deadzone     = 0.45,
    axis_latched_x = false,
    axis_latched_y = false
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

-- TrimUI Nintendo layout: Physical A is right (b), Physical B is bottom (a), Physical X is top (y), Physical Y is left (x)
local BUTTON_MAP = {
    dpleft        = "LEFT",
    dpright       = "RIGHT",
    dpup          = "UP",
    dpdown        = "DOWN",
    a             = "BACK",       -- Physical B (bottom)
    b             = "CONFIRM",    -- Physical A (right)
    x             = "MENU",       -- Physical Y (left)
    y             = "SECONDARY",  -- Physical X (top)
    leftshoulder  = "L1",
    rightshoulder = "R1",
    start         = "START",
    back          = "SELECT",
    guide         = "MENU"
}

-- Raw joystick fallback map for handhelds when SDL gamepad is not auto-assigned
local RAW_BUTTON_MAP = {
    [1]  = "BACK",      -- Physical B
    [2]  = "CONFIRM",   -- Physical A
    [3]  = "MENU",      -- Physical Y
    [4]  = "SECONDARY", -- Physical X
    [5]  = "L1",
    [6]  = "R1",
    [7]  = "SELECT",
    [8]  = "START",
    [9]  = "MENU",
    [11] = "UP",
    [12] = "DOWN",
    [13] = "LEFT",
    [14] = "RIGHT"
}

local HAT_MAP = {
    u = "UP",
    d = "DOWN",
    l = "LEFT",
    r = "RIGHT"
}

function input.init()
    pcall(function()
        love.joystick.setGamepadMapping(
            "030003f05e0400008e02000014010000",
            "TRIMUI Player1",
            "a:b0,b:b1,x:b2,y:b3,back:b6,start:b7,guide:b8,leftshoulder:b4,rightshoulder:b5,leftstick:b9,rightstick:b10,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux"
        )
    end)
end

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

function input.joystickpressed(joystick, button, on_action)
    -- Only handle raw joystick if not already handled as gamepad
    if joystick and joystick:isGamepad() then return end
    local mapped = RAW_BUTTON_MAP[button]
    if mapped then
        input.handle_press(mapped, on_action)
    end
end

function input.joystickreleased(joystick, button)
    if joystick and joystick:isGamepad() then return end
    local mapped = RAW_BUTTON_MAP[button]
    if mapped then
        input.handle_release(mapped)
    end
end

function input.joystickhat(joystick, hat, direction, on_action)
    if joystick and joystick:isGamepad() then return end
    local mapped = HAT_MAP[direction]
    if mapped then
        input.handle_press(mapped, on_action)
    elseif direction == "c" then
        if input.active_dir then
            input.handle_release(input.active_dir)
        end
    end
end

function input.joystickaxis(joystick, axis, value, on_action)
    if axis == 1 then -- Left Stick X
        if value < -input.deadzone then
            if not input.axis_latched_x then
                input.axis_latched_x = true
                input.handle_press("LEFT", on_action)
            end
        elseif value > input.deadzone then
            if not input.axis_latched_x then
                input.axis_latched_x = true
                input.handle_press("RIGHT", on_action)
            end
        elseif math.abs(value) < 0.22 then
            if input.axis_latched_x then
                input.axis_latched_x = false
                if input.active_dir == "LEFT" or input.active_dir == "RIGHT" then
                    input.handle_release(input.active_dir)
                end
            end
        end
    elseif axis == 2 then -- Left Stick Y
        if value < -input.deadzone then
            if not input.axis_latched_y then
                input.axis_latched_y = true
                input.handle_press("UP", on_action)
            end
        elseif value > input.deadzone then
            if not input.axis_latched_y then
                input.axis_latched_y = true
                input.handle_press("DOWN", on_action)
            end
        elseif math.abs(value) < 0.22 then
            if input.axis_latched_y then
                input.axis_latched_y = false
                if input.active_dir == "UP" or input.active_dir == "DOWN" then
                    input.handle_release(input.active_dir)
                end
            end
        end
    end
end

return input
