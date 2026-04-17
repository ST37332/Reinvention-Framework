////////////////////////////////////////////////////////////////////////////
////////////////////     IT WILL BE IN THE FUTURE     //////////////////////
////////////////////////////////////////////////////////////////////////////

//  maybe I'll change CAT_TEST1 to the category name, like:
//  Now - CAT_TEST1
//  Will be - "Test Category #1"

re.Jobs:RegisterSpawnPoint( re.Maps.CONSTRUCT, CAT_TEST1, "Deep Condemned Tunnels", 0, false, { 
    Vector( -396, -2770, -1775 ),
    Vector( -463, -2752, -1775 ),
    Vector( -384, -2717, -1775 ),
    Vector( -198, -2368, -1775 ),
    Vector( -198, -2527, -1775 )
})




////////////////////////////////////////////////////////////////////////////
/////////////////////////     ALREADY WORKING     //////////////////////////
////////////////////////////////////////////////////////////////////////////

TEAM_TESTJOB = re.Jobs:AddJob("Test Job", {

    color = Color(128, 128, 128),

    models = {
        'models/player/Group01/male_01.mdl',
        'models/player/Group01/male_02.mdl',
        'models/player/Group01/male_03.mdl',
        'models/player/Group01/male_04.mdl',
        'models/player/Group01/male_05.mdl',
        'models/player/Group01/male_06.mdl',
        'models/player/Group01/male_07.mdl',
        'models/player/Group01/male_08.mdl',
        'models/player/Group01/male_09.mdl',
        'models/player/Group01/female_01.mdl',
        'models/player/Group01/female_02.mdl',
        'models/player/Group01/female_03.mdl',
        'models/player/Group01/female_04.mdl',
        'models/player/Group01/female_05.mdl',
        'models/player/Group01/female_06.mdl'
    },

    weapons = {},

    items = { "radio" }, // WIP

    salary = 7, // WIP

    max = 3,

    bodygroups = "0721420000", -- Check: https://wiki.facepunch.com/gmod/Entity:SetBodyGroups

    isDefaultJob = true, // default FALSE

    description = "Idk, just TEST JOB?.",

    //  maybe I'll change CAT_TEST1 to the category name, like:
    //  Now - CAT_TEST1
    //  Will be - "Test Category #1"
    category = CAT_TEST1,

    bodyType = "human", // WIP: For Dynamic Damage (Like a EFT)
    slowWalkSpeed = 95,
    walkSpeed = 68,
    jumpPower = 160,
    runSpeed = 185,
    demoteOnDeath = true, // If you dead your job changed on isDefaultJob
    demoteable = true, // Someone can or not demote player with this Job
    immunity = 50 // WIP: For Job changer
})