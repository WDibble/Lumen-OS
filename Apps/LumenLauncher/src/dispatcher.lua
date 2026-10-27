local dispatcher = {}

local EXEC_CFG = "/tmp/lumen_exec.cfg"

function dispatcher.is_handheld()
    local f = io.open("/mnt/SDCARD/System/bin/next-hw", "r")
    if f then
        f:close()
        return true
    end
    return false
end

function dispatcher.prepare_payload(target_type, entry, sub_entry)
    local payload = {
        title = "",
        target_script = "",
        rom_path = "",
        system_id = "",
        governor = "performance (1608 MHz)",
        led_mode = "Cyan Pulse"
    }

    if target_type == "ROM" then
        local system_def = entry
        local game_def = sub_entry
        payload.title = game_def.name
        payload.system_id = system_def.id
        payload.rom_path = game_def.path or ("/mnt/SDCARD/Roms/" .. system_def.id .. "/" .. game_def.file)
        payload.target_script = system_def.launch or ("/mnt/SDCARD/Emus/" .. system_def.id .. "/launch.sh")
    elseif target_type == "APP" then
        local app_def = entry
        payload.title = app_def.label or app_def.id
        payload.system_id = "APP"
        payload.rom_path = ""
        payload.target_script = app_def.launch or ("/mnt/SDCARD/Apps/" .. app_def.id .. "/launch.sh")
    elseif target_type == "FAVORITE" then
        local fav_def = entry
        payload.title = fav_def.name or fav_def.label
        payload.system_id = fav_def.system_id or "EMU"
        payload.rom_path = fav_def.path or ("/mnt/SDCARD/Roms/" .. (fav_def.system_id or "") .. "/" .. (fav_def.file or ""))
        payload.target_script = fav_def.launch or ("/mnt/SDCARD/Emus/" .. (fav_def.system_id or "") .. "/launch.sh")
    end

    return payload
end

function dispatcher.execute(payload)
    if not dispatcher.is_handheld() then
        -- Desktop testing mode: keep overlay active, do not quit
        return false
    end

    -- Write atomic execution configuration
    local tmp_file = EXEC_CFG .. ".tmp"
    local f = io.open(tmp_file, "w")
    if f then
        f:write(string.format("ROM=\"%s\"\n", payload.rom_path))
        f:write(string.format("TARGET=\"%s\"\n", payload.target_script))
        f:write(string.format("SYSTEM=\"%s\"\n", payload.system_id))
        f:write(string.format("NAME=\"%s\"\n", payload.title))
        f:close()
        os.rename(tmp_file, EXEC_CFG)
    end

    -- Exit code 10 signals launch.sh trampoline supervisor to run the target emulator
    love.event.quit(10)
    return true
end

function dispatcher.launch(system_def, game_def)
    local payload = dispatcher.prepare_payload("ROM", system_def, game_def)
    dispatcher.execute(payload)
end

return dispatcher
