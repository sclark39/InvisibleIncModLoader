----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

---------------------------------------------------------------------------
-- Placeholder FX functionality.
-- PLEASE REPLACE THIS ENTIRE FILE IT IS GARBAGE.
---------------------------------------------------------------------------
--
local resources = include( "resources" )
local array = include( "modules/array" )
local util = include( "modules/util" )
include( "class" )
local PRIORITY_FRONTMOST = 100000 -- completelly magic, beyond the iso sorting priorities

---------------------------------------------------------------------------
--

local fxmanager = class()

function fxmanager:init( layer )
	local charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?◊()%&/-\''
	local font = MOAIFont.new ()
	--font:loadFromTTF ( 'data/fonts/calibri.ttf', charcodes, 16, 163 )
	font:loadFromBMFont ( 'data/fonts/font1_12_sb.fnt' )

	self._font = font
	self._layer = layer
	self._fxlist = {}
end

function fxmanager:destroy()
	while #self._fxlist > 0 do
		self:removeFx( self._fxlist[1] )
	end
end

function fxmanager:addAnimFx( args )

	local x, y, z = args.x, args.y, args.z or 0
	local kanim, symbol, anim = args.kanim, args.symbol or "character", args.anim or "idle"
	local loop = args.loop or false
	local scale = args.scale or 0.25  -- why are all anims 4x the size they are used at? I don't know.
	local layer = args.aboveProp or args.belowProp or args.layer or self._layer
	local isAbove = args.aboveProp ~= nil
	local facingMask = args.facingMask or KLEIAnim.FACING_E

	local adef = "data/anims/" .. kanim .. ".adef"
	local abld = "data/anims/" .. kanim .. ".abld"
	KLEIResourceMgr.LoadResource( adef )
	KLEIResourceMgr.LoadResource( abld )
	
	local prop = KLEIAnim.new()
	prop:bindBuild( KLEIResourceMgr.GetResource( abld ) )
	prop:bindAnim( KLEIResourceMgr.GetResource( adef ) )
	prop:setCurrentSymbol( symbol )
	prop:setCurrentAnim( anim )
	prop:setCurrentFacingMask(facingMask)
	prop:setLoc(x, y, z)
	prop:setBillboard( MOAIProp.FLAGS_QUASI_BILLBOARD )
	prop:setDepthTest( false )
	prop:setDepthMask( false )
	prop:setScl( scale, scale, scale )

	if args.color then		
		for i,modulate in ipairs(args.color) do
			prop:setSymbolModulate(modulate.symbol, modulate.r, modulate.g, modulate.b, modulate.a)
		end
	end
		
	if loop then
		prop:setPlayMode( KLEIAnim.LOOP )
	else
		prop:setPlayMode( KLEIAnim.ONCE )
	end

	layer:insertProp( prop, isAbove )

	local fx =
	{
		_done = false,
		_prop = prop,
		_layer = layer,

		update = function( self )
            if self._done and self.onFinished then
                self.onFinished( anim )
            end
			return self._done == false
		end,

		setLoc = function( self, x, y )
			self._prop:setLoc( x, y )
		end,

		setScl = function( self, scl )
			self._prop:setScl( scl, scl, scl )
		end,

        setSymbolModulate = function( self, symbolName, r, g, b, a )
            self._prop:setSymbolModulate( symbolName, r, g, b, a )
        end,

		postLoop = function( self, postAnim )
			self._prop:setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim )
                    self._prop:setCurrentAnim( postAnim )
                    self:setLoop( false )
                end )
        end,

		getProp = function( self )
			return self._prop
        end,        

		setLoop = function( self, isLoop )
			if isLoop then
				self._prop:setListener( KLEIAnim.EVENT_ANIM_END, nil )
			else
        		self._prop:setPlayMode( KLEIAnim.ONCE )
				self._prop:setListener( KLEIAnim.EVENT_ANIM_END,
					function( anim )
                        self._done = true
                    end )
			end
		end,

		destroy = function( self )
			self._layer:removeProp(self._prop,args.above)
			KLEIResourceMgr.UnloadResource( abld )
			KLEIResourceMgr.UnloadResource( adef )
		end
	}

	fx:setLoop( loop )

	table.insert( self._fxlist, fx )
	return fx
