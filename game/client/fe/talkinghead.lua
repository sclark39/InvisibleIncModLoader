local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local rig_util = include( "gameplay/rig_util" )
local mui_defs = include( "mui/mui_defs" )
local mui = include( "mui/mui" )

------------------------------------------------------------------
-- A head that talks in a modal dialog. Quaint.

local talkinghead = class()

function talkinghead:init( screen, widget, init_delay )
    
    self.do_init_delay = init_delay
    self.widget = widget
    if screen then
        self.screen = screen
        screen.onInputEvent = function( ev ) return self:onInputEvent( ev ) end
    end


    self.skip_button = widget:findWidget("skipBtn")

    self.next_button = widget:findWidget("nextBtn")
    self.prev_button = widget:findWidget("prevBtn")

    self.profile = widget:findWidget("profileAnim")
    self.profileImg = widget:findWidget("profileImg")

    self.body_text = widget:findWidget("bodyTxt")
    self.name = widget:findWidget("bodyTxtCentral")

    if self.skip_button then
        self.skip_button.onClick = function() self:OnClickSkip() end 
    end


    if self.next_button then
        self.next_button.onClick = function() self:OnClickNext() end 
    end
    
    if self.prev_button then
        self.prev_button.onClick = function() self:OnClickPrev() end 
    end
end

function talkinghead:FadeBackground( fade_ticks )
	local bg = self.screen:findWidget("bg")
	for k = 1, fade_ticks do
		bg:setColor(0,0,0,(k/fade_ticks)*.5)
		coroutine.yield()
	end
end

function talkinghead:onInputEvent( event )
    if event.eventType == mui_defs.EVENT_KeyDown and util.isKeyBindingEvent( "pause", event ) then
        self:Hide()
        return true
    end
end

function talkinghead:PlayScript(script)
    self:Stop()

    if not script or #script == 0 then
        return
    end

    self.script = script
    self:ShowLine(1)
end

function talkinghead:OnClickSkip()
    self:Hide()
end

function talkinghead:OnClickNext()
    if self.script == nil then
        return -- Multi-click after hiding, bail.
    end
    if self.body_text:isSpooling() then
        self.body_text:spoolText(self.body_text:getText(), 9999)
    else
        if self.line_idx == #self.script then
            self:Hide()
        else
            self:ShowLine(self.line_idx + 1)
        end
    end
end

function talkinghead:OnClickPrev()
    if self.script == nil then
        return -- Multi-click after hiding, bail.
    end
    self.line_idx = math.max(1, self.line_idx - 1 )
    self:ShowLine(self.line_idx, true)
end

function talkinghead:Hide(  )
    self:Stop()
    if self.next_button then
        self.next_button:blink( 0 )
    end
    self.script = nil
end

function talkinghead:Stop()
    MOAIFmodDesigner.stopSound("talkinghead_voice")
    MOAIFmodDesigner.stopSound("talkinghead_type")
    if self._typeThread then
        self._typeThread:stop()
        self._typeThread = nil
    end
    
    if self._scriptThread then
        self._scriptThread:stop()
        self._scriptThread = nil
    end
end

function talkinghead:IsDone()
    return self.script == nil
end

function talkinghead:ShowLine(idx, immediateMode)
    self.line_idx = idx
    
    if self.next_button then
        self.next_button:setText(idx == #self.script and STRINGS.UI.OK or STRINGS.UI.NEXT) --localize me!
    end
    
    if self.prev_button then
        self.prev_button:setText(STRINGS.UI.PREV)
        self.prev_button:setVisible(idx > 1) 
    end

    
    self:Stop()

    if idx < #self.script then
        if self.next_button then
            self.next_button:blink( 0 )
        end
    end

    local line = self.script[idx]
    self.line = line

    --play the voice
    local playing_voice = false

    if not self.notransitions and (line.anim ~= self.talking_head_anim or self.line_idx == 1) then
        self.widget:createTransition( "activate_left" )
    end
    self.talking_head_anim = line.anim

    --set up the talker and the talker's name
    if self.profile and line.anim then
        if self.profileImg then
            self.profileImg:setVisible(false) 
        end

        self.profile:setVisible(true) 
        self.profile:bindBuild(line.anim)
        self.profile:bindAnim(line.anim)    
    end

    if self.profileImg and line.img then
        if self.profile then
            self.profile:setVisible(false) 
        end

        self.profileImg:setVisible(true) 
        self.profileImg:setImage(line.img) 
    end

    if line.name then
        self.name:setText(line.name .. ":")
    else
        self.name:setText("")
    end




    --spool text and play a typing sound
    local textLength = string.len( string.gsub( string.gsub(line.text, " ", "" ), "\n", "") ) 

    local function dotextspool()

        if immediateMode then    
            self.body_text:spoolText(line.text, 9999)
        else
            self.body_text:spoolText(line.text, line.voice and 30 or 60)
            MOAIFmodDesigner.playSound("SpySociety/HUD/menu/text_print_2_LP", "talkinghead_type")   
            self._typeThread = MOAICoroutine.new()
            local txt= self.body_text
            self._typeThread:run( function() 
                while txt:isSpooling() do
                    coroutine.yield()
                end
                MOAIFmodDesigner.stopSound("talkinghead_type")
                self._typeThread = nil
            end )
        end
    end


    --if we are playing a voice, auto-advance the dialog when it ends. If no voice, the player will just have to click next
    if line.voice then
        self._scriptThread = MOAICoroutine.new()
        self._scriptThread:run( function() 

            if self.line_idx == 1 and self.do_init_delay then
                rig_util.wait( .3 * cdefs.SECONDS)
            end

            dotextspool()
            MOAIFmodDesigner.playSound(line.voice, "talkinghead_voice")

            while MOAIFmodDesigner.isPlaying( "talkinghead_voice" ) or MOAIFmodDesigner.isPlaying( "talkinghead_type" ) do
                coroutine.yield()
            end

            if line.delay then
                rig_util.wait( line.delay * cdefs.SECONDS )
            end

            if self.line_idx < #self.script then
                self:ShowLine(self.line_idx + 1)
            else
                if self.next_button then
                    self.next_button:blink( 0.2, 2, 2, {r=1,g=1,b=1,a=1} )
                end
            end
        end)

    else
        dotextspool()
    end

end

return talkinghead
