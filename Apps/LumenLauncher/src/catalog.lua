local catalog = {}

-- 14 Core Systems with signature branding and color tokens from the simulator
catalog.SYSTEMS = {
    {
        id = "GBA",
        label = "Game Boy Advance",
        maker = "Nintendo",
        year = "2001",
        color = "#38BDF8",
        launch = "/mnt/SDCARD/Emus/GBA/launch.sh",
        extlist = { "gba", "zip", "7z" },
        games = {
            { name = "Castlevania - Aria of Sorrow", file = "Castlevania - Aria of Sorrow.gba", genre = "Action RPG", year = "2003" },
            { name = "Golden Sun - The Lost Age", file = "Golden Sun - The Lost Age.gba", genre = "RPG", year = "2002" },
            { name = "Metroid - Zero Mission", file = "Metroid - Zero Mission.gba", genre = "Action Adventure", year = "2004" },
            { name = "Metroid Fusion", file = "Metroid Fusion.gba", genre = "Action Adventure", year = "2002" },
            { name = "Pokemon Emerald Version", file = "Pokemon Emerald Version.gba", genre = "RPG", year = "2004" },
            { name = "The Legend of Zelda - The Minish Cap", file = "The Legend of Zelda - The Minish Cap.gba", genre = "Action Adventure", year = "2004" }
        }
    },
    {
        id = "SFC",
        label = "Super Nintendo",
        maker = "Nintendo",
        year = "1990",
        color = "#818CF8",
        launch = "/mnt/SDCARD/Emus/SFC/launch.sh",
        extlist = { "sfc", "smc", "zip" },
        games = {
            { name = "Chrono Trigger", file = "Chrono Trigger.sfc", genre = "RPG", year = "1995" },
            { name = "Donkey Kong Country 2", file = "Donkey Kong Country 2.sfc", genre = "Platformer", year = "1995" },
            { name = "Super Mario World", file = "Super Mario World.sfc", genre = "Platformer", year = "1990" },
            { name = "Super Metroid", file = "Super Metroid.sfc", genre = "Action", year = "1994" },
            { name = "The Legend of Zelda - A Link to the Past", file = "The Legend of Zelda - A Link to the Past.sfc", genre = "Adventure", year = "1991" }
        }
    },
    {
        id = "PS",
        label = "Sony PlayStation",
        maker = "Sony",
        year = "1994",
        color = "#60A5FA",
        launch = "/mnt/SDCARD/Emus/PS/launch.sh",
        extlist = { "chd", "pbp", "cue", "iso" },
        games = {
            { name = "Castlevania - Symphony of the Night", file = "Castlevania - Symphony of the Night.chd", genre = "Action RPG", year = "1997" },
            { name = "Final Fantasy VII", file = "Final Fantasy VII.chd", genre = "RPG", year = "1997" },
            { name = "Metal Gear Solid", file = "Metal Gear Solid.chd", genre = "Stealth Action", year = "1998" },
            { name = "Ridge Racer Type 4", file = "Ridge Racer Type 4.chd", genre = "Racing", year = "1998" },
            { name = "Tekken 3", file = "Tekken 3.chd", genre = "Fighting", year = "1998" }
        }
    },
    {
        id = "PSP",
        label = "PlayStation Portable",
        maker = "Sony",
        year = "2004",
        color = "#A855F7",
        launch = "/mnt/SDCARD/Emus/PSP/launch.sh",
        extlist = { "iso", "cso" },
        games = {
            { name = "Crisis Core - Final Fantasy VII", file = "Crisis Core.iso", genre = "Action RPG", year = "2007" },
            { name = "Persona 3 Portable", file = "Persona 3 Portable.iso", genre = "RPG", year = "2009" },
            { name = "WipEout Pulse", file = "WipEout Pulse.iso", genre = "Futuristic Racing", year = "2007" }
        }
    },
    {
        id = "N64",
        label = "Nintendo 64",
        maker = "Nintendo",
        year = "1996",
        color = "#10B981",
        launch = "/mnt/SDCARD/Emus/N64/launch.sh",
        extlist = { "z64", "n64", "v64" },
        games = {
            { name = "Super Mario 64", file = "Super Mario 64.z64", genre = "3D Platformer", year = "1996" },
            { name = "The Legend of Zelda - Ocarina of Time", file = "The Legend of Zelda - Ocarina of Time.z64", genre = "Action Adventure", year = "1998" }
        }
    },
    {
        id = "NDS",
        label = "Nintendo DS",
        maker = "Nintendo",
        year = "2004",
        color = "#F59E0B",
        launch = "/mnt/SDCARD/Emus/NDS/launch.sh",
        extlist = { "nds", "zip", "7z" },
        games = {
            { name = "Mario Kart DS", file = "Mario Kart DS.nds", genre = "Racing", year = "2005" },
            { name = "New Super Mario Bros", file = "New Super Mario Bros.nds", genre = "Platformer", year = "2006" },
            { name = "Pokemon HeartGold", file = "Pokemon HeartGold.nds", genre = "RPG", year = "2009" },
            { name = "The World Ends With You", file = "The World Ends With You.nds", genre = "Action RPG", year = "2007" }
        }
    },
    {
        id = "DC",
        label = "Sega Dreamcast",
        maker = "Sega",
        year = "1998",
        color = "#F97316",
        launch = "/mnt/SDCARD/Emus/DC/launch.sh",
        extlist = { "chd", "cdi", "gdi" },
        games = {
            { name = "Crazy Taxi", file = "Crazy Taxi.chd", genre = "Arcade Driving", year = "1999" },
            { name = "Jet Set Radio", file = "Jet Set Radio.chd", genre = "Action Skating", year = "2000" },
            { name = "Shenmue", file = "Shenmue.chd", genre = "Adventure RPG", year = "1999" },
            { name = "Sonic Adventure 2", file = "Sonic Adventure 2.chd", genre = "3D Platformer", year = "2001" }
        }
    },
    {
        id = "MD",
        label = "Sega Mega Drive",
        maker = "Sega",
        year = "1988",
        color = "#EAB308",
        launch = "/mnt/SDCARD/Emus/MD/launch.sh",
        extlist = { "bin", "gen", "md", "zip" },
        games = {
            { name = "Gunstar Heroes", file = "Gunstar Heroes.bin", genre = "Run and Gun", year = "1993" },
            { name = "Sonic The Hedgehog 2", file = "Sonic The Hedgehog 2.bin", genre = "Platformer", year = "1992" },
            { name = "Streets of Rage 2", file = "Streets of Rage 2.bin", genre = "Beat 'em Up", year = "1992" }
        }
    },
    {
        id = "PCE",
        label = "PC Engine / TG-16",
        maker = "NEC",
        year = "1987",
        color = "#EC4899",
        launch = "/mnt/SDCARD/Emus/PCE/launch.sh",
        extlist = { "pce", "chd", "cue" },
        games = {
            { name = "Castlevania - Rondo of Blood", file = "Castlevania - Rondo of Blood.chd", genre = "Action", year = "1993" },
            { name = "Bonk's Adventure", file = "Bonk's Adventure.pce", genre = "Platformer", year = "1989" },
            { name = "Blazing Lazers", file = "Blazing Lazers.pce", genre = "Shoot 'em Up", year = "1989" }
        }
    },
    {
        id = "NEOGEO",
        label = "SNK Neo Geo",
        maker = "SNK",
        year = "1990",
        color = "#EF4444",
        launch = "/mnt/SDCARD/Emus/NEOGEO/launch.sh",
        extlist = { "zip", "7z" },
        games = {
            { name = "Metal Slug 3", file = "mslug3.zip", genre = "Run and Gun", year = "2000" },
            { name = "Garou - Mark of the Wolves", file = "garou.zip", genre = "Fighting", year = "1999" },
            { name = "The King of Fighters 98", file = "kof98.zip", genre = "Fighting", year = "1998" }
        }
    },
    {
        id = "FC",
        label = "NES / Famicom",
        maker = "Nintendo",
        year = "1983",
        color = "#F43F5E",
        launch = "/mnt/SDCARD/Emus/FC/launch.sh",
        extlist = { "nes", "zip" },
        games = {
            { name = "Super Mario Bros. 3", file = "Super Mario Bros 3.nes", genre = "Platformer", year = "1988" },
            { name = "Mega Man 2", file = "Mega Man 2.nes", genre = "Action Platformer", year = "1988" },
            { name = "Castlevania III - Dracula's Curse", file = "Castlevania III.nes", genre = "Action", year = "1989" },
            { name = "Metroid", file = "Metroid.nes", genre = "Action Adventure", year = "1986" }
        }
    },
    {
        id = "GB",
        label = "Game Boy",
        maker = "Nintendo",
        year = "1989",
        color = "#14B8A6",
        launch = "/mnt/SDCARD/Emus/GB/launch.sh",
        extlist = { "gb", "zip" },
        games = {
            { name = "Pokemon Red Version", file = "Pokemon Red.gb", genre = "RPG", year = "1996" },
            { name = "The Legend of Zelda - Link's Awakening", file = "Links Awakening.gb", genre = "Action Adventure", year = "1993" },
            { name = "Tetris", file = "Tetris.gb", genre = "Puzzle", year = "1989" },
            { name = "Super Mario Land 2 - 6 Golden Coins", file = "Super Mario Land 2.gb", genre = "Platformer", year = "1992" }
        }
    },
    {
        id = "GBC",
        label = "Game Boy Color",
        maker = "Nintendo",
        year = "1998",
        color = "#8B5CF6",
        launch = "/mnt/SDCARD/Emus/GBC/launch.sh",
        extlist = { "gbc", "zip" },
        games = {
            { name = "Pokemon Crystal Version", file = "Pokemon Crystal.gbc", genre = "RPG", year = "2000" },
            { name = "The Legend of Zelda - Oracle of Ages", file = "Oracle of Ages.gbc", genre = "Action Adventure", year = "2001" },
            { name = "The Legend of Zelda - Oracle of Seasons", file = "Oracle of Seasons.gbc", genre = "Action Adventure", year = "2001" },
            { name = "Shantae", file = "Shantae.gbc", genre = "Platformer", year = "2002" }
        }
    },
    {
        id = "FBNEO",
        label = "FinalBurn Arcade",
        maker = "Capcom / SNK",
        year = "ARCADE",
        color = "#06B6D4",
        launch = "/mnt/SDCARD/Emus/FBNEO/launch.sh",
        extlist = { "zip", "7z" },
        games = {
            { name = "Street Fighter III 3rd Strike", file = "sfiii3.zip", genre = "Fighting", year = "1999" },
            { name = "Marvel vs. Capcom", file = "mvsc.zip", genre = "Fighting", year = "1998" },
            { name = "Alien vs. Predator", file = "avsp.zip", genre = "Beat 'em Up", year = "1994" }
        }
    }
}

