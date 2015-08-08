----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )

----------------------------------------------------------------

local moviescreen = class()

local function doSubtitles(screen, subs,time)

    local diffTime = MOAISim.getDeviceTime() - time

    for i,sub in ipairs(subs) do
        if diffTime > sub[2] then
        
            local widget = screen:findWidget("subtitle")
            widget:setVisible(true)            
            widget:setText(util.sformat(sub[1]))

            if diffTime > sub[3] then
          
                widget:setText("")
                widget:setVisible(false)
                table.remove(subs,i)
            end 
        end
    end
    return subs
end

----------------------------------------------------------------
function moviescreen:init(moviefile, oncompletefn, subs)
    MOAIFmodDesigner.stopAllSounds()
    --push a mix?

    self.screen = mui.createScreen( "splash-screen.lua" )
    mui.activateScreen( self.screen )
    self.screen.binder.logo:setVisible( false )

    self.screen.binder.movie.onFinished = function() 
        self.done_playing = true 
        FMODMixer:popMix( "nomusic" )
    end
    self.screen.binder.movie:playMovie( moviefile )
    inputmgr.addListener( self, 1 )

    self._routine = MOAICoroutine.new()
    self._routine:run( function() 

    subs= util.tcopy(subs)
    
        local time = MOAISim.getDeviceTime()
        local widget = self.screen:findWidget("subtitle")
        widget:setVisible(false)
        local settings = savefiles.getSettings( "settings" )

        while true do

            if subs and settings.data.showMovieSubtitles then
                subs = doSubtitles(self.screen,subs,time)            
            end 

            if self.done_playing then
                break
            end

            coroutine.yield()
        end

        inputmgr.removeListener( self )
        self.screen.binder.movie:stopMovie()
        mui.deactivateScreen( self.screen )

        if oncompletefn then
            oncompletefn()
        end
    end)

end


function moviescreen:onInputEvent( event )

    if event.eventType == mui_defs.EVENT_KeyUp then
        if util.isKeyBindingEvent( "pause", event ) then
            self.done_playing = true
            return true
        else
            if self.escThread then
                self.escThread:stop()
                self.escThread = nil
            end
            self.screen.binder.escTxt:setVisible(true)
            self.escThread = MOAICoroutine.new()
            self.escThread:run( function()       
                local fade_time = 5
                local t = 0
                while t < fade_time do
                    t = t + 1/cdefs.SECONDS
                    local percent = math.min(1, math.max(0, t / fade_time))
                    self.screen.binder.escTxt:setColor(1, 1, 1, 1 - percent)
                    coroutine.yield()
                end
                self.screen.binder.escTxt:setVisible(false)
                self.escThread:stop()
                self.escThread = nil
            end)
        end
    end
end

return moviescreen
