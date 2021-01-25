-- Screen mouseDown(*,*)
-- x and y already assigned, with values from 0 to 1, origin top left
local convertedX = x * 100
local convertedY = y * 100
Dragging = false

if convertedX > scrollUpButtonX and convertedX < scrollUpButtonX + scrollUpButtonWidth and convertedY > scrollUpButtonY and convertedY < scrollUpButtonY + scrollUpButtonHeight then
    -- Scroll up
    ScrollIndex = ScrollIndex - industriesPerPage
    if ScrollIndex < 0 then
        ScrollIndex = 0
    end
elseif convertedX > scrollDownButtonX and convertedX < scrollDownButtonX + scrollDownButtonWidth and convertedY > scrollDownButtonY and convertedY < scrollDownButtonY + scrollDownButtonHeight then
    -- Scroll down
    ScrollIndex = ScrollIndex + industriesPerPage
    if ScrollIndex > IndustryCount - industriesPerPage then
        ScrollIndex = IndustryCount - industriesPerPage
    end
-- And now, click-dragging for the scrollbar
elseif convertedX > scrollUpButtonX and convertedX < scrollUpButtonX + scrollUpButtonWidth and convertedY > scrollbarY and convertedY < scrollbarY + scrollbarHeight then
	-- Tag that we're dragging
	Dragging = true
	-- ... That's it.  
end

    -- Check if it was a recipe button
    
for i=ScrollIndex,ScrollIndex + industriesPerPage,1 do
    local buttonX = ButtonX
    local buttonY = ButtonY + (i-ScrollIndex)*(ButtonHeight+ButtonPadding)
    local craftablei = math.floor(i+1.5)
    if craftablei <= 0 then
        craftablei = IndustryCount
    elseif craftablei > IndustryCount then
        craftablei = 1 + craftablei%IndustryCount
    end
    if convertedX > buttonX and convertedX < buttonX + ButtonWidth and convertedY > buttonY and convertedY < buttonY + ButtonHeight then
        SelectedIndex = craftablei
    end
end