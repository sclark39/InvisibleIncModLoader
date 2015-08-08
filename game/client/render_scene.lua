include( "class" )

local KLEIRenderSceneClass = class()

local function smootherstep( edge0, edge1, t )
	if (t <= edge0) then
		return 0.0
	elseif t >= edge1 then
		return 1.0
	else
		t = (t - edge0) / (edge1 - edge0)
		return t*t*t*(t*(t*6 - 15) + 10)
	end
end

function KLEIRenderSceneClass:init()
    
    local settings = savefiles.getSettings( "settings" ).data

	--Render tables
	self._gameTbl = {}
	self._hudTbl = {}
	self._mouseCursor = {}
	--Render parameters
    self._GausianBlur = settings.enableBloom and 1.0 or 0
	self._DaltonizationType = 0
	self._UIEasePulseTimers = {}

	self.easeDriver = function()
		local ease = 0
		for i,timer in ipairs( self._UIEasePulseTimers ) do
			--controls the ease-in and ease-out of the pulse
			local pp = timer:getTime()
			local pl = timer:getPeriod()
			--local  ramp = math.min( 1.0, 1.0 - math.pow( math.cos( 2 * math.pi * pp / pl ), 3.0) );
			--local ramp = math.cos( 10*2*math.pi * pp / pl )/2 + 0.5
			local ramp = smootherstep( 0.0, 1.0, pp/pl )
			ease = ease + ramp
		end
		ease = math.min( ease, 1.0 )
		self._Stage1PP._pp:getUniforms():setUniformFloat( 'ease', ease )
	end

	self.easeFinishedFunc = function( timer, executed )
		for i,v in ipairs(self._UIEasePulseTimers) do
			if v == timer then
				table.remove( self._UIEasePulseTimers, i )
				if #self._UIEasePulseTimers == 0 then
					self:setup()
				end
				return
			end
		end
		assert(false)
	end
end
function KLEIRenderSceneClass:initRT( msaaSamples )
    self:setMSAA( msaaSamples )
	local post_process_manager = include( "post_process_manager" )

    self._Stage1PP = post_process_manager.create()  --Actual post process effect is selected later
    self._Stage2PP = post_process_manager.create()  --Actual post process effect is selected later

	self._RT = CreateRenderTarget( VIEWPORT_WIDTH, VIEWPORT_HEIGHT )
	self._RT:setClearColor( 0, 0, 0, 0 )

    --If Stage1 is not PASSTHOUGH this is needed
    self._PPRT = CreateRenderTarget( VIEWPORT_WIDTH, VIEWPORT_HEIGHT )
    self._PPRT:setRenderTable( { self._Stage1PP:getRenderable() } )

    --If Stage2 is not PASSTHROUGH these are needed
    --First pass of the bloom effect is to downsample the main RT into a 1/4 sized texture
    self._DSPP = post_process_manager.create()                                  --Input to the downsample is the main RT or PPRT, this is selected later
    self._DSRT = CreateRenderTarget( VIEWPORT_WIDTH / 2, VIEWPORT_HEIGHT / 2 )
    self._DSRT:setRenderTable( { self._DSPP:getRenderable() } )                 --Post process the main RT through the downsample

    --Second pass of the bloom effect is the vertical portion of the seperable gaussian blur
    self._VGPP = post_process_manager.vertical_gaussian( self._DSRT )           --Input to the vertical_gaussian is the downsampled buffer
    self._VGRT = CreateRenderTarget( VIEWPORT_WIDTH / 2, VIEWPORT_HEIGHT / 2 )
    self._VGRT:setRenderTable( { self._VGPP:getRenderable() } )                 --Post process the downsample through the vertical gaussian

    --Third pass of the bloom effect is the vertical portion of the seperable gaussian blur
    self._HGPP = post_process_manager.horizontal_gaussian( self._VGRT )         --Input to the horizontal gaussian in the vertical gaussian
    self._HGRT = CreateRenderTarget( VIEWPORT_WIDTH / 2, VIEWPORT_HEIGHT / 2 )
    self._HGRT:setRenderTable( { self._HGPP:getRenderable() } )                 --Post process the vertical gaussian through the horizontal gaussian

end