-- 9 Native System Apps
catalog.APPS = {
    {
        id = "BIOSDoctor",
        label = "BIOS Doctor",
        desc = "Integrity & MD5 BIOS verification",
        category = "Diagnostic",
        maker = "Lumen OS",
        year = "Utility",
        color = "#38BDF8",
        launch = "/mnt/SDCARD/Apps/BIOSDoctor/launch.sh"
    },
    {
        id = "Search",
        label = "ROM Search",
        desc = "Global fast fuzzy title finder",
        category = "Search Utility",
        maker = "Lumen OS",
        year = "Utility",
        color = "#818CF8",
        launch = "/mnt/SDCARD/Apps/Search/launch.sh"
    },
    {
        id = "SystemTools",
        label = "System Tools",
        desc = "Maintenance & SD partition tools",
        category = "Administration",
        maker = "Lumen OS",
        year = "Utility",
        color = "#10B981",
        launch = "/mnt/SDCARD/Apps/SystemTools/launch.sh"
    },
    {
        id = "PortMaster",
        label = "PortMaster",
        desc = "Native PC and indie game ports",
        category = "Game Launcher",
        maker = "Community",
        year = "Ports",
        color = "#F97316",
        launch = "/mnt/SDCARD/Apps/PortMaster/launch.sh"
    },
    {
        id = "RetroArch",
        label = "RetroArch",
        desc = "Full libretro settings & core manager",
        category = "Configuration",
        maker = "Libretro",
        year = "Core",
        color = "#60A5FA",
        launch = "/mnt/SDCARD/RetroArch/launch.sh"
    },
    {
        id = "FileManager",
        label = "File Manager",
        desc = "DinguxCommander dual-pane browser",
        category = "Browser",
        maker = "Dingux",
        year = "Utility",
        color = "#A855F7",
        launch = "/mnt/SDCARD/Apps/FileManager/launch.sh"
    },
    {
        id = "Terminal",
        label = "Terminal",
        desc = "Direct root ash shell console",
        category = "Shell",
        maker = "Linux",
        year = "Console",
        color = "#22C55E",
        launch = "/mnt/SDCARD/Apps/Terminal/launch.sh"
    },
    {
        id = "MusicPlayer",
        label = "Music Player",
        desc = "GMu multi-format audio player",
        category = "Media",
        maker = "GMu",
        year = "Audio",
        color = "#EC4899",
        launch = "/mnt/SDCARD/Apps/MusicPlayer/launch.sh"
    },
    {
        id = "USBStorage",
        label = "USB Storage",
        desc = "Expose microSD card over Type-C",
        category = "Hardware",
        maker = "Lumen OS",
        year = "Utility",
        color = "#EAB308",
        launch = "/mnt/SDCARD/Apps/USBStorage/launch.sh"
    }
}

