local array = include( "modules/array" )
local util = include( "client_util" )

local XP_PER_MISSION =
{
    100, 
    150,
    200
}

local XP_BASELINE = 80
local XP_INCREMENT1 = 250
local XP_INCREMENT2 = 500
local XP_INCREMENT3 = 600

local XP_LEVELS = {}

XP_LEVELS[1] = XP_BASELINE
XP_LEVELS[2] = XP_LEVELS[1] + XP_INCREMENT1
XP_LEVELS[3] = XP_LEVELS[2] + XP_INCREMENT2
XP_LEVELS[4] = XP_LEVELS[3] + XP_INCREMENT3
XP_LEVELS[5] = XP_LEVELS[4] + XP_INCREMENT3
XP_LEVELS[6] = XP_LEVELS[5] + XP_INCREMENT3
XP_LEVELS[7] = XP_LEVELS[6] + XP_INCREMENT3
XP_LEVELS[8] = XP_LEVELS[7] + XP_INCREMENT3
XP_LEVELS[9] = XP_LEVELS[8] + XP_INCREMENT3
XP_LEVELS[10] = XP_LEVELS[9] + XP_INCREMENT3


local LEVEL_CAP = #XP_LEVELS

local PROGRAM_UNLOCK = 1
local AGENT_UNLOCK = 2

local function GetXPPerMission( missionDifficulty, campaignDifficulty )

    local simdefs = include("sim/simdefs")
    local modifier = 1
    if campaignDifficulty == simdefs.NORMAL_DIFFICULTY then
        modifier = 0.5
    end

    if missionDifficulty > #XP_PER_MISSION then
        missionDifficulty = #XP_PER_MISSION
    end

    local xpgained = XP_PER_MISSION[ missionDifficulty ] or 0
    return xpgained * modifier
end

local LEVEL_REWARDS = 
{
	{ 
        unlockType = AGENT_UNLOCK,
        alt = false,
        unlocks = {{ name = 'sharpshooter_1' }, { name = 'stealth_2' } }
    },
    {
        unlockType = PROGRAM_UNLOCK, 
        unlocks = {{ name = 'fusion' }, { name = 'parasite' } }
    },
    {
        unlockType = AGENT_UNLOCK, 
        alt = false,
        unlocks = {{ name = 'engineer_1' }, { name = 'sharpshooter_2' } }
    },
    { 
        unlockType = PROGRAM_UNLOCK, 
        unlocks = {{ name = 'rapier' }, { name = 'seed' } }
    },
    {
        unlockType = AGENT_UNLOCK, 
        alt = false,
        unlocks = {{ name = 'cyborg_1' }, { name = 'disguise_1' } }
    },
    {
        unlockType = AGENT_UNLOCK, 
        alt = true,
        unlocks = {{ name = 'stealth_1_a' }, { name = 'engineer_2_a' } }
    },
    {
        unlockType = AGENT_UNLOCK, 
        alt = true,
        unlocks = {{ name = 'sharpshooter_1_a' }, { name = 'stealth_2_a' } }
    },
    {
        unlockType = AGENT_UNLOCK, 
        alt = true,
        unlocks = {{ name = 'engineer_1_a' }, { name = 'sharpshooter_2_a' } }
    },
    {
        unlockType = PROGRAM_UNLOCK, 
        unlocks = {{ name = 'dynamo' }, { name = 'mercenary' } }
    },
    {
        unlockType = AGENT_UNLOCK, 
        alt = true,
        unlocks = {{ name = 'cyborg_1_a' }, { name = 'disguise_1_a' } }
    },         
} 

local CAMPAIGN_COMPLETE_REWARD = 
{ 
    unlockType = AGENT_UNLOCK,
    alt = false,
    unlocks = {{ name = 'central_pc' }, { name = 'monst3r_pc' } }
}

local CAMPAIGN_COMPLETE_REWARD_2 = 
{ 
    unlockType = PROGRAM_UNLOCK,
    alt = false,
    unlocks = {{ name = 'faust' }, { name = 'brimstone' } }
}

local CAMPAIGN_COMPLETE_UNLOCKS = 
{
    CAMPAIGN_COMPLETE_REWARD,
    CAMPAIGN_COMPLETE_REWARD_2
}