function KLEIRenderSceneClass:resizeRenderTargets()
	for _,info in pairs(self._gameTbl) do
		if info[1] and info[1].init and not info.CONST then
			if info.MSAA then
				info[1]:init( VIEWPORT_WIDTH, VIEWPORT_HEIGHT, nil, nil, nil, self._msaaSampleCount or 0 )
			else
				info[1]:init( VIEWPORT_WIDTH, VIEWPORT_HEIGHT )
			end
		end
	end
    if self._RT then
	    self._RT:init( VIEWPORT_WIDTH, VIEWPORT_HEIGHT )
    end
    if self._PPRT then
        self._PPRT:init( VIEWPORT_WIDTH, VIEWPORT_HEIGHT )
    end
    if self._DSRT then
        self._DSRT:init( VIEWPORT_WIDTH / 2, VIEWPORT_HEIGHT / 2 )
    end
    if self._VGRT then
        self._VGRT:init( VIEWPORT_WIDTH / 2, VIEWPORT_HEIGHT / 2 )
    end
    if self._HGRT then
        self._HGRT:init( VIEWPORT_WIDTH / 2, VIEWPORT_HEIGHT / 2 )
    end
end

function KLEIRenderSceneClass:setGameRenderTable( tbl )
	self._gameTbl = tbl or {}
	self:setup()
end
function KLEIRenderSceneClass:setHudRenderTable( tbl )
	self._hudTbl = tbl or {}
	self:setup()
end
function KLEIRenderSceneClass:setMouseCursor( renderable )
	self._mouseCursor = { renderable }
end
function KLEIRenderSceneClass:setDaltonizationType( mode )    
	assert( mode == 0 or mode == 1 or mode == 2 or mode == 3 )
	self._DaltonizationType = mode
	self:setup()
end
function KLEIRenderSceneClass:setGaussianBlur( blur )
    self._GausianBlur = blur or 0
    self:setup()
end

function KLEIRenderSceneClass:setDesaturation( func )
	self._desatFunc = func
	self:setup()
end

function KLEIRenderSceneClass:setMSAA( sampleCount )
    if (sampleCount or 0) <= 1 then
        sampleCount = 0
    end
	if self._msaaSampleCount ~= sampleCount then
		self._msaaSampleCount = sampleCount
		self:resizeRenderTargets()
	end
end

function KLEIRenderSceneClass:setPixelate( x_width, y_width )
	if x_width and y_width then
		self._PixelateInfo = { width=x_width, height=y_width }        
	else
		self._PixelateInfo = nil
	end
end

function KLEIRenderSceneClass:pulseUIFuzz( period )
	local timer = MOAITimer.new ()
	timer:setSpan ( period )
	timer:setMode ( MOAITimer.NORMAL )
	timer:setListener ( MOAITimer.EVENT_TIMER_END_SPAN, self.easeFinishedFunc )	
	timer:start()

	table.insert( self._UIEasePulseTimers, timer )

	self._EaseType = 0

	self:setup()
end

function KLEIRenderSceneClass:setAscii( ease )

    self._AsciiEase = ease

	self:setup()
end

local Stage1Options =
{
    PASSTHROUGH         = 0x1,
    PIXELATE            = 0x2,
    --SHUTTER             = 0x3,
    ASCII               = 0x4,
    FUZZ                = 0x5,
    DALTONIZE           = 0x6,
    DALTONIZE_ASCII     = 0x7,
    DALTONIZE_FUZZ      = 0x8,
}
local Stage2Options =
{
    PASSTHROUGH         = 0x9,
    BLOOM               = 0xA,
    DESATURATION        = 0xB,
    BLOOM_DESATURATION  = 0xC,
}

