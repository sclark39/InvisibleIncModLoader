----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simactions = include( "sim/simactions" )

-----------------------------------------------------------------
-- Any strings used in actions need to be specified below so that
-- they can be represented as a single byte.

local STRING_VALS =
{
	END = 0,

	moveAction = 1,
	useDoorAction = 2,
	abilityAction = 3,
	mainframeAction = 4,
	endTurnAction = 5,
	triggerAction = 6,
	debugAction = 7,
	buyItem = 8,
	sellItem = 9,
	sellAbility = 10,
	transferItem = 11,
	lootItem = 12,
    rewindAction = 13,
    abortMission = 14,
    resignMission = 15,

    -- buy item
    item = 20,
    weapon = 21,
    augment = 22,

    -- mainframeAction
    breakIce = 30,
    use = 31,

    -- campaign strings
    template = 99,
    id = 100,
    upgrades = 101,
    upgradeName = 102,
    upgradeParams = 103,
    installed = 104,
    augment = 105,
    autoEquip = 106,
    skillID = 107,
    level = 108,
    skills = 109,
    lvl_procgen = 110,
    situationName = 111,
    miniserversSeen = 112,
    missionCount = 113,
    tags = 114,
    campaignHours = 115,
    levelFile = 116,
    music = 117,
    foundPrisoner = 118,
    difficulty = 119,
    agency = 120,
    NORMAL = 121,
    uiEvent = 122,
    eventData = 123,
    name = 124,
    campaignDifficulty = 125,
    unitDefsPotential = 126,
    traits = 127,
    missions_completed_1 = 128,
    missions_completed_2 = 129,
    missions_completed_3 = 130,
    missions_completed = 131,
    scripts = 132,
}

local function indexDifficultyOptions()
    local j = 156
    for optionName, v in pairs(simdefs.DIFFICULTY_OPTIONS[1] ) do
        STRING_VALS[ optionName ] = j
        j = j + 1
    end

    local agentdefs = include( "sim/unitdefs/agentdefs" )
    for name, v in pairs(agentdefs) do
        STRING_VALS[ name ] = j
        j = j + 1
    end

    assert( j < 255, j )
end

indexDifficultyOptions()

local TYPE_NIL = 0 
local TYPE_STRING = 2
local TYPE_BOOLEAN = 3
local TYPE_CELL = 4
local TYPE_TABLE = 5
local TYPE_RAW_STRING = 6
local TYPE_DOUBLE = 7

-----------------------------------------------------------------
-- Binary packer; wrapper around KLEILuaStruct.

local packer = class()
function packer:init()
	self.data = {}
end

function packer:packVal( val )
	if type(val) == "nil" then
		self:packByte( TYPE_NIL )
	elseif type(val) == "number" then
        self:packByte( TYPE_DOUBLE )
        self:packDouble( val )
	elseif type(val) == "string" then
        if STRING_VALS[ val ] then
		    self:packByte( TYPE_STRING )
		    self:packStr( val )
        else
            self:packByte( TYPE_RAW_STRING )
            self:packRawStr( val )
        end
	elseif type(val) == "boolean" then
		self:packByte( TYPE_BOOLEAN )
		self:packBool( val )
	elseif type(val) == "table" and type(val[1]) == "number" and type(val[2]) == "number" then
        self:packByte( TYPE_CELL )
        self:packByte( val[1] )
        self:packByte( val[2] )
    elseif type(val) == "table" then
        self:packByte( TYPE_TABLE )
        self:packTable( val )
    else
		assert( false, util.stringize(val) ) -- Not supported
	end
end

function packer:packTable( t )
    for k, v in pairs(t) do
        self:packVal(k)
        self:packVal(v)
    end
    self:packVal( nil ) -- Sentinel
end

function packer:packByte( val )
	assert( val >= 0 and val <= 255 )
	table.insert( self.data, struct.pack( "B", val ))
end

function packer:packBool( val )
	table.insert( self.data, struct.pack( "B", val and 1 or 0 ))
end

function packer:packDouble( val )
	table.insert( self.data, struct.pack( "d", val ))
end

function packer:packShort( val )
	assert( val > -2^15 and val < 2^15 )
	table.insert( self.data, struct.pack( "h", val ))
end

function packer:packInt( val )
	table.insert( self.data, struct.pack( "I", val ))
end

function packer:packStr( val )
    assert( STRING_VALS[ val ] )
	table.insert( self.data, struct.pack( "B", STRING_VALS[ val ] ))
end

function packer:packRawStr( val )
    table.insert( self.data, struct.pack( "hc0", val:len(), val ))
end

