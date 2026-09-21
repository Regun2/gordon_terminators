AddCSLuaFile()

if not terminator_Extras then
    ErrorNoHalt( "terminator_nextbot_gordonevil needs StrawWagen's termhunter addon, it's not installed!\n" )
    return
end

ENT.Base = "terminator_nextbot_gordon"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Evil Gordon Freeman"
ENT.Purpose = "Rise and shine, Mr Freeman. Rise and... shine."
ENT.Category = "Terminator Nextbot"
ENT.IsEvilGordon = true
ENT.isTerminatorHunterChummy = "terminators"

terminator_Extras.RegisterNPC( "terminator_nextbot_gordonevil", ENT, {
    Weapons = {
        "weapon_pistol",
        "weapon_smg1",
        "weapon_357",
        "weapon_ar2",
        "weapon_shotgun",
        "weapon_crossbow",
        "weapon_frag",
        "weapon_rpg",
        "weapon_stunstick_gordon",
        "weapon_slam",
    },
} )

local IsValid = IsValid

local EVIL_SUBMAT = "models/gordon/gordon_sheet_evil"
local EVIL_SUBMAT_INDEX = 4

function ENT:AdditionalInitialize( myTbl )
    myTbl = myTbl or self:GetTable()

    -- good gordon's init: HEV suit charge + the arsenal safety net
    BaseClass.AdditionalInitialize( self, myTbl )

    -- THE visual difference
    self:SetSubMaterial( EVIL_SUBMAT_INDEX, EVIL_SUBMAT )
end

local evilHostiles = {
    ["player"] = 1000,
    ["npc_citizen"] = 250,
    ["npc_alyx"] = 250,
    ["npc_barney"] = 250,
    ["npc_kleiner"] = 250,
    ["npc_eli"] = 250,
    ["npc_mossman"] = 250,
    ["npc_magnusson"] = 250,
    ["npc_vortigaunt"] = 250,
    ["npc_dog"] = 250,
    ["npc_monk"] = 250,
    ["npc_fisherman"] = 250,
    ["npc_combine_s"] = 250,
    ["npc_combine"] = 250,
    ["npc_metropolice"] = 250,
    ["npc_stalker"] = 150,
    ["npc_manhack"] = 150,
    ["npc_cscanner"] = 150,
    ["npc_clawscanner"] = 150,
    ["npc_turret_floor"] = 200,
    ["npc_turret_ceiling"] = 200,
    ["npc_combine_camera"] = 150,
    ["npc_rollermine"] = 150,
    ["npc_apcdriver"] = 200,
    ["npc_strider"] = 250,
    ["npc_hunter"] = 250,
    ["npc_combinegunship"] = 250,
    ["npc_combinedropship"] = 150,
    ["npc_helicopter"] = 250,
    ["npc_zombie"] = 100,
    ["npc_zombie_torso"] = 100,
    ["npc_fastzombie"] = 100,
    ["npc_fastzombie_torso"] = 100,
    ["npc_poisonzombie"] = 100,
    ["npc_zombine"] = 100,
    ["npc_headcrab"] = 100,
    ["npc_headcrab_fast"] = 100,
    ["npc_headcrab_black"] = 100,
    ["npc_headcrab_poison"] = 100,
    ["npc_antlion"] = 100,
    ["npc_antlion_worker"] = 100,
    ["npc_antlionguard"] = 100,
    ["npc_barnacle"] = 100,
}

function ENT:DoHardcodedRelations()
    local relations = {}

    for class, priority in pairs( evilHostiles ) do
        relations[class] = { D_HT, D_HT, priority }
    end

    self.term_HardCodedRelations = relations
end

function ENT:ShouldBeEnemy( ent, fov, myTbl, entsTbl )
    if IsValid( ent ) and ent.isTerminatorHunterChummy == self.isTerminatorHunterChummy then return false end

    local shouldBeEnemy = scripted_ents.GetStored( "terminator_nextbot" ).t.ShouldBeEnemy
    return shouldBeEnemy( self, ent, fov, myTbl, entsTbl )
end

function ENT:MakeFeud( enemy )
    if IsValid( enemy ) and enemy.isTerminatorHunterChummy == self.isTerminatorHunterChummy then return end

    local makeFeud = scripted_ents.GetStored( "terminator_nextbot" ).t.MakeFeud
    return makeFeud( self, enemy )
end

function ENT:getShootableVolatile( myTbl, enemy )
    local getVolatile = scripted_ents.GetStored( "terminator_nextbot" ).t.getShootableVolatile
    local volatile = getVolatile( self, myTbl, enemy )
    if not IsValid( volatile ) then return end

    for _, nearby in ipairs( ents.FindInSphere( volatile:GetPos(), 300 ) ) do
        if nearby == self or nearby.isTerminatorHunterChummy == self.isTerminatorHunterChummy then return end

    end

    return volatile
end

-- =========================================================================
-- client
-- =========================================================================

if CLIENT then
    language.Add( "terminator_nextbot_gordonevil", ENT.PrintName )

    -- keep the evil skin on the death ragdoll
    hook.Add( "CreateClientsideRagdoll", "terminator_gordonevil_ragdoll", function( died, ragdoll )
        if not died.IsEvilGordon then return end

        ragdoll:SetSubMaterial( EVIL_SUBMAT_INDEX, EVIL_SUBMAT )

    end )

    return
end