-- 6 Curated Favorites
catalog.FAVORITES = {
    {
        id = "GBA",
        name = "Pokemon Emerald Version",
        label = "Pokemon Emerald Version",
        system_id = "GBA",
        system_label = "Game Boy Advance",
        file = "Pokemon Emerald Version.gba",
        genre = "RPG",
        year = "2004",
        maker = "Nintendo",
        desc = "Game Boy Advance • 2004",
        color = "#38BDF8",
        launch = "/mnt/SDCARD/Emus/GBA/launch.sh"
    },
    {
        id = "SFC",
        name = "Chrono Trigger",
        label = "Chrono Trigger",
        system_id = "SFC",
        system_label = "Super Nintendo",
        file = "Chrono Trigger.sfc",
        genre = "RPG",
        year = "1995",
        maker = "Squaresoft",
        desc = "Super Nintendo • 1995",
        color = "#818CF8",
        launch = "/mnt/SDCARD/Emus/SFC/launch.sh"
    },
    {
        id = "PS",
        name = "Castlevania - Symphony of the Night",
        label = "Castlevania - Symphony of the Night",
        system_id = "PS",
        system_label = "Sony PlayStation",
        file = "Castlevania - Symphony of the Night.chd",
        genre = "Action RPG",
        year = "1997",
        maker = "Konami",
        desc = "Sony PlayStation • 1997",
        color = "#60A5FA",
        launch = "/mnt/SDCARD/Emus/PS/launch.sh"
    },
    {
        id = "N64",
        name = "Super Mario 64",
        label = "Super Mario 64",
        system_id = "N64",
        system_label = "Nintendo 64",
        file = "Super Mario 64.z64",
        genre = "3D Platformer",
        year = "1996",
        maker = "Nintendo",
        desc = "Nintendo 64 • 1996",
        color = "#10B981",
        launch = "/mnt/SDCARD/Emus/N64/launch.sh"
    },
    {
        id = "PSP",
        name = "Persona 3 Portable",
        label = "Persona 3 Portable",
        system_id = "PSP",
        system_label = "PlayStation Portable",
        file = "Persona 3 Portable.iso",
        genre = "RPG",
        year = "2009",
        maker = "Atlus",
        desc = "PlayStation Portable • 2009",
        color = "#A855F7",
        launch = "/mnt/SDCARD/Emus/PSP/launch.sh"
    },
    {
        id = "DC",
        name = "Crazy Taxi",
        label = "Crazy Taxi",
        system_id = "DC",
        system_label = "Sega Dreamcast",
        file = "Crazy Taxi.chd",
        genre = "Arcade Driving",
        year = "1999",
        maker = "Sega",
        desc = "Sega Dreamcast • 1999",
        color = "#F97316",
        launch = "/mnt/SDCARD/Emus/DC/launch.sh"
    }
}

