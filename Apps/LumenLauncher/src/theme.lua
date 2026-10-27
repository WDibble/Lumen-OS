local theme = {}

local hex_cache = {}

function theme.hex_to_color(hex, alpha)
    local key = hex .. "_" .. tostring(alpha or 1.0)
    if hex_cache[key] then return hex_cache[key] end

    local clean_hex = hex:gsub("#", "")
    local r = tonumber(clean_hex:sub(1, 2), 16) or 255
    local g = tonumber(clean_hex:sub(3, 4), 16) or 255
    local b = tonumber(clean_hex:sub(5, 6), 16) or 255
    local a = alpha or 1.0

    local col = { r / 255, g / 255, b / 255, a }
    hex_cache[key] = col
    return col
end

theme.colors = {
    bg           = theme.hex_to_color("#090D14"),
    surface      = theme.hex_to_color("#131B2A"),
    card         = theme.hex_to_color("#162032"),
    card_border  = theme.hex_to_color("#1E283D"),
    card_active  = theme.hex_to_color("#263550"),
    accent       = theme.hex_to_color("#38BDF8"),
    accent_glow  = theme.hex_to_color("#38BDF8", 0.22),
    accent_dim   = theme.hex_to_color("#14354D"),
    text_pri     = theme.hex_to_color("#F8FAFC"),
    text_sec     = theme.hex_to_color("#CBD5E1"),
    text_sub     = theme.hex_to_color("#B0BED0"),
    text_muted   = theme.hex_to_color("#94A3B8"),
    badge_bg     = theme.hex_to_color("#1E293B"),
    badge_green  = theme.hex_to_color("#22C55E"),
    badge_red    = theme.hex_to_color("#EF4444"),
    badge_yellow = theme.hex_to_color("#F59E0B"),
    shadow       = { 0, 0, 0, 0.45 },
}

function theme.set_accent(hex_code)
    theme.colors.accent = theme.hex_to_color(hex_code, 1.0)
    theme.colors.accent_glow = theme.hex_to_color(hex_code, 0.22)
    local clean = hex_code:gsub("#", "")
    local r = (tonumber(clean:sub(1, 2), 16) or 56) * 0.35 / 255
    local g = (tonumber(clean:sub(3, 4), 16) or 189) * 0.35 / 255
    local b = (tonumber(clean:sub(5, 6), 16) or 248) * 0.35 / 255
    theme.colors.accent_dim = { r, g, b, 1.0 }
end

theme.radii = {
    card = 16,
    sub  = 12,
    pill = 8,
    dot  = 4
}

theme.metrics = {
    screen_w = 1280,
    screen_h = 720,
    status_h = 48,
    tab_h    = 56,
    hint_h   = 48,
    stage_y  = 104,
    stage_h  = 568,

    -- Carousel metrics (Simulator 100% parity)
    card_w   = 300,
    card_h   = 410,
    card_gap = 32,
    card_pitch = 332,

    -- Two-pane metrics
    left_x   = 20,
    left_y   = 56,
    left_w   = 440,
    left_h   = 608,

    right_x  = 476,
    right_y  = 56,
    right_w  = 784,
    right_h  = 608,
    row_h    = 76
}

theme.fonts = {}

function theme.init_fonts()
    local font_path = "assets/font.ttf"
    local has_file = io.open(font_path, "r")
    if has_file then
        has_file:close()
        theme.fonts.title   = love.graphics.newFont(font_path, 24)
        theme.fonts.header  = love.graphics.newFont(font_path, 20)
        theme.fonts.body    = love.graphics.newFont(font_path, 16)
        theme.fonts.sub     = love.graphics.newFont(font_path, 14)
        theme.fonts.tiny    = love.graphics.newFont(font_path, 13)
    else
        theme.fonts.title   = love.graphics.newFont(24)
        theme.fonts.header  = love.graphics.newFont(20)
        theme.fonts.body    = love.graphics.newFont(16)
        theme.fonts.sub     = love.graphics.newFont(14)
        theme.fonts.tiny    = love.graphics.newFont(13)
    end
end

return theme