function packer:unpackVal( val )
	local packType = self:unpackByte()
	if packType == TYPE_NIL then
		return nil
	elseif packType == TYPE_DOUBLE then
		return self:unpackDouble()
	elseif packType == TYPE_STRING then
		return self:unpackStr()
    elseif packType == TYPE_RAW_STRING then
        return self:unpackRawStr()
	elseif packType == TYPE_BOOLEAN then
		return self:unpackBool()
    elseif packType == TYPE_CELL then
        local x = self:unpackByte()
        local y = self:unpackByte()
        return { x, y }
    elseif packType == TYPE_TABLE then
        return self:unpackTable()
	else
		assert( false ) -- Not supported
	end
end

function packer:unpackByte()
	local val, i = struct.unpack( "B", self.decodeData, self.decodeIndex )
	self.decodeIndex = i
	return tonumber(val)
end

function packer:unpackBool()
	local val, i = struct.unpack( "B", self.decodeData, self.decodeIndex )
	self.decodeIndex = i
	return val ~= 0 and true or false
end

function packer:unpackDouble( val )
	local val, i = struct.unpack( "d", self.decodeData, self.decodeIndex )
	self.decodeIndex = i
	return tonumber(val)
end

function packer:unpackShort()
	local val, i = struct.unpack( "h", self.decodeData, self.decodeIndex )
	self.decodeIndex = i
	return tonumber(val)
end

function packer:unpackInt( val )
	local val, i = struct.unpack( "I", self.decodeData, self.decodeIndex )
	self.decodeIndex = i
	return tonumber(val)
end


function packer:unpackStr()
	local val, i = struct.unpack( "B", self.decodeData, self.decodeIndex )
	self.decodeIndex = i
	return util.indexOf( STRING_VALS, val )
end

function packer:unpackRawStr()
    local val, i = struct.unpack( "hc0", self.decodeData, self.decodeIndex )
    self.decodeIndex = i
    return val
end

function packer:unpackTable()
    local t = {}
    while true do
        local k = self:unpackVal()
        if k == nil then
            break
        end
        local v = self:unpackVal()
        t[k] = v
    end
    return t
end

function packer:encode()
	return MOAIDataBuffer.base64Encode( MOAIDataBuffer.deflate( table.concat( self.data ) ))
end

function packer:decode( str )
	assert( str )
	self.decodeData = MOAIDataBuffer.inflate( MOAIDataBuffer.base64Decode( str ))
	self.decodeIndex = 1
	return self
end


------------------------------------------------------------------
-- Custom packer/unpackers for all sim actions