-- 9 Settings with Steppers and Strict Value Clamps
catalog.SETTINGS = {
    {
        id = "accent",
        name = "Accent Palette",
        desc = "Interactive highlight & badge color",
        options = { "Lumen Cyan", "Emerald Pulse", "Cyberpunk Violet", "Solar Amber", "Ruby Red" },
        values = { "#38BDF8", "#10B981", "#A855F7", "#F59E0B", "#EF4444" },
        selected = 1
    },
    {
        id = "brightness",
        name = "IPS Backlight PWM",
        desc = "Display luminance clamped to prevent panel blackout",
        options = { "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%" },
        values = { 20, 30, 40, 50, 60, 70, 80, 90, 100 },
        selected = 7,
        clamped = true
    },
    {
        id = "led_mode",
        name = "RGB Analog LED Rings",
        desc = "Dual analog stick RGB ring illumination profile",
        options = { "Breathing Pulse", "Static Solid", "Battery Sentinel", "Disabled" },
        values = { "breathe", "solid", "battery", "off" },
        selected = 1
    },
    {
        id = "cpu_gov",
        name = "CPU Scaling Governor",
        desc = "Allwinner cpufreq dynamic clock stepping policy",
        options = { "Ondemand (816-1608MHz)", "Performance (1608MHz)", "Powersave (408MHz)" },
        values = { "ondemand", "performance", "powersave" },
        selected = 1
    },
    {
        id = "refresh",
        name = "Display Refresh Timing",
        desc = "1280x720 IPS panel controller sync",
        options = { "60Hz Native IPS", "50Hz PAL Mode" },
        values = { 60, 50 },
        selected = 1
    },
    {
        id = "nand_protect",
        name = "NAND Flash Sentinel",
        desc = "Bind-mount /mnt/SDCARD/System/userdata",
        options = { "Active (Zero Wear)", "Direct Mount" },
        values = { 1, 0 },
        selected = 1
    },
    {
        id = "ssh_daemon",
        name = "Dropbear SSH Server",
        desc = "Port 22 root access on wlan0",
        options = { "Enabled (Port 22)", "Disabled" },
        values = { 1, 0 },
        selected = 1
    },
    {
        id = "fn_mode",
        name = "Hardware FN Switch Action",
        desc = "Physical top slider switch behavior",
        options = { "Turbo Performance (1.6GHz)", "Mute Audio", "LED Off" },
        values = { "turbo", "mute", "led_off" },
        selected = 1
    },
    {
        id = "syncthing",
        name = "Syncthing Cloud Saves",
        desc = "Headless background Wi-Fi sync for saves & states",
        options = { "Disabled (Save Battery)", "Enabled (Port 8384)" },
        values = { 0, 1 },
        selected = 1
    }
}

