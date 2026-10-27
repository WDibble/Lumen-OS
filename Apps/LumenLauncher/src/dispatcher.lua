local dispatcher = {}

local EXEC_CFG = "/tmp/lumen_exec.cfg"

function dispatcher.launch(system_def, game_def)
    if not system_def or not game_def then return end

    local rom_path = game_def.path or ("/mnt/SDCARD/Roms/" .. system_def.id .. "/" .. game_def.file)
    local target_script = system_def.launch or ("/mnt/SDCARD/Emus/" .. system_def.id .. "/launch.sh")

    -- Write atomic execution configuration
    local f = io.open(EXEC_CFG .. ".tmp", "w")
    if f then
        f:write(string.format("ROM=\"%s\"\n", rom_path))
        f:write(string.format("TARGET=\"%s\"\n", target_script))
        f:write(string.format("SYSTEM=\"%s\"\n", system_def.id))
        f:write(string.format("NAME=\"%s\"\n", game_def.name))
        f:close()
        os.execute(string.format("mv \"%s.tmp\" \"%s\"", EXEC_CFG, EXEC_CFG))
    end

    -- Exit code 10 signals launch.sh trampoline supervisor to run the target emulator
    love.event.quit(10)
end

return dispatcher