function simactions.triggerAction_pack( p, triggerType, triggerData )
	assert( #triggerData == 1 or #triggerData == 0 )
	p:packByte( triggerType )
	p:packByte( triggerData.uiEvent )
	p:packVal( triggerData.eventData )
end

function simactions.triggerAction_unpack( p, triggerType, triggerData )
	triggerType = p:unpackByte()
	triggerData = { uiEvent = p:unpackByte() }
	triggerData.eventData = p:unpackVal()
	return { triggerType, triggerData }
end


function simactions.moveAction_pack( p, unitID, moveTable )
	p:packShort( unitID )
    local x, y = moveTable[1].x, moveTable[1].y
    p:packByte( x )
    p:packByte( y )
	p:packByte( #moveTable )
    for i = 2, #moveTable do
        local v = moveTable[i]
        local dir = simquery.getDirectionFromDelta( v.x - x, v.y - y )
        p:packByte( dir )
        x, y = v.x, v.y
	end
end

function simactions.moveAction_unpack( p, unitID, moveTable )
	unitID = p:unpackShort()
	moveTable = {}
    local x = p:unpackByte()
    local y = p:unpackByte()
	local n = p:unpackByte()
    table.insert( moveTable, { x = x, y = y } )
	for i = 2, n do
        local dir = p:unpackByte()
        local dx, dy = simquery.getDeltaFromDirection( dir )
        assert( dx and dy, dir )
        x, y = x + dx, y + dy
		table.insert( moveTable, { x = x, y = y })
	end
	return { unitID, moveTable }
end

function simactions.useDoorAction_pack( p, exitOp, unitID, x0, y0, facing )
	p:packByte( exitOp )
	p:packShort( unitID )
	p:packByte( x0 )
	p:packByte( y0 )
	p:packByte( facing )
end

function simactions.useDoorAction_unpack( p, exitOp, unitID, x0, y0, facing )
	exitOp = p:unpackByte()
	unitID = p:unpackShort()
	x0 = p:unpackByte()
	y0 = p:unpackByte()
	facing = p:unpackByte()
	return { exitOp, unitID, x0, y0, facing }
end

function simactions.abilityAction_pack( p, ownerID, userID, abilityIdx, ... )
	p:packShort( ownerID )
	p:packShort( userID )
	p:packByte( abilityIdx )
	p:packByte( #{...} )
	for i, v in ipairs({...}) do
		p:packVal( v )
	end
end

function simactions.abilityAction_unpack( p, ownerID, userID, abilityIdx, ... )
	ownerID = p:unpackShort()
	userID = p:unpackShort()
	abilityIdx = p:unpackByte()
	local action = { ownerID, userID, abilityIdx }
	local n = p:unpackByte()
	for i = 1, n do
		table.insert( action, p:unpackVal() )
	end
	return action
end

function simactions.mainframeAction_pack( p, updates )
	p:packStr( updates.action )
	p:packShort( updates.unitID )
	if updates.action == "use" then
		p:packStr( updates.fn )
	end
end

function simactions.mainframeAction_unpack( p, updates )
	updates = {}
	updates.action = p:unpackStr()
	updates.unitID = p:unpackShort()
	if updates.action == "use" then
		updates.fn = p:unpackStr()
	end
	return { updates }
end

function simactions.lootItem_pack( p, unitID, itemID )
	p:packShort( unitID )
	p:packShort( itemID )
end

function simactions.lootItem_unpack( p, unitID, itemID )
	unitID = p:unpackShort()
	itemID = p:unpackShort()
	return { unitID, itemID }
end

function simactions.buyItem_pack( p, unitID, shopUnitID, itemIndex, discount, itemType, buyback )
	p:packByte( unitID - 1000 )
	p:packShort( shopUnitID )
	p:packByte( itemIndex )
	p:packDouble( discount )
	p:packStr( itemType )
	p:packBool( buyback )
end

function simactions.buyItem_unpack( p, unitID, shopUnitID, itemIndex, discount, itemType, buyback )
	unitID = p:unpackByte() + 1000
	shopUnitID = p:unpackShort()
	itemIndex = p:unpackByte()
	discount = p:unpackDouble()
	itemType = p:unpackStr()
	buyback = p:unpackBool()
	return { unitID, shopUnitID, itemIndex, discount, itemType, buyback }
end

function simactions.sellItem_pack( p, unitID, shopUnitID, itemIndex )
	p:packByte( unitID - 1000 )
	p:packShort( shopUnitID )
	p:packByte( itemIndex )
end

function simactions.sellItem_unpack( p, unitID, shopUnitID, itemIndex )
	unitID = p:unpackByte() + 1000
	shopUnitID = p:unpackShort()
	itemIndex = p:unpackByte()
	return { unitID, shopUnitID, itemIndex }
end

function simactions.sellAbility_pack( p, index )
	p:packByte( index )
end

function simactions.sellAbility_unpack( p, index )
	index = p:unpackByte()
	return { index }
end

function simactions.transferItem_pack( p, unitID, targetID, itemIndex )
	p:packShort( unitID )
	p:packShort( targetID )
	p:packByte( itemIndex )
end

function simactions.transferItem_unpack( p, unitID, targetID, itemIndex )
	unitID = p:unpackShort()
	targetID = p:unpackShort()
	itemIndex = p:unpackByte()
	return { unitID, targetID, itemIndex }
end

function simactions.rewindAction_pack( p, rewindsLeft )
	p:packByte( rewindsLeft )
end

function simactions.rewindAction_unpack( p, rewindsLeft )
	rewindsLeft = p:unpackByte()
	return { rewindsLeft }
end

function simactions.abortMission_pack( p )
end
function simactions.abortMission_unpack( p )
	return {}
end

function simactions.resignMission_pack( p )
end
function simactions.resignMission_unpack( p )
	return {}
end

function simactions.endTurnAction_pack( p )
end
function simactions.endTurnAction_unpack( p )
	return {}
end

local function packActions( params, simHistory )
	local pk = packer()
    pk:packTable( params )
	for k, v in pairs(simHistory) do
		pk:packStr( v.name )
		assert( simactions[ v.name.."_pack" ], v.name)
		simactions[ v.name.."_pack" ]( pk, unpack(v) )
	end
	-- Sentinel.
	pk:packStr( "END" )
	local s = pk:encode()
	print( #simHistory .. " actions took " ..#s.. " base64 digits:", s )
	return s
end

local function unpackActions( str )
	local pk = packer()
	pk:decode( str )

    local params = pk:unpackTable()

	local actions = {}
	while true do
		local actionName = pk:unpackStr()
		if simactions[ actionName.."_unpack" ] == nil then
			break
		end
		local action = simactions[ actionName.."_unpack" ]( pk )
		action.name = actionName
		table.insert( actions, action )
	end
	
	return params, actions
end

return
{
	packActions = packActions,
	unpackActions = unpackActions
}
