local mq = require('mq')

local travel = {
    ['brd_pre15'] = {
        ['gate']  = 5,
        ['invis'] = 8
    },
    ['brd_10']    = {
        ['gate']  = 5,
        ['invis'] = 11
    },
    ['brd_15']    = {
        ['gate']  = 27,
        ['invis'] = 33
    },
    ['brd_20']    = {
        ['gate']  = 4,
        ['invis'] = 13
    },
    --Not accurate
    ['bst_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['bst_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['bst_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['bst_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['ber_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['ber_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['ber_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['ber_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['clr_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    ['clr_15']    = {
        ['gate']  = 0,
        ['invis'] = 17
    },
    ['clr_20']    = {
        ['gate'] = 0,
        ['invis'] = 12
    },
    ['clr_pre15'] = {
        ['gate']  = 0,
        ['invis'] = 6
    },
    --Not accurate
    ['dru_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['dru_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['dru_20']    = {
        ['gate']  = 0,
        ['invis'] = 12
    },
    --Not accurate
    ['dru_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['enc_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['enc_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['enc_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['enc_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mag_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mag_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mag_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mag_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mnk_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mnk_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mnk_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['mnk_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['nec_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['nec_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['nec_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['nec_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['pal_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['pal_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['pal_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['pal_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['rng_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['rng_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['rng_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['rng_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['rog_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['rog_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['rog_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    ['rog_pre15'] = {
        ['gate']  = 7,
        ['invis'] = 8
    },
    --Not accurate
    ['shd_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['shd_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    ['shd_15']    = {
        ['gate']  = 19,
        ['invis'] = 23
    },
    ['shd_20']    = {
        ['gate']  = 19,
        ['invis'] = 23
    },
    ['shm_10']    = {
        ['gate']  = 20,
        ['invis'] = 23
    },
    --Not accurate
    ['shm_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    ['shm_15']    = {
        ['gate']  = 24,
        ['invis'] = 32
    },
    ['shm_20']    = {
        ['gate']  = 16,
        ['invis'] = 14
    },
    --Not accurate
    ['war_10']    = {
        ['gate'] = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['war_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['war_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['war_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['wiz_10']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['wiz_15']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['wiz_20']    = {
        ['gate']  = 69,
        ['invis'] = 420
    },
    --Not accurate
    ['wiz_pre15'] = {
        ['gate']  = 69,
        ['invis'] = 420
    },
}

return travel
