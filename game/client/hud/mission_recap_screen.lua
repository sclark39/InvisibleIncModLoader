local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local rig_util = include( "gameplay/rig_util" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local guiex = include( "client/guiex" )
local agent_templates = include("sim/unitdefs/agentdefs")
local itemdefs = include("sim/unitdefs/itemdefs")
local propdefs = include("sim/unitdefs/propdefs")
local guarddefs = include("sim/unitdefs/guarddefs")
local mainframe_abilities = include( "sim/abilities/mainframe_abilities" )

local HACKED_COLOR = { 196 / 255, 233 / 255, 219 / 255 }
local UNHACKED_COLOR = { 50 / 255, 50 / 255, 50 / 255 }

local GAINED_CREDITS_COLOR = { 196 / 255, 233 / 255, 219 / 255 }
local SPENT_CREDITS_COLOR = { 175 / 255, 2 / 255, 2 / 255 }

--we coalesce some devices and guards to be the same user-presenting icons.
local device_types =
{
    "camera",
    "scanner",

    "safe",
    "powersource",
    "lasers",
    "nanofab",
    "program_shop",
    "sound_bug",
    "turret",

    "barrier",
    "drone_camera",
    "drone_basic",
    "drone_armour",
    "drone_null",
    "drone_akuma",

    "db_camera",
    "db_console",
    "db_daemon",
    "db_facility",
    "large_safe",

    "detention_cell",
    "artifact_case",
    "executive_terminal",
    "vault_terminal",        
    "big_nanofab",
    "big_program_shop",
    "augment_grafter",
}

local guard_types = 
{
    "guard",
    "guard_armour",

    "drone_camera",
    "drone_basic",
    "drone_armour",
    "drone_null",
    "drone_akuma",

    "enforcer",
    "enforcer_armour",

    "specops",
    "sysadmin",
    "barrier",
    "grenade",
    "heavy",

    "executive",

    "omni_crier",
    "omni_hunter",
    "omni_killer",
    "omni_soldier",
    "omni_observer",
    "omni_protector",
}


local credit_sources =
{
    "selling",
    "pickpocket",
    "stolengoods",
    "hostage",
    "safes",
    "econchip",
    "mapping",
}

local credit_sinks =
{
    "cleanup",
    "buying",
}

local LOCALIZATION_MAP = {}
LOCALIZATION_MAP["selling"] = STRINGS.UI.RECAP.SELLING
LOCALIZATION_MAP["pickpocket"] = STRINGS.UI.RECAP.CREDITS_STOLEN
LOCALIZATION_MAP["stolengoods"] = STRINGS.UI.RECAP.VALUABLES
LOCALIZATION_MAP["hostage"] = STRINGS.UI.RECAP.HOSTAGE
LOCALIZATION_MAP["safes"] = STRINGS.UI.RECAP.SAFES
LOCALIZATION_MAP["econchip"] = STRINGS.UI.RECAP.ECONCHIP
LOCALIZATION_MAP["mapping"] = STRINGS.UI.RECAP.MAPPING
LOCALIZATION_MAP["cleanup"] = STRINGS.UI.RECAP.CLEANUP
LOCALIZATION_MAP["buying"] = STRINGS.UI.RECAP.PURCHASES

--these tables translate instantiated prefabs to our icons
local device_lookup =
{
    security_camera_1x1 = "camera",
    security_soundBug_1x1 = "sound_bug",
    turret = "turret",
    turret_generator = "turret", 
    laser_generator = "powersource", 
    item_store = "nanofab",
    item_store_large = "big_nanofab",
    lab_safe = "safe", --both big and small safes - anim gets swapped based on contents
    lab_safe_tier2 = "safe",
    augment_grafter = "augment_grafter",
    server_terminal = "big_program_shop",
    mini_server_terminal = "program_shop",
    camera_core = "db_camera",
    map_core = "db_facility",
    console_core = "db_console",
    daemon_core = "db_daemon",
    vault_safe_1 = "safe",
    vault_safe_2 = "safe",
    vault_safe_3 = "safe",
    public_terminal = "executive_terminal",
    ftm_scanner = "scanner",
    vault_processor = "vault_terminal", 
    detention_processor = "detention_cell", 
    drone = "drone_basic",
    drone_tier2 =  "drone_armour",
    null_drone = "drone_null",
    camera_drone = "drone_camera",
    drone_akuma = "drone_akuma",
    --final_terminal = "terminal",
}

--[[    console = 

    --final level consoles
    black_level_console =
    yellow_level_console =
    red_level_console =
--]]



local guard_lookup =
{
    npc_business_man = "executive",
    dummy_guard = "guard",
    npc_guard = "guard",
    sankaku_guard = "guard",
    ftm_guard = "guard",
    plastek_guard = "guard",
    ko_guard = "guard",
    ftm_grenade_guard = "grenade",
    ko_grenade_guard = "grenade",
    ftm_guard_tier_2 = "guard_armour",
    sankaku_guard_tier_2 = "guard_armour",
    plastek_guard_tier2 = "guard_armour" ,
    ko_guard_tier2 = "guard_armour",
    barrier_guard = "barrier",
    important_guard = "enforcer",
    plastek_recapture_guard = "sysadmin",
    plastek_firewall_guard = "sysadmin",
    ko_guard_heavy = "heavy",
    ko_specops = "specops",
    npc_guard_enforcer = "enforcer",
    npc_guard_enforcer_reinforcement = "enforcer",
    npc_guard_enforcer_reinforcement_2 = "enforcer",
    drone = "drone_basic",
    drone_tier2 =  "drone_armour",
    null_drone = "drone_null",
    camera_drone = "drone_camera",
    drone_akuma = "drone_akuma",
    omni_observer = "omni_observer",
    omni_hunter = "omni_hunter",
    omni_crier = "omni_crier",
    omni_killer ="omni_killer",
    omni_protector = "omni_protector",
    omni_soldier = "omni_soldier",
}


local function MakeTestData()
    local test_data =
    {
        credits_total = 3476,
        pwr_gained = 57,
        pwr_used = 37,
        total_consoles = 10,
        consoles_hacked = 4,
        max_alarm_level = 4,

        mission_type = "TERMINALS",
        mission_city = "VANCOUVER",
        mission_won = true,

        credits_gained = 
        {
            selling=400,
            pickpocket=687,
            hostage=0,
            stolengoods=100,
            safes=500,
            econchip=0,
            mapping=0,

        },

        credits_lost = 
        {
            cleanup=300,
            buying=400,
            felix=0,
        },

        agents =
        {
            {name="sharpshooter_1", status="MIA"},
            {name="engineer_1", status="ACTIVE"},
            {name="stealth_2", status="RESCUED"},
        },

        new_programs =
        {
            "lockpick_1",
            --"hunter",
            --"sniffer",
        },
        loot =
        {
            "item_scanchip",
            "item_icebreaker_3",
            "item_scanchip",
            "item_icebreaker_3",
            "item_scanchip",
            "item_icebreaker_3",
            "item_scanchip",
            "item_icebreaker_3",
            --"item_stim_3",
            --"item_power_tazer_3",
            --"item_defiblance",
        },
        
        guards = 
        {--[[
            {type = "plastek_recapture_guard", seen = true},
            {type = "barrier_guard", killed = true, seen = true},
            {type = "npc_guard", seen = true},
            {type = "ko_guard_tier2", seen = true},
            {type = "npc_guard", seen = true},
            {type = "barrier_guard", killed = true, seen = true},
            {type = "npc_guard", seen = true},
            {type = "ko_guard_tier2", seen = true},
            {type = "npc_guard", seen = true},
            {type = "barrier_guard", killed = true, seen = true},
            {type = "npc_guard", seen = true},
            {type = "ko_guard_tier2", seen = true},
            {type = "npc_guard", seen = true},
            {type = "barrier_guard", killed = true, seen = true},
            {type = "npc_guard", seen = true},
            {type = "ko_guard_tier2", seen = true},
            {type = "npc_guard"},
            {type = "camera_drone"},        
            --]]
        },



        devices = {
            {type="security_camera_1x1", hacked = false, seen = true},
            {type="security_camera_1x1", hacked = true, seen = true},
            {type="security_camera_1x1", hacked = true, seen = true},
            {type="security_camera_1x1", hacked = false, seen = true},
            {type="security_camera_1x1", hacked = true, seen = true},
            {type="security_camera_1x1", hacked = false, seen = true},
            {type="security_camera_1x1", hacked = true, seen = true},
            --{type="turret", hacked = true},
            {type="laser_generator", hacked = true, seen = true},
            {type="lab_safe", hacked = true, seen = true},
            {type="lab_safe", hacked = false, seen = true},
            {type="lab_safe", hacked = true, seen = true},
            {type="lab_safe", hacked = false, seen = true},
            {type="lab_safe", hacked = true, seen = true},
            {type="console_core", hacked = true, seen = true},           
            {type="mini_server_terminal", hacked = true, seen = true},           
            {type="server_terminal", hacked = true, seen = true},
        },
    }

    local num = 0
    for k,v in pairs(guard_lookup) do
        num = num + 1
        if num < 15 then 
            table.insert(test_data.guards, {type=k, seen=true, seen=math.random()>.5, killed=math.random() > 0.8, alerted=math.random() > 0.8, distracted =math.random() > 0.5 })
        end
    end


    return test_data
end


local agent_status_strings =
{
    MIA = STRINGS.UI.MIA,
    ACTIVE = STRINGS.UI.ACTIVE,
    RESCUED = STRINGS.UI.RESCUED,
}



local mission_recap_screen = class()
function mission_recap_screen:init()

    
    self.screen = mui.createScreen( "mission_recap_screen.lua" )

    self.screen:findWidget("pnl.okBtn.btn"):setVisible(false)
    self.screen:findWidget("pnl.okBtn.btn"):setText(STRINGS.UI.CONTINUE)

    self.screen:findWidget("pnl.guards"):setVisible(false)
    self.screen:findWidget("pnl.hacking"):setVisible(false)
    self.screen:findWidget("pnl.loot"):setVisible(false)
    self.screen:findWidget("pnl.credits"):setVisible(false)


    self.screen:findWidget("guards.cleanup"):setVisible(false)
    self.screen:findWidget("guards.alarm"):setVisible(false)
    self.screen:findWidget("hacking.pwrUsed"):setVisible(false)
    self.screen:findWidget("hacking.pwrGen"):setVisible(false)
    self.screen:findWidget("hacking.consoles"):setVisible(false)
    self.screen:findWidget("credits.cash"):setVisible(false)
    self.screen:findWidget("credits.networth"):setVisible(false)
    self.screen:findWidget("netWorthLarge"):setVisible(false)


    self.screen:findWidget("pnl"):setVisible(false)
    self.screen:findWidget("agent_pnl"):setVisible(false)
end

function mission_recap_screen:show(mission_data, on_complete)
    self.mission_data = mission_data or MakeTestData()
    self.on_complete = on_complete
    mui.activateScreen( self.screen )
    inputmgr.addListener( self, 1 )

    self.screen:findWidget("result"):setText(self.mission_data.mission_won and STRINGS.UI.MISSION_SUCCESS or STRINGS.UI.MISSION_FAILURE)
    self.screen:findWidget("location"):setText(string.format(STRINGS.UI.MISSION_LOCATION, self.mission_data.mission_city or "???"))
    self.screen:findWidget("missiontype"):setText(self.mission_data.mission_type or "SECRET")

    self:DoPresentation()    
end


function mission_recap_screen:PlaySound(snd, name)
    if self.go_fast then return end
    MOAIFmodDesigner.playSound( snd, name )
end

function mission_recap_screen:Wait(time)
    if self.go_fast then return end
    local frames = time * cdefs.SECONDS
    while not self.go_fast and frames > 0 do
        frames = frames - 1
        coroutine.yield()
    end
end


function mission_recap_screen:onInputEvent( event )
    if event.eventType == mui_defs.EVENT_KeyDown then
        if event.key == mui_defs.K_ESCAPE or event.key == mui_defs.K_ENTER then
            self.go_fast = true
            return true
        end
    end
end



function mission_recap_screen:ShowCountUp(base_widget, number_widget, endval, duration, format, end_string_override)
    --make a sound here!
    base_widget:setVisible(true)
    

    if not self.go_fast then
        base_widget:createTransition("activate_left")
    end

    number_widget:setVisible(false)
    
    while base_widget:hasTransition() and not self.go_fast do
        coroutine.yield()
    end

    number_widget:setVisible(true)
    
    if not self.go_fast and endval > 0 then
        self:PlaySound("SpySociety/HUD/menu/score_tally_LP", "loop")
       
        local start_val = 0
        
        local val = start_val
        local frames = duration * cdefs.SECONDS
        local rate = (endval - start_val) / frames
    
        while frames > 0 and not self.go_fast do
            number_widget:setText(string.format(format or "%d", val))
            val = val + rate
            frames = frames - 1
            coroutine.yield()
        end

        MOAIFmodDesigner.stopSound( "loop" )
    end
    
    if end_string_override then
        number_widget:setText(end_string_override)
    else
        number_widget:setText(string.format(format or "%d", endval))
    end

    self:PlaySound("SpySociety/HUD/menu/score_hit_small")
end

function mission_recap_screen:ShowPanel(widget)
    self:PlaySound("SpySociety/HUD/menu/score_category")
    widget:setVisible(true)
    widget:createTransition("activate_left")
    
    self:Wait( .1 )
end


function mission_recap_screen:DoPopulate(parent, data_set, template, sz, itemfn)

    if #data_set == 0 then return end
    local panel_width = 380
    local max_spacing = sz + 6
    local space_per_item = math.min(max_spacing, panel_width / #data_set)


    --bring in the actual guard tiles
    for k,v in ipairs(data_set) do
        if k > 1 then
            self:Wait( .15 )
        end

        self:PlaySound("SpySociety/HUD/menu/score_hit_small")
        local widget = self.screen:createFromSkin( template, { xpx = true, ypx = true } )
        parent:addChild(widget)

        itemfn(widget, v)

        widget:setPosition((k-1)*space_per_item, 0) 
        widget:createTransition("activate_above")
    end
end


function mission_recap_screen:DoPresentation()

    self._updateThread = MOAICoroutine.new()
    self._updateThread:run( function() 
        --wait for screen transition to end
        while self.screen:hasTransition() and not self.go_fast do coroutine.yield() end
        self:Wait( .25 )
        local pnl = self.screen:findWidget("pnl")
        pnl:setVisible(true)
        self:PlaySound("SpySociety/HUD/menu/score_whoosh")
        pnl:createTransition("activate_left")
        while pnl:hasTransition() and not self.go_fast do coroutine.yield() end

        self:ShowGuards()
        self:ShowHacking()
        self:ShowLoot()
        self:ShowCredits()
        self:ShowAgents()
        self:FinishPresentation()

    end )
end



function mission_recap_screen:ShowGuards()
        
    local guards = {}
    if self.mission_data.guards then
        for k,v in pairs(self.mission_data.guards) do
            local gtype = guard_lookup[v.type]
            if v.seen and gtype then
                table.insert(guards, {type = gtype, killed = v.killed, alerted = v.alerted, distracted = v.distracted, name = guarddefs[v.type] and guarddefs[v.type].name or "???", image = guarddefs[v.type] and guarddefs[v.type].profile_image or "gui/icons/guard_icons/guard.png"})
            end
        end
    end



    --sort by type and then by condition
    table.sort(guards, function(a, b) 
        local aindex, bindex = util.indexOf(guard_types, a.type), util.indexOf(guard_types, b.type) 
        if aindex == bindex then
            local astatus = (a.killed and 4 or 0) + (a.alerted and 2 or 0) + (a.distracted and 1 or 0)
            local bstatus = (b.killed and 4 or 0) + (b.alerted and 2 or 0) + (b.distracted and 1 or 0)
            return astatus < bstatus
        else
            return aindex < bindex
        end 
    end)

    --bring in the guard panel
    local root = self.screen:findWidget("pnl.guards")
    self:ShowPanel(root)
    self:DoPopulate(root:findWidget("items"), guards, "score_item", 32, function(widget, item) 

        local item_status = ""        
        if item.killed then 
            widget:findWidget("BG"):setColor(0, 0, 0, 0.3)
            widget:findWidget("portrait"):setImage("gui/icons/guard_icons/BW/"..item.image)
            item_status = STRINGS.UI.GUARD_KILLED 
        elseif item.alerted then
            widget:findWidget("BG"):setColor(0.4, 0, 0, 1)
            widget:findWidget("portrait"):setImage("gui/icons/guard_icons/"..item.image)
            item_status = STRINGS.UI.GUARD_ALERTED 
        elseif item.distracted then
            widget:findWidget("BG"):setColor(0.4, 0.4, 0.1, 1)
            widget:findWidget("portrait"):setImage("gui/icons/guard_icons/"..item.image)
            --widget:findWidget("BG"):setColor(0.1, 0.1, 0.1, 1)
            --widget:findWidget("portrait"):setColor(1, 1, 0.1, 1)
            item_status = STRINGS.UI.GUARD_DISTRACTED
        else
            widget:findWidget("BG"):setColor(0.1, 0.1, 0.1, 1)
            widget:findWidget("portrait"):setImage("gui/icons/guard_icons/"..item.image)
            item_status = STRINGS.UI.GUARD_GHOSTED
        end

        widget:setTooltip(string.format("<ttheader>%s</>\n%s", item.name, item_status)) --localize me, fool!
    end)

    self:ShowCountUp(root:findWidget("alarm"), root:findWidget("alarm.money"), self.mission_data.max_alarm_level or 1, .25)

    --show how much money you have to send to those poor guards' families
    local cleanup = (self.mission_data.credits_lost and self.mission_data.credits_lost.cleanup) or 0
    self:ShowCountUp(root:findWidget("cleanup"), root:findWidget("cleanup.money"), cleanup, .25)

end


function mission_recap_screen:ShowHacking()
    
    local hacked_items = {}
    
    if self.mission_data.devices then
        for k,v in pairs(self.mission_data.devices) do
            if v.seen and device_lookup[v.type] then
                if propdefs[v.type] then
                    table.insert(hacked_items, {icon=string.format("gui/icons/device_icons/%s.png",device_lookup[v.type]), prefab = v.type, type = device_lookup[v.type], tooltip = propdefs[v.type].name, hacked = v.hacked})
                elseif guarddefs[v.type] then
                    table.insert(hacked_items, {icon=string.format("gui/icons/device_icons/%s.png",device_lookup[v.type]), prefab = v.type, type = device_lookup[v.type], tooltip = guarddefs[v.type].name, hacked = v.hacked})
                end
            end
        end
    end

    table.sort(hacked_items, function(a, b) 
        local aindex, bindex = util.indexOf(device_types, a.type), util.indexOf(device_types, b.type) 
        if aindex == bindex then
            return (a.hacked and 1 or 0) > (b.hacked and 1 or 0)
        else
            return aindex < bindex
        end 
    end)

    local num_hacked_items = #hacked_items
    
    local row1num = 0
    local row2num = 0
    local max_comfortable_per_row = 10
    
    if num_hacked_items > max_comfortable_per_row * 2 then
        row1num, row2num = math.ceil(num_hacked_items/2), num_hacked_items - math.ceil(num_hacked_items/2)
    elseif num_hacked_items > max_comfortable_per_row then
        row1num, row2num = max_comfortable_per_row, num_hacked_items - max_comfortable_per_row
    else
        row1num, row2num = max_comfortable_per_row, 0
    end
    
    local hacked_items_1 = {}
    local hacked_items_2 = {}
    for k, v in ipairs(hacked_items) do
        if k <= row1num then
            table.insert(hacked_items_1, v)
        else
            table.insert(hacked_items_2, v)
        end
    end

    local root = self.screen:findWidget("pnl.hacking")
    self:ShowPanel(root)
    if hacked_items_1 then
        self:DoPopulate(root:findWidget("items"), hacked_items_1, "score_item", 32, function(widget, item)
            
            widget:findWidget("portrait"):setImage(item.icon)

            if item.hacked then
                widget:findWidget("portrait"):setColor( unpack(HACKED_COLOR) )
            else
                widget:findWidget("portrait"):setColor( unpack(UNHACKED_COLOR) )
            end

            widget:setTooltip(string.format("<ttheader>%s</>\n%s", item.tooltip, item.hacked and STRINGS.UI.RECAP.HACKED or STRINGS.UI.RECAP.NOTHACKED)) 
        end)
    end

    if hacked_items_2 then
        self:DoPopulate(root:findWidget("items2"), hacked_items_2, "score_item", 32, function(widget, item)
            
            widget:findWidget("portrait"):setImage(item.icon)

            if item.hacked then
                widget:findWidget("portrait"):setColor( unpack(HACKED_COLOR) )
            else
                widget:findWidget("portrait"):setColor( unpack(UNHACKED_COLOR) )
            end

            widget:setTooltip(string.format("<ttheader>%s</>\n%s", item.tooltip, item.hacked and STRINGS.UI.RECAP.HACKED or STRINGS.UI.RECAP.NOTHACKED)) 
        end)
    end

    self:ShowCountUp(root:findWidget("consoles"), root:findWidget("consoles.money"), self.mission_data.consoles_hacked or 0, .2, "%d/"..tostring(self.mission_data.total_consoles or 0))
    self:ShowCountUp(root:findWidget("pwrGen"), root:findWidget("pwrGen.money"), self.mission_data.pwr_gained or 0, .2)
    self:ShowCountUp(root:findWidget("pwrUsed"), root:findWidget("pwrUsed.money"), self.mission_data.pwr_used or 0, .2)
end


function mission_recap_screen:ShowLoot()

    local loot_items = {}

    if self.mission_data.loot then
        for k,v in pairs(self.mission_data.loot) do
            if itemdefs[v] then
                table.insert(loot_items, {icon=itemdefs[v].profile_icon, tooltip = itemdefs[v].name})
            end
        end
    end

    if self.mission_data.new_programs then
        for k,v in pairs(self.mission_data.new_programs) do
            if mainframe_abilities[v] then
                table.insert(loot_items, {icon=mainframe_abilities[v].icon, tooltip = mainframe_abilities[v].name, program = true})
            end
        end
    end


    --bring in the guard panel
    local root = self.screen:findWidget("pnl.loot")
    self:ShowPanel(root)
    self:DoPopulate(root:findWidget("items"), loot_items, "loot_item", 50, function(widget, item) 
        widget:findWidget("icon"):setImage(item.icon)
        widget:setTooltip(item.tooltip)
        if item.program then
            --widget:findWidget("bg"):setColor(128, 0, 128, 1)
        end
    end)
end


--this one is kind of complicated because of the data pre-processing
function mission_recap_screen:ShowCredits()
        
    local root = self.screen:findWidget("pnl.credits")
    --prep the source data
    local sources = {}
    local gained = 0
    local spent = 0

    if self.mission_data.credits_gained then
        for k,v in pairs(self.mission_data.credits_gained) do
            if util.indexOf(credit_sources, k) and v > 0 then
                table.insert(sources, {gain = true, source = k, amount = v})
                gained = gained + v
            end
        end
    end

    if self.mission_data.credits_lost then
        for k,v in pairs(self.mission_data.credits_lost) do
            if util.indexOf(credit_sinks, k) and v > 0 then
                table.insert(sources, {gain = false, source = k, amount = v})
                spent = spent + v
            end
        end
    end
    
    table.sort(sources, function(a,b) 
        if a.gain == b.gain then 
            return util.indexOf(a.gain and credit_sources or credit_sinks, a.source) < util.indexOf(b.gain and credit_sources or credit_sinks, b.source)
        else
            return a.gain
        end
    end)


    local numsources = #sources
    root:findWidget("cashflow.row1"):setVisible(#sources > 0)
    for k = 1, 10 do 
        root:findWidget(string.format("row1.col%d", k)):setVisible(false)
    end
    
    self:ShowPanel(root)

    for k = 1, math.min(#sources, 11) do

        local str = string.format("cashflow.row1.col%d", k)
        local widget = root:findWidget( str )
        widget:setVisible(true)
        local filename = string.format("gui/icons/cashflow_icons/%s.png", sources[k].source)
        widget:findWidget("icon"):setImage(filename)

        if sources[k].gain then
            widget:findWidget("number"):setText(string.format("%d", sources[k].amount))
            widget:findWidget("icon"):setColor(unpack(GAINED_CREDITS_COLOR))
        else
            widget:findWidget("number"):setText(string.format("-%d", sources[k].amount))
            widget:findWidget("icon"):setColor(unpack(SPENT_CREDITS_COLOR))
        end

        widget:createTransition("activate_above")
        widget:setTooltip(LOCALIZATION_MAP[ sources[k].source ])

        self:PlaySound("SpySociety/HUD/menu/score_hit_big")
        self:Wait(.1)
    end

    local delta_net_worth = self.mission_data.postNetWorth - self.mission_data.preNetWorth
    local delta_credits = gained - spent

    self:ShowCountUp(root:findWidget("cash"), root:findWidget("cash.money"), self.mission_data.final_credits, .2, nil, delta_credits ~= 0 and string.format("%d (%+d)", self.mission_data.final_credits, delta_credits))
    self:ShowCountUp(root:findWidget("networth"), root:findWidget("networth.money"), self.mission_data.postNetWorth, .2, nil, delta_net_worth ~= 0 and string.format("%d (%+d)", self.mission_data.postNetWorth, delta_net_worth))
    self:ShowCountUp(root:findWidget("netWorthLarge"), root:findWidget("netWorthLarge.money"), self.mission_data.postNetWorth, .2)

end

function mission_recap_screen:ShowAgents()

    local root = self.screen:findWidget("agent_pnl")
    for k = 1, 4 do 
        root:findWidget("agent" .. tostring(k)):setVisible(false)
    end
        
    root:setVisible(true)
    root:createTransition("activate_left")
    self:PlaySound("SpySociety/HUD/menu/score_whoosh")
    self:Wait(.25)


    if self.mission_data.agents then
        local num_bound = 0
        for k = 1, #self.mission_data.agents do

            local agentdata = agent_templates[self.mission_data.agents[k].name]
            
            if agentdata then
                num_bound = num_bound + 1
                if num_bound <= 4 then
                    local widget = root:findWidget("agent" .. tostring(num_bound))
                    widget.binder.name:setText( util.toupper(agentdata.name) )
                    widget.binder.profile:setImage(agentdata.profile_icon_64x64)
                
                    widget.binder.details:setText( agent_status_strings[self.mission_data.agents[k].status] )

                    if self.mission_data.agents[k].status == "MIA" then
                        widget.binder.bgMIA:setVisible(true)
                    else
                        widget.binder.bgMIA:setVisible(false)
                    end

                    
                    widget:setVisible(true)
                    widget:createTransition("activate_left")

                    MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/score_hit_big" )
                    self:Wait(.1)
                end
            end
        end
    end

    self:Wait( .25 )
end

function mission_recap_screen:FinishPresentation()
    MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/score_hit_big" )
    self.screen:findWidget("pnl.okBtn.btn"):setVisible(true)
    self.screen:findWidget("pnl.okBtn.btn").onClick = function() self:Close() end
    self.screen:findWidget("pnl.okBtn.btn"):setHotkey( mui_defs.K_ENTER )
end


function mission_recap_screen:Close()
    inputmgr.removeListener( self )
    mui.deactivateScreen( self.screen )
    if self.on_complete then
        self.on_complete()
    end
end


return mission_recap_screen