end

function fxmanager:addLabel( str, x, y, z, color )

	local prop = MOAITextBox.new()
	prop:setRect( -200, -200, 200, 200 ) --64
	prop:setString( str )
	prop:setFont( self._font )
	prop:setAlignment( MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY )
	prop:setTextSize( 12, 112 ) --10, 112
	if color then
		prop:setColor(  color.r, color.g, color.b, color.a ) 
	else
		prop:setColor(  1, 1, 1, 1 ) 
	end
	prop:setScl(0.4,0.4,0.4)
	prop:setYFlip ( true )
	prop:setBillboard( true )
	prop:setLoc( x, y, z )
	prop:setPriority( PRIORITY_FRONTMOST )	
	
	self._layer:insertProp ( prop )

	local fx =
	{
		_prop = prop,
		_layer = self._layer,
		
		update = function( self )		
			return self._prop ~= nil
		end,

		setString = function( self, str )
			self._prop:setString( str )
		end,

		destroy = function( self )
			if self._prop then
				self._layer:removeProp(self._prop)
				self._prop = nil
			end
		end
	}

	table.insert( self._fxlist, fx )

	return fx
end


function fxmanager:addSpeechLabel( x, y, text ,duration,white, z, ts )

	local prop = MOAITextBox.new()
	prop:setRect( -44, -64, 200, 64 )
	prop:setString(string.format(text))
	prop:setFont( self._font )
	prop:setAlignment( MOAITextBox.LEFT_JUSTIFY, MOAITextBox.CENTER_JUSTIFY )
	prop:setTextSize( ts or 8,50 )
	prop:setScl(0.4,0.4,0.4)
	prop:setColor( 1, 0, 0, 1 ) 
	if white == true then
		prop:setColor(  1, 1, 1, 1 ) 
	end
	prop:setYFlip ( true )
	prop:setBillboard( true )
	prop:setLoc( x, y, z+20 )		
	prop:setPriority( PRIORITY_FRONTMOST )

	local imgProp = MOAIProp.new ()
	imgProp:setBlendMode( MOAIProp.BLEND_NORMAL )
	imgProp:setDeck( resources.find( "Speech" ) )
	imgProp:setLoc( x, y, z )
	imgProp:setScl(0.4,-0.4,0.4)
	imgProp:setBillboard( true )
	imgProp:setPriority( PRIORITY_FRONTMOST - 1 )
	
	self._layer:insertProp ( prop )	
	self._layer:insertProp ( imgProp )

	local fx =
	{
		_prop = prop,		
		_propImg = imgProp,		
		_layer = self._layer,
		_duration = duration * 60,

		update = function( self )
			self._duration = self._duration - 1
			return self._duration > 0
		end,

		destroy = function( self )
			self._layer:removeProp(self._prop)
			self._layer:removeProp(self._propImg)
		end
	}

	table.insert( self._fxlist, fx )

	return fx
end

function fxmanager:addFloatLabel( x, y, text ,duration,color, z, ts, target )

	local prop = MOAITextBox.new()
	prop:setRect( -64, -64, 64, 64 )
	prop:setString(string.format(text))
	prop:spool()
	prop:setFont( self._font )
	prop:setAlignment( MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY )
	prop:setTextSize( ts or 10, 112 )
	--prop:setTextSize( ts or 12, 72 )
	prop:setColor( 1, 0, 0, 1 ) 

	if color then
		if color == true then
			prop:setColor(  1, 1, 1, 1 ) 
		else
			prop:setColor(  color.r, color.g, color.b, color.a ) 
		end
	end
	prop:setYFlip ( true )
	prop:setBillboard( true )
	prop:setLoc( x, y, z or 0 )
		
	self._layer:insertProp ( prop )

	local fx =
	{
		_prop = prop,		
		_layer = self._layer,
		_duration = duration * 60,

		update = function( self )
			self._duration = self._duration - 1
			return self._duration > 0
		end,

		destroy = function( self )
			self._layer:removeProp(self._prop)
		end
	}

	local easeDuration = math.max( 1, duration - 2 )
	if target then
		prop:seekLoc( target.x, target.y, (z or 0), easeDuration, MOAIEaseType.SHARP_EASE_IN )
	else
		prop:seekLoc( x, y, (z or 0) + 20, easeDuration, MOAIEaseType.SHARP_EASE_IN )
	end
	prop:seekScl( 0.5, 0.5, 0.5, easeDuration, MOAIEaseType.SHARP_EASE_IN )

	table.insert( self._fxlist, fx )

	return fx
