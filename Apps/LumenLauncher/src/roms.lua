local catalog = require("src.catalog")
local roms = {}

function roms.load_all()
    return catalog.load_systems()
end

return roms