local function GetLevelForXP(xp)
    local last = 0
    for k,v in ipairs(XP_LEVELS) do
        if xp < v then
            local percent = ((xp - last) / (v - last))
            return k-1, percent
        end
        last = v
    end
    --at cap!
    return #XP_LEVELS, 0
end

local function GetXPCap()
    return XP_LEVELS[#XP_LEVELS]
end

local function GetRewardsForTotalXP(xp)
    local level = math.min(GetLevelForXP(xp), LEVEL_CAP)
    
    local rewards = {}
    if level > 0 then
        for k = 1, math.min(level, #LEVEL_REWARDS) do
            table.insert(rewards, LEVEL_REWARDS[k])
        end
    end
    return rewards
end

local function GetRewardForLevel(level)
    level = level + 1
    if level > 0 and level <= #LEVEL_REWARDS then
        return LEVEL_REWARDS[level]
    end
end
    
   -- Returns a pair of <Total XP to level, additional XP needed to next level>
local function GetXPForLevel(level)
    if level == 0 then
        return 0, XP_LEVELS[1]
    end
    if level <= #XP_LEVELS then
        return XP_LEVELS[level], level + 1 <= #XP_LEVELS and (XP_LEVELS[level + 1] - XP_LEVELS[level]) or 0
    end  
end

local function IsCappedXP(xp)
    return xp >= XP_LEVELS[#XP_LEVELS]
end

local DLC_INSTALL_REWARDS = {}
      
local function isRewardUnlocked( name )
    local function findReward( reward )
        return reward.unlocks[1].name == name or reward.unlocks[2].name == name
    end 

    local allunlocks = util.tcopy(LEVEL_REWARDS)
    for _,v in ipairs(CAMPAIGN_COMPLETE_UNLOCKS) do
        table.insert(allunlocks, v)
    end

    -- Is this thing even a reward to be earned?
    local isReward = array.findIf( allunlocks, findReward ) ~= nil
    if not isReward then
        return true -- Not a reward -> unlocked
    end

    local user = savefiles.getCurrentGame()

    local rewards = GetRewardsForTotalXP( user.data.xp or 0 )
    local hasReward = array.findIf( rewards, findReward ) ~= nil

    --look in final rewards
    if user.data.storyExperiencedWins then
        hasReward = hasReward or (array.findIf( CAMPAIGN_COMPLETE_UNLOCKS, findReward ) ~= nil)
    end

--[[
    --look up starting DLC rewards
    if #DLC_INSTALL_REWARDS > 0 then
       for i,reward in ipairs(DLC_INSTALL_REWARDS) do        
            hasReward = hasReward or (array.findIf( reward, findReward ) ~= nil)
       end
    end
]]
    return hasReward
end

function ResetMetaDefs()
    log:write("ResetMetaDefs()")
    util.tclear(DLC_INSTALL_REWARDS)
end

return 
{    
    DLC_INSTALL_REWARDS = DLC_INSTALL_REWARDS,
    XP_INCREMENT1 = XP_INCREMENT1,
    XP_INCREMENT2 = XP_INCREMENT2,
    XP_INCREMENT3 = XP_INCREMENT3,
    PROGRAM_UNLOCK = PROGRAM_UNLOCK,
    AGENT_UNLOCK = AGENT_UNLOCK,

    LEVEL_CAP = LEVEL_CAP,
    XP_LEVELS = XP_LEVELS,
    AGENT_UNLOCK = AGENT_UNLOCK,
    PROGRAM_UNLOCK = PROGRAM_UNLOCK,
	LEVEL_REWARDS = LEVEL_REWARDS,
    CAMPAIGN_COMPLETE_REWARD = CAMPAIGN_COMPLETE_REWARD,
    CAMPAIGN_COMPLETE_REWARD_2 = CAMPAIGN_COMPLETE_REWARD_2,

    GetXPPerMission = GetXPPerMission,
    GetXPCap = GetXPCap,
    GetRewardsForTotalXP = GetRewardsForTotalXP,
    GetRewardForLevel = GetRewardForLevel,
    GetXPForLevel = GetXPForLevel,
    GetLevelForXP = GetLevelForXP,
    IsCappedXP = IsCappedXP,
    isRewardUnlocked = isRewardUnlocked,
}