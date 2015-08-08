local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )


local lastWords = 
	{
		name = STRINGS.ABILITIES.SPRINT,
        canUseWhileDragging = true,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			section:addDesc( STRINGS.ABILITIES.LAST_WORDS_DESC )		
			return tooltip
		end,

		alwaysShow = true,
		iconColor= util.color( 163/255, 0/255, 0/255 )  ,
		iconColorHover= util.color( 1,1,1 )  ,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/actionicon_talk.png",

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.LAST_WORDS
		end,

		acquireTargets = function( self, targets, game, sim, unit )
			return targets.unitTarget( game, { unit }, self, unit, unit )
		end,

		canUseAbility = function( self, sim, unit )
			if sim:getTags().no_last_words then 
				return false 
			end 

            if not simquery.isUnitUnderOverwatch(unit) then
                return false -- Not targetted.
            end

			-- Count agents that can still 'escape' and aren't knocked out.
		 	local unitNums = 0
			for i, unit in pairs( unit:getPlayerOwner():getUnits() ) do
                if unit:hasAbility( "escape" ) and not unit:isKO() then
					unitNums = unitNums + 1					
				end
			end

		 	if unitNums > 1 then
		 		return false
			end

			return true 
		end,
		
        confirmAbility = function( self, sim, ownerUnit )
            return STRINGS.UI.CONFIRMLASTWORDS
        end,

		executeAbility = function( self, sim, sourceUnit )
	        local script = sim:getLevelScript()
            script:clearQueue()
   	     
            local agentDef = sourceUnit:getUnitData()
            local speechSet = sourceUnit:getSpeech()
            local speech = speechSet.FINAL_WORDS[math.floor(sim:nextRand()*#speechSet.FINAL_WORDS)+1]

    	    sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 0.3*cdefs.SECONDS )

            local text =  {{
                text = speech, 
                anim = agentDef.profile_anim,
                build = agentDef.profile_build,
                name = agentDef.name,
                voice = nil,
            }}

            script:queue( { script=text, type="newOperatorMessage" } ) 	
    	    sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 3*cdefs.SECONDS )

			sim:processReactions( sourceUnit )
		end,
	}

return lastWords