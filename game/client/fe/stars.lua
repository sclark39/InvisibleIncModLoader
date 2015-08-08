local function setDifficultyStars(widget_parent, difficulty)

    local star = widget_parent:findWidget("difficultyShield")

    star:setImage(string.format("gui/menu pages/map_screen/shield%d.png", difficulty))

end


return {setDifficultyStars = setDifficultyStars}