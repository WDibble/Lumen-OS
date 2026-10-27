function love.conf(t)
    t.identity = "LumenLauncher"
    t.version = "11.5"
    t.console = false
    t.accelerometerjoystick = false

    t.window.title = "Lumen Launcher"
    t.window.icon = nil
    t.window.width = 1280
    t.window.height = 720
    t.window.borderless = true
    t.window.resizable = false
    t.window.minwidth = 1280
    t.window.minheight = 720
    t.window.fullscreen = true
    t.window.fullscreentype = "exclusive"
    t.window.vsync = 1
    t.window.msaa = 0
    t.window.depth = nil
    t.window.stencil = nil
    t.window.display = 1
    t.window.highdpi = false
    t.window.x = 0
    t.window.y = 0

    -- Prune unused modules for rapid <200ms cold boot and <35MB RAM footprint
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.filesystem = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
end