function catalog.load_systems()
    local emus_base = "/mnt/SDCARD/Emus"
    local roms_base = "/mnt/SDCARD/Roms"
    local has_sdcard = false

    local check_file = io.open(emus_base .. "/GBA/config.json", "r")
    if check_file then
        check_file:close()
        has_sdcard = true
    end

    if has_sdcard then
        local systems = {}
        for _, sys_def in ipairs(catalog.SYSTEMS) do
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
                                local clean_name = line:gsub("%.%w+$", "")
                                table.insert(detected_games, {
                                    name = clean_name,
                                    file = line,
                                    path = sys_rom_dir .. "/" .. line,
                                    genre = "ROM",
                                    year = sys_def.year
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
                maker = sys_def.maker,
                manufacturer = sys_def.maker,
                year = sys_def.year,
                color = sys_def.color,
                launch = sys_def.launch,
                extlist = sys_def.extlist,
                games = #detected_games > 0 and detected_games or sys_def.games
            }
            table.insert(systems, system_entry)
        end
        return systems
    else
        -- Desktop Simulator fallback with full catalog
        local systems = {}
        for _, sys in ipairs(catalog.SYSTEMS) do
            local sys_copy = {
                id = sys.id,
                label = sys.label,
                maker = sys.maker,
                manufacturer = sys.maker,
                year = sys.year,
                color = sys.color,
                launch = sys.launch,
                extlist = sys.extlist,
                games = {}
            }
            for _, g in ipairs(sys.games) do
                table.insert(sys_copy.games, {
                    name = g.name,
                    file = g.file,
                    genre = g.genre or "ROM",
                    year = g.year or sys.year,
                    path = "/mnt/SDCARD/Roms/" .. sys.id .. "/" .. g.file
                })
            end
            table.insert(systems, sys_copy)
        end
        return systems
    end
end

return catalog
