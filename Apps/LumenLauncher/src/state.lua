local state = {
    MODE_CAROUSEL = 1,
    MODE_GAME_LIST = 2,
    MODE_DISPATCH = 3,
    MODE_OPTIONS = 4,
    MODE_SEARCH = 5,

    mode = 1,
    prev_mode = 1,
    system_index = 1,
    game_indices = {}, -- system_index -> selected_game_index
    scroll_offsets = {},
    state_file = "/tmp/lumen_state.json"
}

function state.init(system_count)
    for i = 1, system_count do
        state.game_indices[i] = 1
        state.scroll_offsets[i] = 0
    end
    state.restore()
end

function state.save()
    local payload = string.format(
        "{\"system_index\":%d,\"mode\":%d}\n",
        state.system_index,
        state.mode
    )
    local f = io.open(state.state_file, "w")
    if f then
        f:write(payload)
        f:close()
    end
end

function state.restore()
    local f = io.open(state.state_file, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    if not content then return end

    local s_idx = content:match("\"system_index\":(%d+)")
    local s_mode = content:match("\"mode\":(%d+)")
    if s_idx then
        state.system_index = math.max(1, tonumber(s_idx))
    end
    if s_mode then
        state.mode = math.max(1, tonumber(s_mode))
    end
end

return state
