local util = include( "client_util" )
local array = include("modules/array")
local serverdefs = include( "modules/serverdefs" )
local stars = include('client/fe/stars')
local locationPopup = class()



local map_colours_highlight =
{
    --asia = {45/255,77/255,132/255, 1},
    asia = {89/255,138/255,221/255, 1},
    --europe = {71/255,81/255,81/255, 1},
    europe = {180/255,180/255,180/255, 1},
    sa = {200/255, 125/255, 13/255, 1},
    na = {187/255,82/255,200/255, 1},
    omni = {255/255,175/255,36/255, 1},
    --na = {93/255,39/255,100/255, 1},
}


function locationPopup:init( widget, campaign, situation, color )
    local corpData = serverdefs.getCorpData( situation )
    local situationData = serverdefs.SITUATIONS[situation.name]
    local travelTime = serverdefs.calculateTravelTime( campaign.location, situation.mapLocation ) + serverdefs.BASE_TRAVEL_TIME 
    local cityName = util.toupper(serverdefs.MAP_LOCATIONS[situation.mapLocation].name)
    local diff = STRINGS.UI.DIFFICULTY[situation.difficulty]

    widget.binder.pnl.binder.icon:setImage(corpData.imgs.logoLarge)
    if corpData.region and map_colours_highlight[corpData.region] then
        widget.binder.pnl.binder.icon:setColor(unpack(map_colours_highlight[corpData.region]))
    end
    
    widget.binder.pnl.binder.pnl.binder.travelTime:setText( util.sformat( STRINGS.UI.MAP_SCREEN_TRAVEL_TIME, cityName, travelTime ) )

    local missionTxt = util.toupper(string.format("%s %s", corpData.stringTable.SHORTNAME, situationData.ui.locationName))
    widget.binder.pnl.binder.pnl.binder.missionTxt:setText( missionTxt )
    stars.setDifficultyStars(widget, situation.difficulty)

end


return locationPopup