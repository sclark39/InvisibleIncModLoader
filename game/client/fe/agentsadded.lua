local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local rig_util = include( "gameplay/rig_util" )
local mui_defs = include( "mui/mui_defs" )
local mui = include( "mui/mui" )
local simfactory = include( "sim/simfactory" )
local itemdefs = include("sim/unitdefs/itemdefs")

local agentsadded = class()

local SET_COLOR = {r=244/255,g=255/255,b=120/255, a=1}

function updateItems( agentDef, agentWidget, screen )
    for i, widget in agentWidget.binder:forEach( "item" ) do
        if agentDef.upgrades[i] then
            widget:setVisible(true)

            local unitData = itemdefs[ agentDef.upgrades[i] ]
            local newItem = simfactory.createUnit( unitData, nil )                      
            widget:setImage( unitData.profile_icon )

            local tooltip = util.tooltip( screen )
            local section = tooltip:addSection()
            newItem:getUnitData().onTooltip( section, newItem )
            widget:setTooltip( tooltip )
            widget:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
        else
            widget:setVisible(false)
        end
    end
end

function agentsadded:init( agentDef1, agentDef2, programDef1, programDef2 )
    local screen = mui.createScreen( "modal-agents-added.lua" )
	mui.activateScreen( screen )			

    self.isdone = false

	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/unlock_agent" )

    self.screen = screen
    self.ok_button = screen:findWidget("okBtn.btn")
    self.agent1 = screen:findWidget("agent1")
    self.agent2 = screen:findWidget("agent2")
    self.program1 = screen:findWidget("Program1")
    self.program2 = screen:findWidget("Program2")

    self.ok_button.onClick = function() self:Hide() end 
    self.ok_button:setText(STRINGS.UI.CONTINUE)
    
    inputmgr.addListener( self, 1 )

    self.agent1.binder.agent.binder.agentNameBody:setText(util.toupper(agentDef1.name))
    self.agent1.binder.agent.binder.agentImg:setImage(agentDef1.team_select_img[1])
    updateItems( agentDef1, self.agent1.binder.agent, screen )

    self.agent2.binder.agent.binder.agentNameBody:setText(util.toupper(agentDef2.name))
    self.agent2.binder.agent.binder.agentImg:setImage(agentDef2.team_select_img[1])
    updateItems( agentDef2, self.agent2.binder.agent, screen )

    local populateProgram = function(programWidget, ability)
        local PWRtooltip = STRINGS.UI.TOOLTIPS.TEAM_SELECT_PWR_DESC

        programWidget.binder.programIcon:setImage(ability.icon)     
        programWidget.binder.programName:setText(util.toupper(ability.name))
        programWidget.binder.programTxt:spoolText(ability.desc)
        if ability.cpu_cost > 0 or not ability.passive then
            programWidget.binder.powerTxt:setText(tostring(ability.cpu_cost))
            programWidget.binder.firewallTooltip:setTooltip(PWRtooltip..util.sformat(STRINGS.UI.TOOLTIPS.TEAM_SELECT_PWR, ability.cpu_cost))
        else
            programWidget.binder.powerTxt:setText("-")
            programWidget.binder.firewallTooltip:setTooltip(PWRtooltip..STRINGS.UI.TOOLTIPS.TEAM_SELECT_NOPWR)
        end
    end

    populateProgram(self.program1.binder.Program, programDef1)
    populateProgram(self.program2.binder.Program, programDef2)

end

function agentsadded:IsDone()
    return self.isdone
end

function agentsadded:onInputEvent( event )
    if event.eventType == mui_defs.EVENT_KeyDown then
        if event.key == mui_defs.K_ENTER then
            self:Hide()
            return true

        elseif util.isKeyBindingEvent( "pause", event ) then
            self:Hide()
            return true
        end
    end
end

function agentsadded:Hide(  )
    inputmgr.removeListener( self )

    mui.deactivateScreen( self.screen ) 
    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT ) 
    self.isdone = true
end

return agentsadded
