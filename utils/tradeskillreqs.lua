local mq = require('mq')

local elheader = "\ay[\agEpic Laziness\ay]"

local tradeskill_requirements = {
    ['bst'] = {
        ['pre15'] = {
            ['Tailoring'] = 100,
            ['Brewing'] = 122,
        },
        ['15'] = {
            ['Tailoring'] = 100,
        },
        ['20'] = {
            ['Baking'] = 100,
            ['Blacksmithing'] = 100,
            ['Pottery'] = 100
        }
    },
    ['clr'] = {
        ['15'] = {
            ['Brewing'] = 100
        }
    },
    ['pal'] = {
        ['15'] = {
            ['Fishing'] = 100
        }
    },
    ['rog'] = {
        ['15'] = {
            ['Baking'] = 192,
            ['Tailoring'] = 82,
            ['Blacksmithing'] = 104,
            ['Jewelry Making'] = 120,
            ['Make Poison'] = 277,
            ['Brewing'] = 121
        },
    },
    ['shd'] = {
        ['15'] = {
            ['Tailoring'] = 100,
        },
    },
    ['shm'] = {
        ['15'] = {
            ['Alchemy'] = 100,
        },
    },
}

return tradeskill_requirements
