local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local rig_util = include( "gameplay/rig_util" )
local mui_defs = include( "mui/mui_defs" )


local talkinghead_ingame = class()

function talkinghead_ingame:init( widget, ismainframefn )
    self.widget = widget
    self.isdone = true
    self.ismainframefn = ismainframefn
end

function talkinghead_ingame:shouldShowSubtitles()
    local user = savefiles.getSettings( "settings" )
    return user.data.showSubtitles
end

function talkinghead_ingame:PlayScript(script)
    self.isdone = false
    self:Stop()

    if not script or #script == 0 then
        return
    end

    self.widget:setVisible(true)
    self.script = script
    self:ShowLine(1)
end

function talkinghead_ingame:TryResume(  )
    if not self.isdone and (self:shouldShowSubtitles() or not self.line.voice) and (not self.ismainframefn or not self.ismainframefn()) then 
        if self.widget:hasTransition() then
            self.should_reshow = true
        else
            self.widget:setVisible(true)
            self.widget:createTransition( "activate_left" )
        end
    end
end


function talkinghead_ingame:Hide(  )
    self.widget:createTransition( "deactivate_left",
        function( transition )
            self.widget:setVisible( false )
            if self.should_reshow and not self.ismainframefn or not self.ismainframefn() then
                self:TryResume()
                self.should_reshow = false
            end
        end,
     { easeOut = true } )       
end


function talkinghead_ingame:Halt(  )
    if not self.isdone then
        self:Stop()
        self.widget:createTransition( "deactivate_left",
            function( transition )
                 self.widget:setVisible( false )
            end,
         { easeOut = true } )      

        if self.onfinished then
            self.onfinished()
        end
        self.isdone = true
    end
end

function talkinghead_ingame:CentralSays(text, voice)
    self:PlayScript{ {text = text, anim = "portraits/central_face", name = STRINGS.UI.CENTRAL_TITLE, voice = voice} }
end

function talkinghead_ingame:Stop()
    self:StopLine()
    if self._scriptThread then
        self._scriptThread:stop()
        self._scriptThread = nil
    end
    
end
function talkinghead_ingame:StopLine()
    MOAIFmodDesigner.stopSound("talkinghead_voice")
    MOAIFmodDesigner.stopSound("talkinghead_type")
    if self._typeThread then
        self._typeThread:stop()
        self._typeThread = nil
    end
end


function talkinghead_ingame:IsDone()
    return self.isdone
end

function talkinghead_ingame:setOnFinishedFn(fn)
    self.onfinished = fn
end

function talkinghead_ingame:ShowLine(idx)
    self.line_idx = idx
    
    if self._scriptThread then
        self._scriptThread:stop()
        self._scriptThread = nil
    end

    self:StopLine(self)

    local line = self.script[idx]
    self.line = line

    local was_viz = self.widget:isVisible()
    if (self:shouldShowSubtitles() or not line.voice) and (not self.ismainframefn or not self.ismainframefn()) then 
        self.widget:setVisible(true)
    else 
        self.widget:setVisible(false)
    end

    --play the voice
    local playing_voice = false
    if line.voice then
        MOAIFmodDesigner.playSound(line.voice, "talkinghead_voice")
        playing_voice = MOAIFmodDesigner.isPlaying("talkinghead_voice")
    else        
        MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/Operator/textbox" )        
    end

    if self.widget:isVisible() and (not was_viz or line.anim ~= self.talking_head_anim or self.line_idx == 1) and not self.widget:hasTransition() then
        self.widget:createTransition( "activate_left" )
    end
    self.talking_head_anim = line.anim

    --set up the talker and the talker's name
    self.widget.binder.profileAnim:bindBuild(line.build or line.anim)
    self.widget.binder.profileAnim:bindAnim(line.anim)
    if line.name then
        self.widget.binder.headerTxt:setText(line.name .. ":")
    else
        self.widget.binder.headerTxt:setText("")
    end

    --spool text and play a typing sound
    local textLength = string.len( string.gsub( string.gsub(line.text, " ", "" ), "\n", "") ) 
    self.widget.binder.bodyTxt:spoolText(line.text, line.voice and 30 or 60)
    self._typeThread = MOAICoroutine.new()
    local txt= self.widget.binder.bodyTxt 
    self._typeThread:run( function() 
        while txt:isSpooling() do
            coroutine.yield()
        end
        self._typeThread = nil
    end )


    --if we are playing a voice, auto-advance the dialog when it ends.
    if self.line_idx < #self.script then
        self._scriptThread = MOAICoroutine.new()
        self._scriptThread:run( function() 
            
            if playing_voice then
                while MOAIFmodDesigner.isPlaying( "talkinghead_voice" ) do
                    coroutine.yield()
                end
                rig_util.wait( .2 * cdefs.SECONDS)
            else
                rig_util.wait( (line.timing or 5) * cdefs.SECONDS)
            end
            

            self:ShowLine(self.line_idx + 1)
        end)

    elseif self.line_idx >= #self.script then  
        self._scriptThread = MOAICoroutine.new()
        self._scriptThread:run( function() 
            if playing_voice then
                while MOAIFmodDesigner.isPlaying( "talkinghead_voice" ) do
                    coroutine.yield()
                end
                rig_util.wait( .2 * cdefs.SECONDS)
                if self.onfinished then
                    self.onfinished()
                end
            else
                rig_util.wait( (line.timing or 5) * cdefs.SECONDS)
            end
            self:Halt()
            self.isdone = true
        end)
    end 

end

return talkinghead_ingame
