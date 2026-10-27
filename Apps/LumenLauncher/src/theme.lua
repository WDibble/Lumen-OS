local theme = {}

-- Normalized RGB/RGBA (0.0 to 1.0)
theme.colors = {
    bg           = {  9/255,  13/255,  20/255, 1.0 }, -- #090D14
    surface      = { 19/255,  27/255,  42/255, 1.0 }, -- #131B2A
    card         = { 22/255,  32/255,  50/255, 1.0 }, -- #162032
    card_border  = { 30/255,  40/255,  61/255, 1.0 }, -- #1E283D
    card_active  = { 38/255,  53/255,  80/255, 1.0 }, -- #263550
    accent       = { 56/255, 189/255, 248/255, 1.0 }, -- #38BDF8 (Lumen Cyan)
    accent_glow  = { 56/255, 189/255, 248/255, 0.22 },
    accent_dim   = { 20/255,  80/255, 110/255, 1.0 },
    text_pri     = { 248/255, 250/255, 252/255, 1.0 }, -- #F8FAFC
    text_sec     = { 148/255, 163/255, 184/255, 1.0 }, -- #94A3B8
    text_muted   = {  71/255,  85/255, 105/255, 1.0 }, -- #475569
    badge_bg     = {  30/255,  41/255,  59/255, 1.0 }, -- #1E293B
    badge_green  = {  34/255, 197/255,  94/255, 1.0 }, -- #22C55E
    badge_red    = { 239/255,  68/255,  68/255, 1.0 }, -- #EF4444
    badge_yellow = { 245/255, 158/255,  11/255, 1.0 }, -- #F59E0B
    shadow       = {   0,       0,       0,   0.45 },
}

-- Radii
theme.radii = {
    card = 16,
    sub  = 12,
    pill = 8,
    dot  = 4
}

-- Screen and Layout metrics
theme.metrics = {
    screen_w = 1280,
    screen_h = 720,
    status_h = 48,
    hint_h   = 48,
    stage_y  = 48,
    stage_h  = 624,

    -- Carousel view
    card_w   = 300,
    card_h   = 420,
    card_gap = 40,

    -- Two-pane view
    left_x   = 20,
    left_y   = 64,
    left_w   = 440,
    left_h   = 592,

    right_x  = 480,
    right_y  = 64,
    right_w  = 780,
    right_h  = 592,
    row_h    = 52
}

return theme