end


function fxmanager:widgetFlyTxt( x0, y0, x1, y1, text ,duration, screen, scale, color, sound, soundDelay)

	local widget = screen:createFromSkin( "flying_text" )
	
	screen:addWidget( widget )
	widget:setPosition(x0,y0+0.02)
	widget.binder.txt:setText(text)	

	if color then
		widget.binder.txt:setColor(color.r,color.g,color.b,color.a)	
	end


	if not scale then
		scale = 1
	end 

	local easeDuration = math.max( 3, duration )

	local fx =
	{
		_widget = widget,
		_screen = screen,	
		_duration = duration  * 60,
		_timer = 0,
		_stage1 = 90, 
	
		_x1 = x1, 
		_y1 = y1, 

		update = function( self )
			self._timer = self._timer + 1

			if soundDelay then
				if self._timer == math.floor(soundDelay*60) then
					MOAIFmodDesigner.playSound(sound)
				end
			end
			if self._stage1 ~= true and self._timer > self._stage1 then
				self._stage1 = true
				widget:seekLoc( x1, y1, easeDuration, MOAIEaseType.SHARP_EASE_IN )
				widget:seekScl( scale, scale, scale,  easeDuration, MOAIEaseType.SHARP_EASE_IN )

				if not color then
					color = util.color.WHITE
				end

				widget.binder.txt:seekColor( color.r,color.g,color.b,0,  easeDuration, MOAIEaseType.SHARP_EASE_IN )
			end

			self._duration = self._duration - 1
			return self._duration > 0			
		end,

		destroy = function( self )
			self._screen:removeWidget( self._widget )
		end
	}

	table.insert( self._fxlist, fx )

	widget:seekLoc( x0, y0+0.05, easeDuration, MOAIEaseType.SHARP_EASE_IN )
--	widget:seekScl( scale, scale, scale,  easeDuration, MOAIEaseType.SHARP_EASE_IN )

	return fx
end


function fxmanager:widgetFlyImage( x0, y0, x1, y1, duration, screen, imgName )

	local widget = screen:createFromSkin( "flying_image" )
	
	screen:addWidget( widget )
	widget:setPosition(x0,y0)

	if imgName then
		widget.binder.img:setImage(imgName)
	end

	local fx =
	{
		_widget = widget,
		_screen = screen,	
		_duration = duration  * 60,
		_timer = 0,
	
		_x1 = x1, 
		_y1 = y1, 

		update = function( self )		
			self._duration = self._duration - 1
			return self._duration > 0			
		end,

		destroy = function( self )
			self._screen:removeWidget( self._widget )
		end
	}

	table.insert( self._fxlist, fx )

	widget:seekLoc( x1, y1, duration, MOAIEaseType.LINEAR )

	return fx
end




function fxmanager:updateFx()

	for i = #self._fxlist,1,-1 do
		local fx = self._fxlist[i]

		if not fx:update() then
			fx:destroy()
			table.remove( self._fxlist, i )
		end
	end
end

function fxmanager:removeFx( fx )
	local idx = array.find( self._fxlist, fx )
	assert( idx )

	fx:destroy()
	table.remove( self._fxlist, idx )
end

function fxmanager:containsFx( fx )
	return array.find( self._fxlist, fx ) ~= nil
end

return fxmanager
