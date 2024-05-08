local mq        = require('mq')
local sha       = require('lib/sha2')
local logger    = require('utils/logger')

local path      = mq.luaDir .. "/../resources/MQ2Nav/"
local hashCheck = {}

hashCheck.files = {
    ['mirb.navmesh']          = '4fb53688d08fb8220b0e5c694fe08c78', --
    ['soldungb.navmesh']      = '2ab3cf763d6718ab5fe7e13b1629c1e1', --
    ['abysmal.navmesh']       = 'd3b6a609349cd25d7d746be1a5d0dfa5', --
    ['causeway.navmesh']      = '3ff232d3e6ed128735f3036f5d680c37', -------GGGGGGGG
    ['cazicthule.navmesh']    = 'edbfe9f99f2a61d28ba8b35c0d5565b5', --
    ['charasis.navmesh']      = 'fef73b3b65b7c5dd0312c0c69ce992ad', --
    ['citymist.navmesh']      = '848fd9623a9f0dfb077ffb7507b4b350', ---------GGGGG
    ['crushbone.navmesh']     = 'c787789e4966e107e8b12618c08d0259', -------GGGGGGGGGGGG
    ['dulak.navmesh']         = 'ecf63ad53a4eec334334363b9a6bbd3e', --
    ['erudnext.navmesh']      = '8e9d29613098e2e4268ecc8f36b7e5e9', --
    ['fieldofbone.navmesh']   = '46130be3719fea40a9e43ceb9115fd01', --
    ['grobb.navmesh']         = 'c73153d69bf1bf56feab321980bca0b5', --
    ['halas.navmesh']         = '56ba2b3658337fb6726dd561f35f89b9', --
    ['iceclad.navmesh']       = 'd748c233b6cbef2308e34686b602244b', --
    ['lfaydark.navmesh']      = 'a53affe8b40a81b7e65821557d85e2eb', --
    ['mirc.navmesh']          = '0032510c31b0f92d91f1d1ec91f771a5', --
    ['mischiefplane.navmesh'] = 'ca05876740e4001fc42b2baa14de36cc', -------------------GGGGGGGGGGG
    ['necropolis.navmesh']    = '571c376a6e96b3440bb9524c42ae50ff', --
    ['nedaria.navmesh']       = '68836ddce190b396b2858713a02e2d14', ------------GGGG
    ['poknowledge.navmesh']   = '64a2c1d0714f5d1299fa062d7da619dc', --
    ['ponightmare.navmesh']   = '024df0b27cb607416adefe85ed32f6ae', --
    ['postorms.navmesh']      = 'fd2f969bb6a22e755e61eb1a68cf1331', --
    ['potranquility.navmesh'] = '34945b4c41e7003c82e23f0ee61a49b4', --
    ['qeynos2.navmesh']       = '95d1e8f09725cec7bb87a558faf113aa', ---------GGGGGGGGGGGG
    ['riwwi.navmesh']         = 'ce99dbb70c8144caf16b9df210a06c4e', --
    ['shadowhaven.navmesh']   = '396ad4a4602933c76f35a4659e03bd3b', -------GGGGGGGGG
    ['sirens.navmesh']        = '8ef779818b2ac82d6b93d56a375c540c', --
    ['soldungc.navmesh']      = 'ddfecd111fd15f7b2699ad6ecc072462', --
    ['southro.navmesh']       = '30425a2ee40ad65653acc76377367580', --
    ['veksar.navmesh']        = '4bac0c5169a8fb5a1d705d40aa0e6409'  --------------GGGGGGG
}

function hashCheck.check_meshes()
    for file, hash in pairs(hashCheck.files) do
        local fullPath = string.format("%s%s", path, file)
        local inp, err = io.open(fullPath, "rb")
        if inp then
            local data = inp:read("*all")
            inp:close()
            local result = sha.md5(data)
            if result ~= hash then
                local zone = string.gsub(file, ".navmesh", "")
                table.insert(_G.State.badMeshes, zone)
                --logger.log_info("\aoYour \ar%s \aomesh does not match the tested version. You may experience navigation issues in this zone.", file)
                --logger.log_info("\aoDownload the latest version from meshupdater.exe or from \arhttps://github.com/yb-f/meshes \aothank you.")
            end
        else
            logger.log_error("\aoError opening file: \ar%s\ao.", err)
        end
    end
end

hashCheck.check_meshes()

return hashCheck
