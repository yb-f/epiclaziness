local mq        = require('mq')
local sha       = require 'lib/sha2'

local path      = mq.luaDir .. "/../resources/MQ2Nav/"
local hashCheck = {}
local hashFile  = mq.luaDir .. '/epiclaziness/lib/md5s.lua'

hashCheck.files = {
    "abysmal.navmesh",
    "cazicthule.navmesh",
    "charasis.navmesh",
    "citymist.navmesh",
    "dulak.navmesh",
    "erudnext.navmesh",
    "fieldofbone.navmesh",
    "grobb.navmesh",
    "halas.navmesh",
    "iceclad.navmesh",
    "lfaydark.navmesh",
    "mirc.navmesh",
    "necropolis.navmesh",
    "poknowledge.navmesh",
    "ponightmare.navmesh",
    "postorms.navmesh",
    "potranquility.navmesh",
    "riwwi.navmesh",
    "shadowhaven.navmesh",
    "sirens.navmesh",
    "soldungc.navmesh",
    "southro.navmesh",
    "mirb.navmesh",
    "soldungb.navmesh",
}

function hashCheck.load_stored_hashes()
    local configData, err = loadfile(hashFile)
    if err then
        Logger.log_error("\aoUnable to find hashes file.")
    elseif configData then
        hashCheck.hashes = configData()
    end
end

function hashCheck.check_meshes()
    for i, file in pairs(hashCheck.files) do
        local fullPath = string.format("%s%s", path, file)
        local inp = assert(io.open(fullPath, "rb"))
        local data = inp:read("*all")
        inp:close()
        local result = sha.md5(data)
        if hashCheck.hashes[file] ~= result then
            Logger.log_error("\aoYour \ar%s \aomesh does not match the tested version. You may experience navigation issues in this zone.", file)
            Logger.log_error("\aoDownload the latest version from meshupdater.exe or from \arhttps://github.com/yb-f/meshes \aothank you.")
        end
    end
end

hashCheck.load_stored_hashes()
hashCheck.check_meshes()

return hashCheck
