local roms = {}

local FALLBACK_SYSTEMS = {
    {
        id = "GBA",
        label = "Game Boy Advance",
        manufacturer = "Nintendo",
        year = "2001",
        launch = "/mnt/SDCARD/Emus/GBA/launch.sh",
        extlist = { "gba", "zip", "7z" },
        games = {
            { name = "Castlevania - Aria of Sorrow", file = "Castlevania - Aria of Sorrow.gba" },
            { name = "Golden Sun - The Lost Age", file = "Golden Sun - The Lost Age.gba" },
            { name = "Metroid - Zero Mission", file = "Metroid - Zero Mission.gba" },
            { name = "Metroid Fusion", file = "Metroid Fusion.gba" },
            { name = "Pokemon Emerald Version", file = "Pokemon Emerald Version.gba" },
            { name = "The Legend of Zelda - The Minish Cap", file = "The Legend of Zelda - The Minish Cap.gba" }
        }
    },
    {
        id = "SNES",
        label = "Super Nintendo",
        manufacturer = "Nintendo",
        year = "1990",
        launch = "/mnt/SDCARD/Emus/SNES/launch.sh",
        extlist = { "sfc", "smc", "zip" },
        games = {
            { name = "Chrono Trigger", file = "Chrono Trigger.sfc" },
            { name = "Donkey Kong Country 2", file = "Donkey Kong Country 2.sfc" },
            { name = "Super Mario World", file = "Super Mario World.sfc" },
            { name = "Super Metroid", file = "Super Metroid.sfc" },
            { name = "The Legend of Zelda - A Link to the Past", file = "The Legend of Zelda - A Link to the Past.sfc" }
        }
    },
    {
        id = "PS",
        label = "Sony PlayStation",
        manufacturer = "Sony",
        year = "1994",
        launch = "/mnt/SDCARD/Emus/PS/launch.sh",
        extlist = { "chd", "pbp", "cue", "iso" },
        games = {
            { name = "Castlevania - Symphony of the Night", file = "Castlevania - Symphony of the Night.chd" },
            { name = "Final Fantasy VII", file = "Final Fantasy VII.chd" },
            { name = "Metal Gear Solid", file = "Metal Gear Solid.chd" },
            { name = "Ridge Racer Type 4", file = "Ridge Racer Type 4.chd" },
            { name = "Tekken 3", file = "Tekken 3.chd" }
        }
    },
    {
        id = "MD",
        label = "Sega Mega Drive",
        manufacturer = "Sega",
        year = "1988",
        launch = "/mnt/SDCARD/Emus/MD/launch.sh",
        extlist = { "bin", "gen", "md", "zip" },
        games = {
            { name = "Gunstar Heroes", file = "Gunstar Heroes.bin" },
            { name = "Sonic The Hedgehog 2", file = "Sonic The Hedgehog 2.bin" },
            { name = "Streets of Rage 2", file = "Streets of Rage 2.bin" }
        }
    },
    {
        id = "N64",
        label = "Nintendo 64",
        manufacturer = "Nintendo",
        year = "1996",
        launch = "/mnt/SDCARD/Emus/N64/launch.sh",
        extlist = { "z64", "n64", "v64" },
        games = {
            { name = "Super Mario 64", file = "Super Mario 64.z64" },
            { name = "The Legend of Zelda - Ocarina of Time", file = "The Legend of Zelda - Ocarina of Time.z64" }
        }
    },
    {
        id = "PSP",
        label = "PlayStation Portable",
        manufacturer = "Sony",
        year = "2004",
        launch = "/mnt/SDCARD/Emus/PSP/launch.sh",
        extlist = { "iso", "cso" },
        games = {
            { name = "Crisis Core - Final Fantasy VII", file = "Crisis Core.iso" },
            { name = "Persona 3 Portable", file = "Persona 3 Portable.iso" },
            { name = "WipEout Pulse", file = "WipEout Pulse.iso" }
        }
    }
}

local function strip_ext(filename)
    return filename:gsub("%.%w+$", "")
end

function roms.load_all()
    local systems = {}
    local emus_base = "/mnt/SDCARD/Emus"
    local roms_base = "/mnt/SDCARD/Roms"

    local has_sdcard = false
    local check_file = io.open(emus_base .. "/GBA/config.json", "r")
    if check_file then
        check_file:close()
        has_sdcard = true
    end

    if has_sdcard then
        -- Iterate through known system directories
        for _, sys_def in ipairs(FALLBACK_SYSTEMS) do
            local sys_id = sys_def.id
            local sys_rom_dir = roms_base .. "/" .. sys_id
            local detected_games = {}

            local pipe = io.popen("ls -1 \"" .. sys_rom_dir .. "\" 2>/dev/null")
            if pipe then
                for line in pipe:lines() do
                    local ext = line:match("%.(%w+)$")
                    if ext then
                        ext = ext:lower()
                        for _, valid_ext in ipairs(sys_def.extlist) do
                            if ext == valid_ext then
                                table.insert(detected_games, {
                                    name = strip_ext(line),
                                    file = line,
                                    path = sys_rom_dir .. "/" .. line
                                })
                                break
                            end
                        end
                    end
                end
                pipe:close()
            end

            local system_entry = {
                id = sys_id,
                label = sys_def.label,
                manufacturer = sys_def.manufacturer,
                year = sys_def.year,
                launch = sys_def.launch,
                extlist = sys_def.extlist,
                games = #detected_games > 0 and detected_games or sys_def.games
            }
            table.insert(systems, system_entry)
        end
    else
        -- Fallback to curated demo data for simulation
        for _, sys in ipairs(FALLBACK_SYSTEMS) do
            local sys_copy = {
                id = sys.id,
                label = sys.label,
                manufacturer = sys.manufacturer,
                year = sys.year,
                launch = sys.launch,
                extlist = sys.extlist,
                games = {}
            }
            for _, g in ipairs(sys.games) do
                table.insert(sys_copy.games, {
                    name = g.name,
                    file = g.file,
                    path = "/mnt/SDCARD/Roms/" .. sys.id .. "/" .. g.file
                })
            end
            table.insert(systems, sys_copy)
        end
    end

    return systems
end

return roms
