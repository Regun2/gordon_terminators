--[[---------------------------------------------------------
    weapon_stunstick_gordon
    gordon's stunstick. same real-melee behavior as his crowbar,
    but heavier, slower, and shocky. doesn't get thrown like the
    terminators' weapon_stunstick_term does.
------------------------------------------------------------]]

AddCSLuaFile()

SWEP.Base = "weapon_crowbar_gordon"
SWEP.PrintName = "#HL2_Stunbaton"

SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.Weight = 7

SWEP.Range = 95
SWEP.MeleeDamage = 45
SWEP.MeleeInterval = 0.8
SWEP.MeleeForce = 2500

SWEP.SwingSnd = "weapons/iceaxe/iceaxe_swing1.wav"
SWEP.HitSnd = "physics/flesh/flesh_impact_hard3.wav"
SWEP.WorldSnd = "physics/metal/metal_computer_impact_bullet3.wav"
SWEP.ZapSnd = "ambient/energy/zap1.wav"

-- players can't have this one either
hook.Add( "PlayerCanPickupWeapon", "weapon_stunstick_gordon_noPlys", function( _ply, wep )
    if wep:GetClass() == "weapon_stunstick_gordon" then return false end
end )