local mq        = require('mq')
local sha       = require('lib/sha2')
local logger    = require('utils/logger')

local path      = mq.luaDir .. "/../resources/MQ2Nav/"
---@class HashCheck
local hashCheck = {}

hashCheck.files = {
    ['dulak.navmesh']         = 'ecf63ad53a4eec334334363b9a6bbd3e',
    ['erudnext.navmesh']      = '8e9d29613098e2e4268ecc8f36b7e5e9',
    ['fieldofbone.navmesh']   = '46130be3719fea40a9e43ceb9115fd01',
    ['grobb.navmesh']         = 'c73153d69bf1bf56feab321980bca0b5',
    ['halas.navmesh']         = '56ba2b3658337fb6726dd561f35f89b9',
    ['soldungb.navmesh']      = '2ab3cf763d6718ab5fe7e13b1629c1e1',
    ['soldungc.navmesh']      = 'ddfecd111fd15f7b2699ad6ecc072462',
    ['lfaydark.navmesh']      = 'a53affe8b40a81b7e65821557d85e2eb',
    ['southro.navmesh']       = '30425a2ee40ad65653acc76377367580',
    ['mirb.navmesh']          = '4fb53688d08fb8220b0e5c694fe08c78',
    ['thurgadina.navmesh']    = 'c86a8d8c326d09c9c42432b3f23d30ed',
    ['mirc.navmesh']          = '0032510c31b0f92d91f1d1ec91f771a5',
    ['mischiefplane.navmesh'] = 'e16967b6d50300d815bd582f3292e839',
    ['mistythicket.navmesh']  = '1ee5e6c97d8a73939d4a91760c6e8003',
    ['necropolis.navmesh']    = '571c376a6e96b3440bb9524c42ae50ff',
    ['nedaria.navmesh']       = 'e2411c54e94c2e178ee80c900f7dbe82',
    ['poknowledge.navmesh']   = '64a2c1d0714f5d1299fa062d7da619dc',
    ['ponightmare.navmesh']   = '024df0b27cb607416adefe85ed32f6ae',
    ['postorms.navmesh']      = 'fd2f969bb6a22e755e61eb1a68cf1331',
    ['potactics.navmesh']     = '264c48953bfab2c4db7a6c54494a7766',
    ['potranquility.navmesh'] = '34945b4c41e7003c82e23f0ee61a49b4',
    ['qeynos2.navmesh']       = '5972d76bd59baf942b36c3762458f3f8',
    ['abysmal.navmesh']       = 'd3b6a609349cd25d7d746be1a5d0dfa5',
    ['veksar.navmesh']        = '813b078fa56e0dbe2e32a007aad9569c',
    ['causeway.navmesh']      = '385fb148406f5ceb33fb4b241039e719',
    ['iceclad.navmesh']       = 'd748c233b6cbef2308e34686b602244b',
    ['cazicthule.navmesh']    = 'edbfe9f99f2a61d28ba8b35c0d5565b5',
    ['letalis.navmesh']       = 'f3569840cb0f585f7055eeae96eaa426',
    ['charasis.navmesh']      = 'fef73b3b65b7c5dd0312c0c69ce992ad',
    ['riwwi.navmesh']         = 'ce99dbb70c8144caf16b9df210a06c4e',
    ['citymist.navmesh']      = '5bcf64ea0346f130ee8b5055e0140cc9',
    ['shadowhaven.navmesh']   = 'af10f271d7c08278ce4d891f9fedd8f5',
    ['crushbone.navmesh']     = '01d5f004cd1ab36d99ad0c896f41aab3',
    ['sirens.navmesh']        = '8ef779818b2ac82d6b93d56a375c540c',
}

-- Check the hash of mesh files against the stored hashes to determine if user is using the correct navmesh
-- Adds items to the badMeshes table if the hash does not match
-- This will be used to display the snitch tag in the log messages
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