function KLEIRenderSceneClass:setup()
    local renderTable

    local Stage1 = Stage1Options.PASSTHROUGH

    if self._PixelateInfo then                                                                          --Pixelate
        Stage1 = Stage1Options.PIXELATE
	elseif self._DaltonizationType > 0 and #self._UIEasePulseTimers > 0 and self._EaseType == 0 then    --Daltonize and Fuzz
        Stage1 = Stage1Options.DALTONIZE_FUZZ
	elseif self._DaltonizationType > 0 and self._AsciiEase then                                         --Daltonize and Ascii
        Stage1 = Stage1Options.DALTONIZE_ASCII
	elseif self._DaltonizationType > 0 then                                                             --Only daltonization
        Stage1 = Stage1Options.DALTONIZE
	elseif #self._UIEasePulseTimers > 0 and self._EaseType == 0 then                                    --Fuzz only
        Stage1 = Stage1Options.FUZZ
	elseif self._AsciiEase then                                                                         --Ascii only
        Stage1 = Stage1Options.ASCII
    end

    local Stage2 = Stage2Options.PASSTHROUGH

    if self._GausianBlur ~= 0 and self._desatFunc then
        Stage2 = Stage2Options.BLOOM_DESATURATION
    elseif self._GausianBlur ~= 0 then
        Stage2 = Stage2Options.BLOOM
    elseif self._desatFunc then
        Stage2 = Stage2Options.DESATURATION
    end

    self._RT:setRenderTable( { self._gameTbl, self._hudTbl } )

    local renderTable
    if Stage1 == Stage1Options.PASSTHROUGH and Stage2 == Stage2Options.PASSTHROUGH then
        self._Stage1PP:passthrough( self._RT )
        renderTable = { self._RT, self._Stage1PP:getRenderable(), self._mouseCursor }
    else
        if Stage1 == Stage1Options.PASSTHROUGH then
            self._Stage1PP:passthrough( self._RT )
        elseif Stage1 == Stage1Options.PIXELATE then
            self._Stage1PP:pixelate( self._RT, function(shader) shader:setUniformVector2( "Size", self._PixelateInfo.width, self._PixelateInfo.height ) end )
        elseif Stage1 == Stage1Options.ASCII then
            self._Stage1PP:ascii( self._RT, self._AsciiEase )
        elseif Stage1 == Stage1Options.FUZZ then
            self._Stage1PP:fuzz( self._RT, self.easeDriver )
        elseif Stage1 == Stage1Options.DALTONIZE then
            self._Stage1PP:daltonize( self._RT, self._DaltonizationType )
        elseif Stage1 == Stage1Options.DALTONIZE_ASCII then
            self._Stage1PP:daltonize_ascii( self._RT, self._DaltonizationType, self._AsciiEase )
        elseif Stage1 == Stage1Options.DALTONIZE_FUZZ then
            self._Stage1PP:daltonize_fuzz( self._RT, self._DaltonizationType, self.easeDriver )
        else
            assert(false)
        end

        local Stage1T = self._PPRT
        local Stage1P = { self._RT, self._PPRT }
        if Stage1 == Stage1Options.PASSTHROUGH then
            Stage1T = self._RT
            Stage1P = { self._RT }
        end

        if Stage2 == Stage2Options.PASSTHROUGH then
            assert(Stage1 ~= Stage1Options.PASSTHROUGH )
            renderTable = {
                self._RT,                       --Push   _RT,   process its render table,   Pop _RT
                self._Stage1PP:getRenderable(), --execute Stage1
                self._mouseCursor,              --mouse cursor
            }
        elseif Stage2 == Stage2Options.BLOOM then
            self._DSPP:downsample( Stage1T )
            self._Stage2PP:bloom_merge( Stage1T, self._HGRT, self._GausianBlur )
            renderTable = {
                Stage1P,                        --execute Stage1P, outputs to Stage1T
                self._DSRT,                     --Push _DSRT,   downsample _PPRT,           Pop _DSRT
                self._VGRT,                     --Push _VGRT,   vertical gaussian _DSRT,    Pop _VGRT
                self._HGRT,                     --Push _HGRT,   horizontal gaussian _VGRT,  Pop _HGRT
                self._Stage2PP:getRenderable(), --bloom merge
                self._mouseCursor,              --mouse cursor
            }
        elseif Stage2 == Stage2Options.DESATURATION then
            self._Stage2PP:desaturation( Stage1T, self._desatFunc )
            renderTable = {
                Stage1P,                        --execute Stage1P, outputs to Stage1T
                self._Stage2PP:getRenderable(), --desaturation
                self._mouseCursor,              --mouse cursor
            }
        elseif Stage2 == Stage2Options.BLOOM_DESATURATION then
            self._DSPP:downsample( Stage1T )
            self._Stage2PP:bloom_merge_desaturation(Stage1T, self._HGRT, self._GausianBlur, self._desatFunc )
            renderTable = {
                Stage1P,                        --execute Stage1P, outputs to Stage1T
                self._DSRT,                     --Push _DSRT,   downsample _PPRT,           Pop _DSRT
                self._VGRT,                     --Push _VGRT,   vertical gaussian _DSRT,    Pop _VGRT
                self._HGRT,                     --Push _HGRT,   horizontal gaussian _VGRT,  Pop _HGRT
                self._Stage2PP:getRenderable(), --bloom merge desaturation
                self._mouseCursor,              --mouse cursor
            }
        else
            assert(false)
        end
    end

	MOAIRenderMgr.setRenderTable( renderTable )
end

return KLEIRenderSceneClass
