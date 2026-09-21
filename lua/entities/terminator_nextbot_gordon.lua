AddCSLuaFile()

if not terminator_Extras then
    ErrorNoHalt( "terminator_nextbot_gordon needs StrawWagen's termhunter addon, it's not installed!\n" )
    return
end

ENT.Base = "terminator_nextbot"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Gordon Freeman"
ENT.Author = "regunkyle"
ENT.Purpose = "The right man in the wrong place can make all the difference in the world."
ENT.Category = "Terminator Nextbot"
ENT.SubCategory = "Other"

ENT.IsGordonFreeman = true

terminator_Extras.RegisterNPC( "terminator_nextbot_gordon", ENT, {
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

local GORDON_MODEL = "models/player/gorde/gordon.mdl"
local FALLBACK_MODEL = "models/player/barney.mdl"

if SERVER and not util.IsValidModel( GORDON_MODEL ) then
    print( "[terminator_nextbot_gordon] " .. GORDON_MODEL .. " not found, spawning as barney! install the gordon playermodel!" )
    ENT.Model = FALLBACK_MODEL
    ENT.Models = { FALLBACK_MODEL }

else
    ENT.Model = GORDON_MODEL
    ENT.Models = { GORDON_MODEL }

end

local entMeta = FindMetaTable( "Entity" )
local IsValid = IsValid

ENT.isTerminatorHunterChummy = "gordon_freeman"

ENT.SpawnHealth = 300
ENT.HealthRegen = nil

ENT.FriendlyFireMul = 0.1

ENT.DoMetallicDamage = nil
ENT.ReallyHeavy = nil
ENT.ReallyStrong = nil
ENT.MetallicMoveSounds = nil
ENT.FootstepClomping = false
ENT.term_DMG_ImmunityMask = nil
ENT.neverManiac = true
ENT.WalkSpeed = 100
ENT.MoveSpeed = 250
ENT.RunSpeed = 380
ENT.AccelerationSpeed = 1800
ENT.JumpHeight = 80
ENT.DeathDropHeight = 500
ENT.TakesFallDamage = true
ENT.HeightToStartTakingDamage = 300
ENT.FallDamagePerHeight = 0.15
ENT.BreathesAir = true
ENT.BreathesWater = nil
ENT.CanSwim = true
ENT.CanUseLadders = true
ENT.TERM_WEAPON_PROFICIENCY = WEAPON_PROFICIENCY_VERY_GOOD
ENT.AimSpeed = 320
ENT.HasBrains = true
ENT.JudgesEnemies = true
ENT.CanUseStuff = true
ENT.CanHearStuff = true
ENT.CanSpeak = false -- a man of few words. zero, in fact
ENT.Term_FootstepMode = "human"
ENT.Term_FootstepMsReductionPerUnitSpeed = 0.5

ENT.GordonMaxSuitArmor = 100
ENT.GordonSpawnArmor = 0 -- start with an empty suit
ENT.GordonBatteryArmor = 15 -- armor per item_battery
ENT.GordonArmorAbsorb = 0.8 -- HEV absorbs 80% of incoming damage while charged

ENT.GordonVialHeal = 25 -- health per item_healthvial
ENT.GordonKitHeal = 25 -- health per item_healthkit
ENT.GordonHealthSeekFrac = 0.6 -- hunt medkits below 60% health
ENT.GordonHealthSearchRange = 4000
ENT.GordonBatterySeekLevel = 50 -- hunt batteries below 50 armor
ENT.GordonBatterySearchRange = 2500

local gordonHealthItems = {
    ["item_healthvial"] = true,
    ["item_healthkit"] = true,
}

local gordonArmorItems = {
    ["item_battery"] = true,
}

-- also usable with E while driving him
local gordonUsableItems = {
    ["item_healthvial"] = true,
    ["item_healthkit"] = true,
    ["item_battery"] = true,
}

function ENT:GetSuitArmor()
    return self:GetNWInt( "GordonSuitArmor", 0 )
end

function ENT:SetSuitArmor( armor )
    self:SetNWInt( "GordonSuitArmor", math.Clamp( math.floor( armor ), 0, self.GordonMaxSuitArmor ) )
end

-- can he get any use out of this item right now?
function ENT:GordonCanUseItem( item )
    if not IsValid( item ) then return end

    local class = item:GetClass()
    if gordonHealthItems[ class ] then
        return self:Health() < self:GetMaxHealth()

    elseif gordonArmorItems[ class ] then
        return self:GetSuitArmor() < self.GordonMaxSuitArmor

    end
end

-- nom. returns true if the item was consumed
function ENT:GordonTakeHealthItem( item )
    if not self:GordonCanUseItem( item ) then return end

    local class = item:GetClass()

    if class == "item_battery" then
        self:SetSuitArmor( self:GetSuitArmor() + self.GordonBatteryArmor )
        self:EmitSound( "items/battery_pickup.wav", 75, 100 )
        SafeRemoveEntity( item )
        return true

    elseif gordonHealthItems[ class ] then
        local heal = ( class == "item_healthvial" ) and self.GordonVialHeal or self.GordonKitHeal
        self:SetHealth( math.min( self:Health() + heal, self:GetMaxHealth() ) )
        self:EmitSound( "items/smallmedkit1.wav", 75, 100 )
        SafeRemoveEntity( item )
        return true

    end
end

-- nearest useful item of the given kind
function ENT:GordonFindItem( wantHealth )
    local range = wantHealth and self.GordonHealthSearchRange or self.GordonBatterySearchRange
    local best
    local bestDist

    for _, item in ipairs( ents.FindInSphere( self:GetPos(), range ) ) do
        if self:GordonCanUseItem( item ) then
            local class = item:GetClass()
            if ( wantHealth and gordonHealthItems[ class ] ) or ( not wantHealth and gordonArmorItems[ class ] ) then
                local dist = self:GetPos():DistToSqr( item:GetPos() )
                if not bestDist or dist < bestDist then
                    best, bestDist = item, dist
                end
            end
        end
    end

    return best
end

-- gordon likes these, and they like gordon back
local gordonFriendlies = {
    ["player"] = true,
    ["npc_citizen"] = true,
    ["npc_alyx"] = true,
    ["npc_barney"] = true,
    ["npc_kleiner"] = true,
    ["npc_eli"] = true,
    ["npc_mossman"] = true,
    ["npc_magnusson"] = true,
    ["npc_vortigaunt"] = true,
    ["npc_dog"] = true,
    ["npc_monk"] = true,
    ["npc_fisherman"] = true,
}

local gordonHostiles = {
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

    for class in pairs( gordonFriendlies ) do
        relations[class] = { D_LI, D_LI, 100 }
    end

    for class, priority in pairs( gordonHostiles ) do
        relations[class] = { D_HT, D_HT, priority }
    end

    self.term_HardCodedRelations = relations
end

function ENT:ShouldBeEnemy( ent, fov, myTbl, entsTbl )
    if IsValid( ent ) and gordonFriendlies[entMeta.GetClass( ent )] then return false end

    return BaseClass.ShouldBeEnemy( self, ent, fov, myTbl, entsTbl )
end

function ENT:MakeFeud( enemy )
    if IsValid( enemy ) and gordonFriendlies[entMeta.GetClass( enemy )] then return end

    return BaseClass.MakeFeud( self, enemy )
end

local crateClass = "item_item_crate"

local gordonUsableWeapons = {
    ["weapon_pistol"] = true,
    ["weapon_smg1"] = true,
    ["weapon_357"] = true,
    ["weapon_ar2"] = true,
    ["weapon_shotgun"] = true,
    ["weapon_crossbow"] = true,
    ["weapon_frag"] = true,
    ["weapon_rpg"] = true,
    ["weapon_slam"] = true,
    ["weapon_stunstick_gordon"] = true,

    -- the lua analogs of the above, in case they end up on the ground somehow
    ["weapon_pistol_term"] = true,
    ["weapon_smg1_term"] = true,
    ["weapon_357_term"] = true,
    ["weapon_ar2_term"] = true,
    ["weapon_shotgun_term"] = true,
    ["weapon_crossbow_term"] = true,
    ["weapon_frag_term"] = true,
    ["weapon_rpg_term"] = true,
    ["weapon_slam_term"] = true,
    -- no weapon_physcannon. gordon left it at home
}

-- only half-life 2 weapons for this man. no admin guns, no m9k
function ENT:CanPickupWeapon( wep, doingHolstered, myTbl, wepsTbl )
    if IsValid( wep ) then
        local class = entMeta.GetClass( wep )
        if not gordonUsableWeapons[class] and class ~= crateClass then
            return false

        end
    end

    return BaseClass.CanPickupWeapon( self, wep, doingHolstered, myTbl, wepsTbl )
end

-- don't shoot explosive barrels that would gib our friends ( or ourselves )
function ENT:getShootableVolatile( myTbl, enemy )
    local volatile = BaseClass.getShootableVolatile( self, myTbl, enemy )
    if not IsValid( volatile ) then return end

    for _, nearby in ipairs( ents.FindInSphere( volatile:GetPos(), 300 ) ) do
        if nearby == self or gordonFriendlies[entMeta.GetClass( nearby )] then return end

    end

    return volatile
end

function ENT:CanOvercharge()
    return false -- no overcharge for you.
end

ENT.TERM_FISTS = "weapon_crowbar_gordon"
ENT.DefaultWeapon = "weapon_crowbar_gordon"

-- =========================================================================
-- THE INVENTORY
-- terminators can only holster one weapon on their back and one on their hip,
-- everything else gets dropped. gordon carries the entire arsenal instead.
-- the base's m_HolsteredWeapons table has no size limit of its own, the limit
-- only comes from CanHolsterWeap's slot check, so:
--   - CanHolsterWeap now always accepts
--   - HolsterWeap wears the first weapon per body slot visibly ( same bone math
--     as the terminators ), everything else is carried hidden
--   - UnHolsterWeap/DropWeapon un-hide weapons when equipped or dropped
-- =========================================================================

ENT.CanHolsterWeapons = true
ENT.CanFindWeaponsOnTheGround = true
ENT.WeaponSearchRange = 1500

-- spawn carrying every HL2 weapon?
-- true  = the full arsenal
-- false = spawns with just the crowbar, scavenges and hoards guns over time
ENT.SpawnWithFullArsenal = true

-- ordered! the first sidearm-sized and first back-sized weapon in this list
-- are the two that visibly show up on his body ( pistol on hip, smg on back )
ENT.GordonLoadout = {
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
}

-- no size limit on gordon's inventory, no evicting
-- returns canHolster, holsterData, toEvict ( never evicts )
function ENT:CanHolsterWeap( wep )
    if not self.CanHolsterWeapons then return false end
    if not IsValid( wep ) then return false end
    if self:IsHolsteredWeap( wep ) then return false end
    if wep:GetClass() == self.TERM_FISTS then return false end

    -- holsterDat can be nil ( weapon too big or too oddly shaped for a body
    -- slot, eg the rpg ), those get stored in the invisible inventory instead
    return true, self:GetHolsterData( wep )
end

function ENT:HolsterWeap( wep, silent )
    if not self:CanHolsterWeap( wep ) then return end

    local holsterDat = self:GetHolsterData( wep )
    local slot = holsterDat and holsterDat.slot

    local boneExists
    local boneId
    if slot then
        boneExists, boneId = self:HasHolsterBone( slot )
    end

    if wep == self:GetActiveWeapon() then
        self:SetActiveWeapon( NULL )
    end

    wep:SetOwner( self )
    wep:SetVelocity( vector_origin )
    wep:RemoveSolidFlags( FSOLID_TRIGGER )
    wep:RemoveEffects( EF_ITEM_BLINK )
    wep:PhysicsDestroy()

    wep:SetTransmitWithParent( true )
    wep:AddSolidFlags( FSOLID_NOT_SOLID )
    wep:SetMoveType( MOVETYPE_NONE )

    self.m_HolsteredWeapons = self.m_HolsteredWeapons or {}
    self.m_HolsteringSlots = self.m_HolsteringSlots or {}

    -- the most recent weapon per body slot is the one you can see,
    -- the rest of the arsenal is carried, but not rendered
    local slotTaken = IsValid( self.m_HolsteringSlots[ slot ] )
    if boneExists and not slotTaken then
        wep:FollowBone( self, boneId )
        wep:SetLocalAngles( holsterDat.rotation )
        wep:SetLocalPos( holsterDat.posOffset )
        wep:SetPos( wep:LocalToWorld( -wep:OBBCenter() ) )
        wep:SetNoDraw( false )
        self.m_HolsteringSlots[ slot ] = wep

    else
        wep:SetParent( self )
        wep:SetLocalPos( vector_origin )
        wep:SetLocalAngles( angle_zero )
        wep:SetNoDraw( true )

    end

    self.m_HolsteredWeapons[ wep ] = true

    wep:CallOnRemove( "terminator_unholsteronremove", function( removedWep, myOwner )
        if not IsValid( myOwner ) then return end
        myOwner:UnHolsterWeap( removedWep )

    end, self )

    if not silent then
        -- 'equip' sound
        self:EmitSound( "Flesh.Strain", 80, 120, 0.8 )

    end
end

function ENT:UnHolsterWeap( wep )
    if self.m_HolsteredWeapons then
        self.m_HolsteredWeapons[ wep ] = nil
    end

    if IsValid( wep ) then
        -- only free the body slot if it was OURS, hidden inventory weapons
        -- can share slot data with the visible one
        local holsterDat = self:GetHolsterData( wep )
        if holsterDat and self.m_HolsteringSlots and self.m_HolsteringSlots[ holsterDat.slot ] == wep then
            self.m_HolsteringSlots[ holsterDat.slot ] = nil
        end

        wep:SetNoDraw( false )
        wep:RemoveCallOnRemove( "terminator_unholsteronremove" )

    end
end

-- unhide inventory weapons when they leave us ( equipped, or dropped on death )
function ENT:DropWeapon( noHolster, droppingOverride )
    local wep = droppingOverride
    if not IsValid( wep ) then
        wep = self:GetActiveWeapon()
    end

    if IsValid( wep ) and ( wep == self:GetActiveWeapon() or self:IsHolsteredWeap( wep ) ) then
        wep:SetNoDraw( false )

    end

    return BaseClass.DropWeapon( self, noHolster, droppingOverride )
end

-- compat stub fix, actually lists the whole inventory
function ENT:GetWeapons()
    local weps = {}

    local active = self:GetWeapon()
    if IsValid( active ) then
        weps[#weps + 1] = active
    end

    local holstered = self:GetHolsteredWeapons()
    for wep, _ in pairs( holstered ) do
        if IsValid( wep ) then
            weps[#weps + 1] = wep
        end
    end

    return weps
end

-- give gordon a weapon straight into his inventory ( used for the spawn loadout )
function ENT:AddWeaponToInventory( wepClass )
    if not self.CanHolsterWeapons then return end

    -- no duplicates
    local active = self:GetActiveWeapon()
    if IsValid( active ) and active:GetClass() == wepClass then return end

    local holstered = self:GetHolsteredWeapons()
    for wep, _ in pairs( holstered ) do
        if IsValid( wep ) and wep:GetClass() == wepClass then return end

    end

    local wep = ents.Create( wepClass )
    if not IsValid( wep ) then return end

    wep:SetPos( self:GetPos() )
    wep:Spawn()
    self:HolsterWeap( wep, true )
    return wep

end

-- everything gordon is carrying, alphabetical by class
-- ( the crowbar is not included, it's innate and has its own hotkey )
function ENT:GetInventory()
    local inv = {}

    local active = self:GetActiveWeapon()
    if IsValid( active ) and active:GetClass() ~= self.TERM_FISTS then
        inv[#inv + 1] = active
    end

    local holstered = self:GetHolsteredWeapons()
    for wep, _ in pairs( holstered ) do
        if IsValid( wep ) then
            inv[#inv + 1] = wep
        end
    end

    table.sort( inv, function( a, b ) return a:GetClass() < b:GetClass() end )
    return inv
end

-- used by the drive controls, equip the next/previous weapon in the inventory.
-- skips weapons that fail to equip, so one broken weapon can't jam the cycle
function ENT:GordonCycleWeapon( forward )
    local inv = self:GetInventory()
    if #inv <= 0 then
        if not self:IsFists() then
            self:DoFists()

        end
        return
    end

    local active = self:GetActiveWeapon()
    local currIndex = 0
    if IsValid( active ) then
        for i, wep in ipairs( inv ) do
            if wep == active then
                currIndex = i
                break
            end
        end
    end

    local step = forward and 1 or -1
    local targetIndex = currIndex
    for _ = 1, #inv do
        targetIndex = targetIndex + step
        if targetIndex > #inv then targetIndex = 1 end
        if targetIndex < 1 then targetIndex = #inv end

        local wep = inv[targetIndex]
        if wep ~= active and self:SetupWeapon( wep ) then
            return wep
        end
    end
end

-- used by the drive controls, equip the best weapon for the current situation
function ENT:GordonEquipBestWeapon()
    local myTbl = self:GetTable()
    local distToEnemy = self.DistToEnemy or 0

    local best
    local bestScore = -math.huge
    for _, wep in ipairs( self:GetInventory() ) do
        local score = self:GetWeightOfWeapon( wep )
        if distToEnemy > 0 and self:GetWeaponRange( myTbl, wep ) < distToEnemy then
            score = score * 0.1 -- can't even reach the enemy with this one
        end
        if score > bestScore then
            best, bestScore = wep, score
        end
    end

    if not IsValid( best ) then
        if not self:IsFists() then
            self:DoFists()

        end
        return
    end

    if best ~= self:GetActiveWeapon() then
        self:SetupWeapon( best )
    end
end

function ENT:GiveDefaultWeapons( myTbl )
    myTbl = myTbl or self:GetTable()
    BaseClass.GiveDefaultWeapons( self, myTbl )

    -- ALWAYS load the full arsenal!
    -- ( the old version skipped this when the spawnmenu set an
    --   "additionalequipment" weapon -- which the termhunter npc menu does by
    --   default -- leaving gordon with one gun + the crowbar. no more. the
    --   spawnmenu pick now only decides what he spawns HOLDING )
    if not myTbl.SpawnWithFullArsenal then return end

    local added = 0
    for _, wepClass in ipairs( myTbl.GordonLoadout ) do
        if self:AddWeaponToInventory( wepClass ) then
            added = added + 1
        end
    end

    print( "[terminator_nextbot_gordon] arsenal loaded, " .. added .. " weapons stashed ( + the crowbar )" )
end

function ENT:AdditionalInitialize( myTbl )
    myTbl = myTbl or self:GetTable()

    self:SetSuitArmor( myTbl.GordonSpawnArmor )

    -- SAFETY NET: a second after spawn, make sure the arsenal actually exists.
    -- AddWeaponToInventory dedupes, so this is safe to run no matter what the
    -- spawnmenu, load order, or anything else did to the first attempt
    timer.Simple( 1, function()
        if not IsValid( self ) then return end
        if self.term_Dead then return end
        if not myTbl.SpawnWithFullArsenal then return end

        local added = 0
        for _, wepClass in ipairs( myTbl.GordonLoadout ) do
            if self:AddWeaponToInventory( wepClass ) then
                added = added + 1
            end
        end

        if added > 0 then
            print( "[terminator_nextbot_gordon] force-loaded " .. added .. " missing arsenal weapons!" )

        end
    end )
end

-- =========================================================================
-- health & suit seeking
-- a class task monitors his vitals and dispatches the medkit task below.
-- ( it also hoovers up items he walks over, HL2-style )
-- NOTE: IsTaskActive, NOT HasTask! HasTask only checks the task REGISTRY,
-- which would always be true and the seek would never start
-- =========================================================================

ENT.MyClassTask = {
    OnStart = function( self, data )
        data.nextItemScan = 0
        data.nextSeekCheck = 0

    end,

    BehaveUpdatePriority = function( self, data )
        local cur = CurTime()

        -- touch pickup, like HL2
        if data.nextItemScan < cur then
            data.nextItemScan = cur + 0.4

            for _, item in ipairs( ents.FindInSphere( self:GetPos(), 50 ) ) do
                if self:GordonCanUseItem( item ) then
                    self:GordonTakeHealthItem( item )

                end
            end
        end

        -- decide whether to go hunting
        if data.nextSeekCheck > cur then return end
        data.nextSeekCheck = cur + 1

        if self:IsTaskActive( "movement_gordon_gethealth" ) then return end
        if self:IsControlledByPlayer() then return end -- the driver can use items with E

        local hp = self:Health()
        local maxHp = self:GetMaxHealth()
        local armor = self:GetSuitArmor()

        local hurt = hp < maxHp * self.GordonHealthSeekFrac
        local reallyHurt = hp < maxHp * 0.35
        local enemy = self:GetEnemy()
        local engaged = self.IsSeeEnemy and IsValid( enemy ) and self.DistToEnemy < 800

        if hurt and ( not engaged or reallyHurt ) then
            local item = self:GordonFindItem( true )
            if IsValid( item ) then
                self:KillAllTasksWith( "movement" )
                self:StartTask( "movement_gordon_gethealth", { Item = item }, "gordon needs a medkit!" )
            end

        elseif armor < self.GordonBatterySeekLevel and not engaged then
            local item = self:GordonFindItem( false )
            if IsValid( item ) then
                self:KillAllTasksWith( "movement" )
                self:StartTask( "movement_gordon_gethealth", { Item = item }, "gordon needs a battery!" )
            end

        end
    end,
}

-- the actual "go get the medkit" movement task
function ENT:DoCustomTasks( defaultTasks )
    defaultTasks["movement_gordon_gethealth"] = {
        OnStart = function( self, data )
            data.timeout = CurTime() + 20
            if not self.isUnstucking then
                self:InvalidatePath( "going for an item, killing old path" )

            end
        end,

        BehaveUpdateMotion = function( self, data )
            if data.timeout < CurTime() then
                self:TaskFail( "movement_gordon_gethealth" )
                self:StartTask( "movement_handler", nil, "gave up on the item" )
                return
            end

            -- item gone or no longer useful?
            if not self:GordonCanUseItem( data.Item ) then
                local newItem = self:GordonFindItem( true ) or self:GordonFindItem( false )
                if IsValid( newItem ) then
                    data.Item = newItem

                else
                    self:TaskFail( "movement_gordon_gethealth" )
                    self:StartTask( "movement_handler", nil, "no more items" )
                    return

                end
            end

            local item = data.Item
            local itemPos = item:GetPos() + Vector( 0, 0, 10 )

            -- something wants to kill us more than we want the item
            local enemy = self:GetEnemy()
            if IsValid( enemy ) and self.IsSeeEnemy and self.DistToEnemy < 250 then
                self:TaskFail( "movement_gordon_gethealth" )
                self:EnemyAcquired( "movement_gordon_gethealth" )
                return
            end

            -- close enough, grab it
            if self:GetPos():Distance( itemPos ) < 60 and terminator_Extras.PosCanSee( self:GetShootPos(), itemPos, self ) then
                self:GordonTakeHealthItem( item )
                self:TaskComplete( "movement_gordon_gethealth" )
                self:StartTask( "movement_handler", nil, "patched up!" )
                return
            end

            if self.isUnstucking then
                self:ControlPath2( not self.IsSeeEnemy )
                return
            end

            if self:primaryPathInvalidOrOutdated( itemPos ) then
                self:SetupPathShell( itemPos )

                if not self:primaryPathIsValid() then
                    -- can't path there, is it at least close enough to walk at?
                    if self:GetPos():Distance( itemPos ) < 300 then
                        self:GotoPosSimple( self:GetTable(), itemPos, 25 )
                        return

                    end
                    self:TaskFail( "movement_gordon_gethealth" )
                    self:StartTask( "movement_handler", nil, "item unreachable" )
                    return

                end
            end

            self:ControlPath2( not self.IsSeeEnemy )
        end,

        ShouldRun = function( self, data )
            return self:canDoRun()
        end,
    }
end

ENT.MySpecialActions = {
    ["invnext"] = {
        commandName = "invnext",
        drawHint = true,
        name = "Next Weapon",
        desc = "Cycle to the next weapon in Gordon's inventory",
        ratelimit = 0.15,

        svAction = function( _drive, _driver, bot )
            bot:GordonCycleWeapon( true )

        end,
    },
    ["invprev"] = {
        commandName = "invprev",
        drawHint = true,
        name = "Previous Weapon",
        desc = "Cycle to the previous weapon in Gordon's inventory",
        ratelimit = 0.15,

        svAction = function( _drive, _driver, bot )
            bot:GordonCycleWeapon( false )

        end,
    },
    ["WepSlot1"] = {
        commandName = "slot1",
        drawHint = true,
        name = "Best Weapon",
        desc = "Pull out Gordon's best weapon for the situation",
        ratelimit = 0.15,

        svAction = function( _drive, _driver, bot )
            bot:GordonEquipBestWeapon()

        end,
    },
    ["WepSlot2"] = {
        commandName = "slot2",
        drawHint = true,
        name = "Crowbar",
        desc = "Pull out the crowbar",
        ratelimit = 0.15,

        svAction = function( _drive, _driver, bot )
            if not bot:IsFists() then
                bot:DoFists()

            end
        end,
    },
    -- actually DROP the weapon, don't stash it in the inventory
    ["DropCurrentWeapon"] = {
        commandName = "noclip",
        drawHint = true,
        name = "Drop current weapon",
        desc = "Drop the bot's current weapon",
        ratelimit = 0.25,

        svAction = function( _drive, _driver, bot )
            local actWep = bot:GetActiveLuaWeapon()
            if not IsValid( actWep ) then return end
            if bot:IsFists() then return end
            bot:DropWeapon( true )

        end,
    },
    -- same as the base use action, plus medkit/battery usage, and weapon
    -- pickups respect gordon's HL2-only whitelist
    ["Use"] = {
        commandName = "+use",
        drawHint = function( bot )
            if bot.CanUseStuff or bot.CanFindWeaponsOnTheGround then
                return true
            end
        end,
        name = "Use",
        desc = "Interact with the environment",
        ratelimit = 0.15,

        svAction = function( _drive, _driver, bot )
            local shoot = bot:GetShootPos()
            local blocker
            -- find something to use, check under crosshair first
            local blockerResult = util.QuickTrace( shoot, bot:GetAimVector() * 80, bot )
            if blockerResult.Hit and IsValid( blockerResult.Entity ) then
                blocker = blockerResult.Entity -- ( the base has a typo here, it reads .SetEntity, which is always nil )

            end
            if not IsValid( blocker ) then -- now check nearby the crosshair
                local secondBiggerHullCheck = {
                    start = shoot,
                    endpos = shoot + bot:GetAimVector() * 80,
                    mins = Vector( -8, -8, -8 ),
                    maxs = Vector( 8, 8, 8 ),
                    ignoreworld = true,
                    filter = function( ent )
                        if ent == bot then return false end
                        if ent:GetParent() == bot then return false end
                        return true

                    end,
                }
                local hullResult = util.TraceHull( secondBiggerHullCheck )
                if hullResult.Hit and IsValid( hullResult.Entity ) and terminator_Extras.PosCanSee( hullResult.Entity:GetPos(), bot:GetShootPos() ) then
                    blocker = hullResult.Entity

                else
                    blocker = bot.LastShootBlocker

                end
            end

            if not IsValid( blocker ) then return end

            -- medkits and batteries first
            if gordonUsableItems[ blocker:GetClass() ] then
                bot:GordonTakeHealthItem( blocker )
                return

            end

            if bot.CanFindWeaponsOnTheGround and blocker:IsWeapon() then -- pickup if we can pick stuff up
                if not bot:CanPickupWeapon( blocker ) then return end -- HL2 weapons only!
                if IsValid( bot:GetActiveLuaWeapon() ) then
                    bot:DropWeapon( false ) -- stash current weapon

                end
                bot:SetupWeapon( blocker )
                return

            end

            if not bot.CanUseStuff then return end
            bot:Use2( blocker )

        end,
    },
}


if CLIENT then
    language.Add( "terminator_nextbot_gordon", ENT.PrintName )

    function ENT:AdditionalClientInitialize()
        -- stops the base from tinting his suit a random color
        self.PlayerColorVec = Vector( 1, 1, 1 )
    end

    -- =========================================================================
    -- HEV suit power readout, drawn on top of the base's health/ammo HUD
    -- =========================================================================
    function ENT:ModifyPlayerControlHUD( chx, chy, chHit )
        -- let the base draw its full HUD ( health, ammo, hints, crosshair ) first
        BaseClass.ModifyPlayerControlHUD( self, chx, chy, chHit )

        local scaleHoris = ScrW() / 1920
        local scaleVert = ScrH() / 1080

        local armor = self:GetNWInt( "GordonSuitArmor", 0 )
        local maxArmor = self.GordonMaxSuitArmor or 100
        local armorFrac = math.Clamp( armor / maxArmor, 0, 1 )

        local barX = 24 * scaleHoris
        local barY = ScrH() - 110 * scaleVert
        local barW = 480 * scaleHoris

        -- suit power number, next to the health number
        local alpha = armor <= 0 and 120 or 255
        surface.SetFont( "TerminatorHUD_Large" )
        local hpTxt = tostring( math.max( 0, self:Health() ) )
        local hpW = surface.GetTextSize( hpTxt )
        local numX = barX + 4 * scaleHoris + hpW + 34 * scaleHoris

        draw.SimpleText( tostring( armor ), "TerminatorHUD_Large", numX, barY - 48 * scaleVert, Color( 120, 220, 255, alpha ), TEXT_ALIGN_LEFT )
        draw.SimpleText( "SUIT POWER", "TerminatorHUD_Small", numX, barY - 66 * scaleVert, Color( 120, 220, 255, math.max( 100, alpha - 60 ) ), TEXT_ALIGN_LEFT )

        -- suit power bar, above the health bar
        local suitY = barY - 62 * scaleVert
        surface.SetDrawColor( 0, 0, 0, 180 )
        surface.DrawRect( barX - 4 * scaleHoris, suitY - 4 * scaleVert, barW + 8 * scaleHoris, 10 * scaleVert + 8 * scaleVert )
        surface.SetDrawColor( 60, 60, 60, 255 )
        surface.DrawRect( barX, suitY, barW, 10 * scaleVert )
        surface.SetDrawColor( 120, 220, 255, 255 )
        surface.DrawRect( barX, suitY, barW * armorFrac, 10 * scaleVert )

        return true
    end

    -- =========================================================================
    -- FIXED drive hooks.
    -- the base's version of this function installs a PlayerBindPress hook that
    -- does "self.commandCombos[commandName] >= IN_ATTACK" with no nil check.
    -- commandCombos only has entries for actions with inBind combos, so every
    -- plain commandName action ( invnext, invprev, slot1, slot2, +use, noclip )
    -- ERRORS the moment you press its bind, and the action never reaches the
    -- server. this is the base's function with that one bug fixed.
    -- =========================================================================
    function ENT:SetupCLDrivingHooks()
        local toTeardown = {}

        toTeardown[#toTeardown + 1] = "PlayerBindPress"
        hook.Add( "PlayerBindPress", "Term_CLDriving", function( ply, bind, pressed, code )
            if not self.commandNames then return end -- wait...

            local commandName = self.commandNames[bind]
            if not commandName then return end

            -- THE FIX: nil-check the combo before comparing
            local combo = self.commandCombos[commandName]
            if combo and combo >= IN_ATTACK and not ply:KeyDown( combo ) then return end -- it needs both down

            if self.commandClActions[commandName] then
                self.commandClActions[commandName]( self, ply, pressed, code )

            end
            if self.commandSvActions[commandName] then
                net.Start( "Term_DriveAction" )
                    net.WriteEntity( self )
                    net.WriteString( commandName )
                net.SendToServer()

            end
        end )

        toTeardown[#toTeardown + 1] = "HUDPaint"
        hook.Add( "HUDPaint", "Term_CLDriving", function()
            local startPos = self:GetShootPos()
            local aimDir = self:GetEyeAngles():Forward()
            local crosshairTrace = util.TraceLine( {
                start = startPos,
                endpos = startPos + aimDir * 56756, -- large distance constant: effectively 'infinite' ray for crosshair placement
                mask = MASK_SHOT,
                filter = self,
            } )
            local hitPosCorrected, hittingATarget = self:GetAssistedHitPos( aimDir, crosshairTrace )
            local hitPos = hitPosCorrected or crosshairTrace.HitPos
            local chp = hitPos:ToScreen()

            self:ModifyPlayerControlHUD( chp.x, chp.y, hittingATarget )

        end )

        -- Suppress base HUD pieces while driving.
        local suppressed = {
            ["CHudHealth"] = true,
            ["CHudBattery"] = true,
            ["CHudAmmo"] = true,
            ["CHudSecondaryAmmo"] = true,
            ["CHudDamageIndicator"] = true,

        }

        toTeardown[#toTeardown + 1] = "HUDShouldDraw"
        hook.Add( "HUDShouldDraw", "Term_CLDriving", function( name )
            if suppressed[name] then return false end

        end )

        hook.Add( "RenderScene", "Term_CLDriving", function()
            if IsValid( LocalPlayer():GetDrivingEntity() ) then return end
            for _, hookName in ipairs( toTeardown ) do
                hook.Remove( hookName, "Term_CLDriving" )

            end
            toTeardown = nil
            self.StopDriving = nil
            hook.Remove( "RenderScene", "Term_CLDriving" )

        end )
    end

    -- backup delivery for gordon's drive actions, completely independent of the
    -- synced action tables. all of gordon's actions are ratelimited, so if the
    -- hook above also sends, the double-send is harmlessly absorbed
    local gordonDriveBinds = {
        ["invnext"] = "invnext",
        ["invprev"] = "invprev",
        ["slot1"] = "WepSlot1",
        ["slot2"] = "WepSlot2",
        ["noclip"] = "DropCurrentWeapon",
        ["+use"] = "Use",
    }

    hook.Add( "PlayerBindPress", "Term_GordonDriveBinds", function( ply, bind )
        local actionName = gordonDriveBinds[bind]
        if not actionName then return end

        local ent = ply:GetDrivingEntity()
        if not IsValid( ent ) or not ent.IsGordonFreeman then return end

        net.Start( "Term_DriveAction" )
            net.WriteEntity( ent )
            net.WriteString( actionName )
        net.SendToServer()

    end )

    return
end

hook.Add( "EntityTakeDamage", "terminator_nextbot_gordon_damage", function( ent, dmg )
    if not ent.IsGordonFreeman then return end

    -- crushing func_doors deal absurd damage and can instagib him.
    -- ( terminators get this protection inside their DoMetallicDamage branch,
    --   gordon turned that off, so he gets his own clamp )
    local attacker = dmg:GetAttacker()
    if IsValid( attacker ) then
        local class = attacker:GetClass()
        if class == "func_door_rotating" or class == "func_door" then
            dmg:SetDamage( math.Clamp( dmg:GetDamage(), 0, 25 ) )
            ent:ReallyAnger( 10 )
            ent.overrideMiniStuck = true

        end
    end

    -- the HEV suit! while it has charge, it absorbs most incoming damage
    local damage = dmg:GetDamage()
    local armor = ent:GetSuitArmor()
    if damage <= 0 or armor <= 0 then return end
    if bit.band( dmg:GetDamageType(), bit.bor( DMG_DROWN, DMG_DIRECT ) ) ~= 0 then return end

    local absorbed = math.min( armor, damage * ent.GordonArmorAbsorb )
    ent:SetSuitArmor( armor - absorbed )
    dmg:SetDamage( damage - absorbed )

    if ent:GetSuitArmor() <= 0 then
        -- suit's dead, gordon
        ent:EmitSound( "items/suitchargeno1.wav", 70, 100 )

    end
end )