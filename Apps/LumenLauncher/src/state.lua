local state = {
    TAB_CONSOLES = 1,
    TAB_APPS      = 2,
    TAB_FAVORITES = 3,
    TAB_SETTINGS  = 4,

    VIEW_CAROUSEL = "carousel",
    VIEW_GAMES    = "games",
    VIEW_SETTINGS = "settings",
    VIEW_LAUNCH   = "launch",

    current_tab = 1,
    active_view = "carousel",
    prev_view   = "carousel",

    carousel_indices   = { [1] = 1, [2] = 1, [3] = 1, [4] = 1 },
    game_indices       = {},
    settings_row_index = 1,
    active_accent      = "#38BDF8",

    launch_context = nil,
    state_file     = "/tmp/lumen_state.json"
}

function state.init(system_count)
    for i = 1, (system_count or 14) do
        state.game_indices[i] = 1
    end
    state.restore()
end

function state.set_tab(tab_idx)
    state.current_tab = math.max(1, math.min(4, tab_idx))
    if state.current_tab == state.TAB_SETTINGS then
        state.active_view = state.VIEW_SETTINGS
    else
        state.active_view = state.VIEW_CAROUSEL
    end
    state.save()
end

function state.cycle_tab(delta)
    local next_tab = ((state.current_tab - 1 + delta) % 4) + 1
    state.set_tab(next_tab)
end

function state.save()
    local payload = string.format(
        "{\"tab\":%d,\"view\":\"%s\",\"carousel_idx\":%d,\"settings_row\":%d,\"accent\":\"%s\"}\n",
        state.current_tab,
        state.active_view,
        state.carousel_indices[state.current_tab] or 1,
        state.settings_row_index,
        state.active_accent
    )
    local tmp_file = state.state_file .. ".tmp"
    local f = io.open(tmp_file, "w")
    if f then
        f:write(payload)
        f:close()
        os.rename(tmp_file, state.state_file)
    end
end

function state.restore()
    local f = io.open(state.state_file, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    if not content then return end

    local tab = content:match("\"tab\":(%d+)")
    local view = content:match("\"view\":\"([^\"]+)\"")
    local accent = content:match("\"accent\":\"([^\"]+)\"")
    local settings_row = content:match("\"settings_row\":(%d+)")

    if tab then
        local t = tonumber(tab)
        if t and t >= 1 and t <= 4 then
            state.current_tab = t
        end
    end
    if view and (view == "carousel" or view == "games" or view == "settings") then
        state.active_view = view
    end
    if accent and #accent > 0 then
        state.active_accent = accent
    end
    if settings_row then
        local sr = tonumber(settings_row)
        if sr and sr >= 1 then
            state.settings_row_index = sr
        end
    end
end

return state
