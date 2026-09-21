local set = {
    name = "evil_gordons_glee", -- unique name, matches the filename
}

if SERVER then

    local bossHealthPerExtraPlayer = 250
    local bossStartsSuitedUp = true -- spawn with a full HEV charge

    local function evilGordonBossUp( _spawnData, npc )
        local plys = player.GetAll()

        -- boss spawns with a full suit charge
        if bossStartsSuitedUp and npc.SetSuitArmor then
            npc:SetSuitArmor( npc.GordonMaxSuitArmor or 100 )
            npc:EmitSound( "items/battery_pickup.wav", 75, 90 )

        end

        -- scale with playercount so he holds up as the round boss
        local extraPlys = #plys - 1
        if extraPlys > 0 then
            local newMax = npc:GetMaxHealth() + extraPlys * bossHealthPerExtraPlayer
            npc:SetMaxHealth( newMax )
            npc:SetHealth( newMax )

        end

        huntersGlee_Announce( plys, 100, 10, "Rise and shine.\nEvil Gordon has the entire arsenal." )

    end

    local setSv = {
        prettyName = "Evil Gordon Freeman",
        description = "He brought the whole arsenal.\nThe shop is CLOSED.\nKill him to escape.",
        difficultyPerMin = 0.05, -- barely anything, there is only ever one of him
        waveInterval = "default", -- time between spawn waves
        diffBumpWhenWaveKilled = 0, -- the boss IS the "<= 1 hunters left" state, the wave-clear bump would fire every single wave. keep difficulty flat
        startingBudget = "default", -- so budget isnt 0
        spawnCountPerDifficulty = "default",
        startingSpawnCount = "default",
        maxSpawnCount = 1, -- ONLY him. ( <= 1 also auto-detects the boss: killing him escapes all alive players )
        maxSpawnDist = "default",
        roundEndSound = "default",
        roundStartSound = "default",
        roundEarlyStartSound = "default", -- plays 10s before round start
        genericSpawnerRate = "default", -- speeds up or slows down the crate/beartrap/etc spawner
        chanceToBeVotable = 2,
        spawns = {
            {
                hardRandomChance = nil,
                name = "evil_gordon", -- unique name
                prettyName = "Evil Gordon Freeman",
                class = "terminator_nextbot_gordonevil", -- class spawned
                spawnType = "hunter",
                difficultyCost = { 30 }, -- cost barely matters, minCount bypasses budget. it's the boss
                countClass = "terminator_nextbot_gordonevil*", -- class COUNTED, uses findbyclass. note: does NOT match good gordon
                minCount = { 1 }, -- will ALWAYS maintain this count
                maxCount = { 1 }, -- will never exceed this count, uses findbycount
                isBoss = true, -- when the boss is killed, all alive players escape
                postSpawnedFuncs = { evilGordonBossUp },
            },
        }
    }
    table.Merge( set, setSv )

end

local noShopReason = "There is no shop against Evil Gordon."

function set:Activate()
    self:Hook( "glee_blockshopopen", function()
        return true, noShopReason

    end )
    -- the shop panel is only one way in, termhunt_purchase is the other, and this closes both
    self:Hook( "glee_shop_canshow", function()
        return false, noShopReason

    end )
end

-- put the spawnset IN the global table to be gobbled
table.insert( GLEE_SPAWNSETS, set )
