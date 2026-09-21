--[[---------------------------------------------------------
    weapon_crowbar_gordon
    gordon freeman's personal crowbar, for terminator_nextbot_gordon.

    a REAL melee weapon for the term bot base. it does not get thrown
    like the terminators' weapon_crowbar_term does.

    implements the "lua weapon" interface the bot base calls:
    NPCShoot_Primary, NPCShoot_Secondary, GetNPCBurstSettings,
    GetNPCRestTimes, GetCapabilities, TranslateActivity, NPC_Initialize,
    and the Equip/Deploy/OwnerChanged/OnDrop stubs.
------------------------------------------------------------]]

AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName = "Crowbar"
SWEP.Author = "terminator_nextbot_gordon"
SWEP.Instructions = "Bot weapon, not intended for players"
SWEP.Spawnable = false

SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

SWEP.HoldType = "melee"
SWEP.Weight = 8

SWEP.Primary = {
    Automatic = true,
    ClipSize = -1,
    DefaultClip = -1,
    Ammo = "",
}
SWEP.Secondary = {
    Automatic = false,
    ClipSize = -1,
    DefaultClip = -1,
    Ammo = "",
}

-- melee tuning
SWEP.Range = 85 -- how far the swing reaches, read by the bot's weapon logic
SWEP.MeleeDamage = 25
SWEP.MeleeInterval = 0.45 -- seconds between swings
SWEP.MeleeForce = 1500
SWEP.HitMask = MASK_SOLID -- used by the bot's canHitEnt melee checks

-- swap these for direct file paths if the soundscripts are silent on your mount
SWEP.SwingSnd = "weapons/iceaxe/iceaxe_swing1.wav"
SWEP.HitSnd = "Weapon_Crowbar.Melee_Hit"
SWEP.WorldSnd = "Weapon_Crowbar.Melee_Hit_World"
SWEP.ZapSnd = nil -- stunstick only

-- our own GetHoldType, so we never depend on whatever holdtype patching
-- the base does. the base calls wep:GetHoldType() when equipping
function SWEP:GetHoldType()
    return self.HoldType
end

-- melee animations for hl2mp playermodels.
-- any nil activity here just falls back to the base's gun animations
do
    local meleeAttack = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE or ACT_HL2MP_GESTURE_RANGE_ATTACK

    local actTranslations = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_MELEE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_MELEE,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_MELEE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_MELEE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_MELEE,
        [ACT_MP_ATTACK_STAND_PRIMARYFIRE] = meleeAttack,
        [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = meleeAttack,
    }

    function SWEP:TranslateActivity( act )
        return actTranslations[ act ]
    end
end

function SWEP:Initialize()
    self:SetWeaponHoldType( self.HoldType )
end

-- bot weapon interface stubs.
-- NOTE: these are ProtectedCall'd by the bot base, and a missing/ERRORING
-- callback makes the bot DROP the weapon as "buggy", so they must all exist!
function SWEP:NPC_Initialize() end
function SWEP:Equip( _owner ) end
function SWEP:Deploy() return true end
function SWEP:OwnerChanged() end
function SWEP:OnDrop() end
function SWEP:Reload() end
function SWEP:NPCShoot_Secondary()
    self:SetNextSecondaryFire( CurTime() + 0.5 )
end

function SWEP:PrimaryAttack()
    self:Swing()
end

function SWEP:GetCapabilities()
    return CAP_WEAPON_MELEE_ATTACK1
end

-- burst of 1 with rest time equal to the swing interval, so the bot
-- swings at a steady, human pace ( and uses frate while player-driven )
function SWEP:GetNPCBurstSettings()
    return 1, 1, self.MeleeInterval
end

function SWEP:GetNPCRestTimes()
    return self.MeleeInterval, self.MeleeInterval * 1.25
end

-- THE SWING. a real melee attack, no throwing!
function SWEP:Swing( shootPos, aimDir )
    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    shootPos = shootPos or owner:GetShootPos()
    aimDir = aimDir or owner:GetAimVector()

    self:SetNextPrimaryFire( CurTime() + self.MeleeInterval )
    self:EmitSound( self.SwingSnd, 70, 100, 0.7, CHAN_STATIC )

    local filter = { self, owner }
    for _, child in ipairs( owner:GetChildren() ) do
        filter[#filter + 1] = child
    end

    local tr = util.TraceHull( {
        start = shootPos,
        endpos = shootPos + aimDir * self.Range,
        mask = self.HitMask,
        filter = filter,
        mins = Vector( -8, -8, -8 ),
        maxs = Vector( 8, 8, 8 ),
    } )

    if not tr.Hit then return end -- clean whiff

    local hitEnt = tr.Entity
    if IsValid( hitEnt ) then
        local dmg = DamageInfo()
        dmg:SetAttacker( owner )
        dmg:SetInflictor( self )
        dmg:SetDamage( self.MeleeDamage )
        dmg:SetDamageType( DMG_CLUB )
        dmg:SetDamageForce( aimDir * self.MeleeForce )
        dmg:SetDamagePosition( tr.HitPos )
        hitEnt:TakeDamageInfo( dmg )

        self:EmitSound( self.HitSnd, 75, 100, 0.9, CHAN_STATIC )
        if self.ZapSnd then
            self:EmitSound( self.ZapSnd, 75, math.random( 95, 105 ), 0.9, CHAN_STATIC )

        end

    else
        self:EmitSound( self.WorldSnd, 70, 100, 0.8, CHAN_STATIC )

    end
end

function SWEP:NPCShoot_Primary( shootPos, aimDir )
    self:Swing( shootPos, aimDir )
end

-- this is gordon's personal crowbar, players can't have it
hook.Add( "PlayerCanPickupWeapon", "weapon_crowbar_gordon_noPlys", function( _ply, wep )
    if wep:GetClass() == "weapon_crowbar_gordon" then return false end
end )