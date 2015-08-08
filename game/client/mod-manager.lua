----------------------------------------------------------------
-- Copyright (c) 2015 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local filesystem = include("modules/filesystem")

local MOD_FOLDER = "mods"
local DLC_FOLDER = "dlc"

----------------------------------------------------------------
-- Mod handling

local mod_manager = class()

function mod_manager:init( mod_path )
    self.mod_path = mod_path or ""
    self.mods = {}
    self.modPrefabs = {}
    self.modMissionScripts = {}
    self.modWorldPrefabs = {}
    self.generationOptions = {}
    self:enumerateMods( self.mod_path .. DLC_FOLDER, true )
    self:enumerateMods( self.mod_path .. MOD_FOLDER )

    filesystem.mountVirtualDirectory( "data_locale", "data" ) -- By default, simply map directly to data.

    local settings = savefiles.getSettings( "settings" )
    if settings.data.localeMod then
        self:mountLanguageMod( settings.data.localeMod )
    end
    
    for i, mod in ipairs(self.mods) do
        if mod.is_dlc then
            self:mountContentMod( mod.id )
        end
    end
end

function mod_manager:updateMods()
    if not KLEISteamWorkshop then
        return
    end

    log:write( "Updating mods..." )
    KLEISteamWorkshop:setListener( KLEISteamWorkshop.EVENT_REFRESH_COMPLETE,
        function( success, msg )
            log:write("KLEISteamWorkshop.EVENT_REFRESH_COMPLETE - (%s, %s)", success and "succeeded" or "failed", msg )
            self:clearMods()
            --self:enumerateMods( self.mod_path or DLC_FOLDER )
            self:enumerateMods( self.mod_path .. MOD_FOLDER )
        end )
    -- Kick off the call to refresh mods.
    KLEISteamWorkshop:updateWorkshopMods()
end

function mod_manager:enumerateMods( enum_folder, is_dlc )

    log:write("Mod manager enumerating [%s]", enum_folder)

    local steamMods = KLEISteamWorkshop and KLEISteamWorkshop:getWorkshopMods() or {}
    local fsMods = MOAIFileSystem.listDirectories( enum_folder ) or {}
    for i, path in ipairs( fsMods ) do
        local modData = nil

        -- if it's a workshop mod, pick up steam data
        for i,mod in ipairs(steamMods) do
            if mod.folder == path then
                modData = mod
                break
            end
        end

        modData = modData or {} -- might be a bare folder with no associated steam data
        modData.id = modData.id or path -- either workshop id or folder name as appropriate
        modData.folder = filesystem.pathJoin( enum_folder, path )
        modData.is_dlc = is_dlc

        log:write("Found mod [%s] in [%s]", modData.id, modData.folder)

        self:initMod( modData )
    end
end

function mod_manager:initMod( modData )
    log:write( "initMod - %s", modData.folder )

    local initFile = filesystem.pathJoin( modData.folder, "modinfo.txt" )

    -- Find the specified locale in modinit.
    local fl = io.open( initFile, "r" )
    if fl then
        local modinfo = {}
	    for line in fl:lines() do
            local key, value = line:match( "^([_%w]+)[%s]*=[%s]*(.+)%s*$" )
            if key and value then
                modinfo[key] = value
                log:write( "\tproperty: %s = %s", tostring(key), tostring(value) )
            end
        end

        if modinfo.locale then
            modData.name = modinfo.name
            modData.locale = modinfo.locale
            modData.poFile = modinfo.poFile
			
            log:write( "\tNAME: %s", tostring(modData.name) )
            log:write( "\tLOCALE: %s", tostring(modData.locale) )
            log:write( "\tPOFILE: %s", tostring(modData.poFile) )
			
			table.insert( self.mods, modData )
        end

        if modinfo.modtype then
            modData.name = modinfo.name
            modData.modtype = modinfo.modtype
            modData.mlversion = modinfo.mlversion or 1
			
            log:write( "\tNAME: %s", tostring(modData.name) )
            log:write( "\tMOD TYPE: %s", tostring(modData.modtype) )
            log:write( "\tML VERSION: %s", tostring(modData.mlversion) )
			
			table.insert( self.mods, modData )
        end

        
    elseif MOAIFileSystem.checkFileExists( filesystem.pathJoin( modData.folder, "scripts.zip" )) then
        table.insert( self.mods, modData )
    else
        log:write( "\tMissing '%s' -- ignoring.", initFile )
    end
