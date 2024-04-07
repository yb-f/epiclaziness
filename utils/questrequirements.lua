local mq = require('mq')

local elheader = "\ay[\agEpic Laziness\ay]"

local quests_requirements = {
    ['brd'] = {
        ['10'] = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes.',
        ['15'] =
        'Requires the assistance of an enchanter for 8x enchanted velium bars, and brown diamond of earth, cloudy diamond of air, red diamond of fire, aqua diamond of water, yellow diamond of valor, gray diamond of storms, green diamond of disease, and white diamond of justice.',
        ['20'] = 'Requires Dark Orb from Bard 1.5 Epic.  Requires manually obtaining a Globe of Discordant Energy.'
    },
    ['bst'] = {
        ['10'] = '',
        ['pre15'] = 'Requires tailoring 100 and brewing 122.',
        ['15'] = 'Requires tailoring 100.',
        ['20'] =
        'Requires baking 100, blacksmithing 100, pottery 100. Also requires manually obtaining a Globe of Discordant Energy.'
    },
    ['clr'] = {
        ['10'] = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes.',
        ['15'] = 'Requires brewing 100 (120+ recomended).',
        ['20'] = 'Requires manually obtaining a Globe of Discordant Energy.'
    },
    ['rog'] = {
        ['10'] = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes.',
        ['15'] = '',
        ['20'] = ''
    },
    ['shd'] = {
        ['10'] = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes.',
        ['15'] = 'Requires tailoring 100.',
        ['20'] = 'Requires manually obtaining a Globe of Discordant Energy.'
    },
    ['shm'] = {
        ['10'] = 'Requires a lockpicker for several steps in City of Mist',
        ['pre15'] = '',
        ['15'] = 'Requires alchemy 100.',
        ['20'] = 'Requires manually obtaining a Globe of Discordant Energy.'
    },
}

return quests_requirements