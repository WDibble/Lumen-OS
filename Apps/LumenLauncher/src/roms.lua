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
    },
    {
        id = "NDS",
        label = "Nintendo DS",
        manufacturer = "Nintendo",
        year = "2004",
        launch = "/mnt/SDCARD/Emus/NDS/launch.sh",
        extlist = { "nds", "zip", "7z" },
        games = {
            { name = "Mario Kart DS", file = "Mario Kart DS.nds" },
            { name = "New Super Mario Bros", file = "New Super Mario Bros.nds" },
            { name = "Pokemon HeartGold", file = "Pokemon HeartGold.nds" },
            { name = "The World Ends With You", file = "The World Ends With You.nds" }
        }
    },
    {
        id = "DC",
        label = "Sega Dreamcast",
        manufacturer = "Sega",
        year = "1998",
        launch = "/mnt/SDCARD/Emus/DC/launch.sh",
        extlist = { "chd", "cdi", "gdi" },
        games = {
            { name = "Crazy Taxi", file = "Crazy Taxi.chd" },
            { name = "Jet Set Radio", file = "Jet Set Radio.chd" },
            { name = "Shenmue", file = "Shenmue.chd" },
            { name = "Sonic Adventure 2", file = "Sonic Adventure 2.chd" }
        }
    },
    {
        id = "PCE",
        label = "PC Engine / TG-16",
        manufacturer = "NEC",
        year = "1987",
        launch = "/mnt/SDCARD/Emus/PCE/launch.sh",
        extlist = { "pce", "chd", "cue" },
        games = {
            { name = "Castlevania - Rondo of Blood", file = "Castlevania - Rondo of Blood.chd" },
            { name = "Bonk's Adventure", file = "Bonk's Adventure.pce" },
            { name = "Blazing Lazers", file = "Blazing Lazers.pce" }
        }
    },
    {
        id = "NEOGEO",
        label = "SNK Neo Geo",
        manufacturer = "SNK",
        year = "1990",
        launch = "/mnt/SDCARD/Emus/NEOGEO/launch.sh",
        extlist = { "zip", "7z" },
        games = {
            { name = "Metal Slug 3", file = "mslug3.zip" },
            { name = "Garou - Mark of the Wolves", file = "garou.zip" },
            { name = "The King of Fighters 98", file = "kof98.zip" }
        }
    },
    {
        id = "FC",
        label = "NES / Famicom",
        manufacturer = "Nintendo",
        year = "1983",
        launch = "/mnt/SDCARD/Emus/FC/launch.sh",
        extlist = { "nes", "zip" },
        games = {
            { name = "Super Mario Bros. 3", file = "Super Mario Bros 3.nes" },
            { name = "Mega Man 2", file = "Mega Man 2.nes" },
            { name = "Castlevania III - Dracula's Curse", file = "Castlevania III.nes" },
            { name = "Metroid", file = "Metroid.nes" }
        }
    },
    {
        id = "GB",
        label = "Game Boy",
        manufacturer = "Nintendo",
        year = "1989",
        launch = "/mnt/SDCARD/Emus/GB/launch.sh",
        extlist = { "gb", "zip" },
        games = {
            { name = "Pokemon Red Version", file = "Pokemon Red.gb" },
            { name = "The Legend of Zelda - Link's Awakening", file = "Links Awakening.gb" },
            { name = "Tetris", file = "Tetris.gb" },
            { name = "Super Mario Land 2 - 6 Golden Coins", file = "Super Mario Land 2.gb" }
        }
    },
    {
        id = "GBC",
        label = "Game Boy Color",
        manufacturer = "Nintendo",
        year = "1998",
        launch = "/mnt/SDCARD/Emus/GBC/launch.sh",
        extlist = { "gbc", "zip" },
        games = {
            { name = "Pokemon Crystal Version", file = "Pokemon Crystal.gbc" },
            { name = "The Legend of Zelda - Oracle of Ages", file = "Oracle of Ages.gbc" },
            { name = "The Legend of Zelda - Oracle of Seasons", file = "Oracle of Seasons.gbc" },
            { name = "Shantae", file = "Shantae.gbc" }
        }
    },
    {
        id = "FBNEO",
        label = "FinalBurn Arcade",
        manufacturer = "Capcom / SNK",
        year = "ARCADE",
        launch = "/mnt/SDCARD/Emus/FBNEO/launch.sh",
        extlist = { "zip", "7z" },
        games = {
            { name = "Street Fighter III 3rd Strike", file = "sfiii3.zip" },
            { name = "Marvel vs. Capcom", file = "mvsc.zip" },
            { name = "Alien vs. Predator", file = "avsp.zip" }
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