end

function mod_manager:mountContentMod( id )
    local modData = self:findMod( id )
    if not modData then
        log:write( "Could not mount missing content mod: '%s'", tostring(id) )
    elseif not MOAIFileSystem.checkFileExists( filesystem.pathJoin( modData.folder, "scripts.zip" )) then
        log:write( "Could not mount content mod without scripts.zip: '%s'", tostring(id) )
    else
        -- Mount the content archive.
        local scriptsArchive = string.format( "%s/scripts.zip", modData.folder, modData.scripts )
        local scriptsAlias = scriptsArchive:match( "/([-_%w]+)/scripts[.]zip$" )

        log:write( "Mounting content mod [%s] scripts at: [%s]", tostring(scriptsArchive), tostring(scriptsAlias)  )
        MOAIFileSystem.mountVirtualDirectory( scriptsAlias, scriptsArchive )

        local initFile = string.format( "%s/modinit.lua", scriptsAlias )
        log:write( "\tExecuting '%s':", initFile )
        local ok, mod = pcall( dofile, initFile )
        if ok then
            modData.modfn = mod

            assert(modData.modfn.init)
            assert(modData.modfn.load)

            ok, res = xpcall(
                function()
                    local modapi = reinclude( "mod-api" )
                    modData.api = modapi( self, id, modData.folder, scriptsAlias )

                    modData.modfn.init( modData.api )
                end,
                function( err )
                    log:write( "mod.init ERROR: %s\n%s", tostring(err), debug.traceback() )
                end )
        end
        if ok then
            log:write( "\tMOD-INIT OK")
            -- Anything here to finalize mod content?
            modData.installed = true
        else
            log:write( "\tMOD-INIT FAILED: %s", tostring(res))
            modData.installed = false
        end
    end
end

function mod_manager:mountLanguageMod( id )
    local modData = self:findMod( id )
    if not modData then
        log:write( "Could not mount missing language mod: '%s'", tostring(id) )
    elseif not modData.locale then
        log:write( "Could not mount non-language mod: '%s'", tostring(id) )
    elseif not modData.poFile then
        log:write( "Could not language mod without specified 'poFile': '%s'", tostring(id) )
    else
        log:write( "Mounting language mod: %s ['data-locale' -> '%s']", modData.locale, modData.folder )    
        filesystem.mountVirtualDirectory( "data_locale", modData.folder )
        local loc_translator = include( "loc_translator" )
        local poFilepath = string.format( "%s/%s", modData.folder, modData.poFile )
        loc_translator.translateStringTable( "STRINGS", STRINGS, poFilepath, modData.locale )
        self.languageMod = modData
    end
end

function mod_manager:getLanguageMod()
    return self.languageMod
end

function mod_manager:clearMods()
    util.tclear( self.mods )
end

function mod_manager:findMod( id )
    for i, modData in ipairs(self.mods) do
        if modData.id == id and id then
            return modData
        end
    end
end

function mod_manager:getLanguageMods()
    local t = {}
    for i, modData in ipairs(self.mods) do
        if modData.locale then
            table.insert( t, { name = modData.locale, id = modData.id } )
        end
    end
    return t
end

function mod_manager:loadMLMod( id )
    local modData = self:findMod( id )
    if not modData then
        log:write( "Could not load missing game mod: '%s'", tostring(id) )
    elseif modData.modtype ~= "game" then
        log:write( "Could not load non-game mod: '%s'", tostring(id) )
	else
        log:write( "Loading game mod: %s", tostring(id) )    
	
		local filename = filesystem.pathJoin( modData.folder, "main.lua" )
		assert( filename ) -- Important assert, since loadfile's behaviour for nil filename is to read from stdin (can you say HANG?)
		local f,e = loadfile( filename )
		assert( f, e )		
		local status, err = pcall( f )
		if not status then			
			modData.status = "ERR:SYNTAX"
			log:write(err)
		else
			modData.obj = err
			local status,err = xpcall(
                function() return modData.obj:load() end,
                function( err )
                    log:write( "ml_mod.load ERROR: %s\n%s", tostring(err), debug.traceback() )
                end )
			if status and err then
				modData.active = true
				modData.status = "ON"
			else
				if not status then
					log:write(err)
				end
				modData.active = false
				modData.status = "ERR:RUNTIME"
			end
		end
	
	end
