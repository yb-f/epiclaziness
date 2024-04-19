local mq                  = require('mq')

local quests_requirements = {
    ['brd'] = {
        ['10']    = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes.',
        ['15']    =
        'Requires the assistance of an enchanter for 8x enchanted velium bars, and brown diamond of earth, cloudy diamond of air, red diamond of fire, aqua diamond of water, yellow diamond of valor, gray diamond of storms, green diamond of disease, and white diamond of justice.',
        ['20']    = 'Requires Dark Orb from Bard 1.5 Epic.  Requires manually obtaining a Globe of Discordant Energy.'
    },
    ['bst'] = {
        ['10']    = '',
        ['pre15'] = 'Requires tailoring 100 and brewing 122.',
        ['15']    = 'Requires tailoring 100.',
        ['20']    =
        'Requires baking 100, blacksmithing 100, pottery 100. Also requires manually obtaining a Globe of Discordant Energy.'
    },
    ['ber'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
    ['clr'] = {
        ['10']    = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes.',
        ['15']    = 'Requires brewing 100 (120+ recomended).',
        ['20']    = 'Requires manually obtaining a Globe of Discordant Energy.'
    },
    ['dru'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
    ['enc'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
    ['mag'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
    ['mnk'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
    ['nec'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
    ['pal'] = {
        ['10']    = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes. You are required to be in a guild in order to use the guildhall portal to Plane of Hate.',
        ['15']    = '100 Fishing required.  Shaman with 224 Alchemy required for Mist of the Breathless.',
        ['20']    = ''
    },
    ['rng'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
    ['rog'] = {
        ['10']    = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes.',
        ['15']    =
        'Requires baking 192, tailoring 82, blacksmithing 104, jewelry making 12, make poison 277, and brewing 121. Please make sure your food and drink are in your topmost slots so as to not eat or drink items for this quest.',
        ['20']    = ''
    },
    ['shd'] = {
        ['10']    = '',
        ['pre15'] = 'No tradeskill or requirements for assistance from other classes. You are required to be in a guild in order to use the guildhall portal to Plane of Hate.',
        ['15']    = 'Requires tailoring 100.',
        ['20']    = 'Requires manually obtaining a Globe of Discordant Energy.'
    },
    ['shm'] = {
        ['10']    =
        'Requires a lockpicker for several steps in City of Mist. Group with your lockpicker and select their name in the 2nd dropdown box. (They must be in the same zone.)',
        ['pre15'] = '',
        ['15']    = 'Requires alchemy 100. You are required to be in a guild in order to use the guildhall portal to Plane of SKy.',
        ['20']    = 'Requires manually obtaining a Globe of Discordant Energy.'
    },
    ['war'] = {
        ['10']    = '',
        ['pre15'] = 'Requires brewing 100.',
        ['15']    = '',
        ['20']    = '',
    },
    ['wiz'] = {
        ['10']    = '',
        ['pre15'] = '',
        ['15']    = '',
        ['20']    = '',
    },
}

return quests_requirements