end

function mod_manager:unloadMLMod( id )
    local modData = self:findMod( id )
    if not modData then
        log:write( "Could not unload missing game mod: '%s'", tostring(id) )	
    elseif not modData.active then
        log:write( "Could not unload non-loaded game mod: '%s'", tostring(id) )
	else
        log:write( "Unloading game mod: %s", tostring(id) )    
		local status,err = xpcall(
			function() return modData.obj:unload() end,
			function( err )
				log:write( "ml_mod.unload ERROR: %s\n%s", tostring(err), debug.traceback() )
			end )
		if status and err then
			modData.active = false
			modData.status = "OFF"
		else
			if not status then
				log:write(err)
			end
			modData.active = false
			modData.status = "ERR:RUNTIME"
		end	
	end
end

function mod_manager:getMLMods()
	local t = {}
    for i, modData in ipairs(self.mods) do
        if modData.modtype == "game" then
			table.insert( t, { name = modData.name or modData.title or "undefined", status = modData.status or "OFF", active = modData.active or false, id = modData.id } )
        end
    end
    return t
end

function mod_manager:isDLCOptionEnabled(modID,option)
   local modData = self:findMod( modID )
    
    if modData and modData.options then
        return modData.options[option] and modData.options[option].enabled
    end
end

function mod_manager:getInstalledMods()
    local t = {}
    for i, modData in ipairs(self.mods) do
        if modData.installed then
            assert( modData.id )
            table.insert( t, modData.id )
        end
    end
    return t
end

function mod_manager:isInstalled( id )
    local modData = self:findMod( id )
    return modData and modData.installed
end

function mod_manager:getModName( id )
    local modData = self:findMod( id )
    return modData and (modData.name or "ID:"..modData.id)
end

function ResetCampaignEvents(self)
    self.campaignEvents = {}
end


function mod_manager:resetContent()
    log:write("mod_manager:resetContent()")

    ResetAgentDefs()
    ResetAgentLoadouts()
    ResetSelectableAgents()
    ResetSelectablePrograms()
    ResetDaemonAbilities()
    ResetStoreItems()
    ResetMetaDefs()
    ResetUnitDefsPotential()
    ResetSituations()
    ResetCampaignEvents(self)
    ResetStoryScripts()
    ResetPropDefs()
end

function mod_manager:loadModContent( dlc_options )
    
    self.modPrefabs = {}
    self.modMissionScripts = {}

    --log:write("mod_manager:loadModContent(%s)", util.stringize(dlc_options))    
    if dlc_options then
        for id,dlc in pairs(dlc_options) do
            --log:write("   %s %s: %s", id, dlc.name, tostring(dlc.enabled))
            if dlc.enabled then
                local modData = self:findMod( id )
                modData.modfn.load(modData.api, dlc.options)
            end
        end
    end
end


function mod_manager:setCampaignEvent(event)
    table.insert(self.campaignEvents,event)
end
 
function mod_manager:getCampaignEvents()
    return self.campaignEvents
end

function mod_manager:addGenerationOption( mod_id, option, name, tip)
    if not self.generationOptions[mod_id] then
        self.generationOptions[mod_id] = { name = self:getModName(mod_id), enabled = true, options = {} }
    end

    local new_opt = { option = option, name = name, enabled = true, tip = tip}
    table.insert(self.generationOptions[mod_id].options, new_opt)
end

function mod_manager:getModContentDefaults()
    --log:write("mod_manager:getModContentDefaults")

    local options = util.tcopy(self.generationOptions)

    -- convert from array (for order) to keyed (for save game)
    for mod_id, mod_info in pairs(options) do
        local keyed_options = {}
        for i, opt_info in ipairs(mod_info.options) do
            keyed_options[opt_info.option] = { enabled = opt_info.enabled }
        end
        mod_info.options = keyed_options
    end

    --log:write("   %s", util.stringize(options))

    return options
end

function mod_manager:getModGenerationOptions( mod_id )
    return util.tcopy(self.generationOptions[mod_id].options)
end


function mod_manager:addWorldPrefabs( world , prefabs )
    self.modWorldPrefabs[world] = prefabs 
end


return mod_manager
