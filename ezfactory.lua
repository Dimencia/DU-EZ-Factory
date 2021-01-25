-- In here, we will iterate all machines to get their info
-- And build a screen displaying it.

local font = "Calibri" -- No-flicker font
local tableFontSize = "12px"

-- Okay let's get straight to it, setup the viewbox for a screen
local content = "<svg class='bootstrap' viewBox='0 0 1024 612'>"
-- Layout a nice title bar
-- Stolen from the elevator
content = content .. "<path d='M 0 0 L 194 75 Q 512 95 830 75 L 1024 0' style='stroke:black;opacity:1;stroke-width:3;fill-opacity:0.9;fill:rgb(55,55,55)'/>"
content = content .. "<text x='50%' y='20px' style='font-size:22px;fill:white;text-anchor:middle;font-family:" .. font .. "'>EZ Factory Monitor</text>"

-- Setup a table header
-- Each industry unit will list:
-- Schematic Name, Unit Status, Amount in Container / Amount to Maintain, 
-- That's it for now.  Later we can add amount/hour, requirements, requirement amounts/hour, etc

-- Honestly we don't even need a header for that
local y = 110 -- Remember, we only have 612 y to work with don't get greedy
-- But the header stops at 95

-- Now to steal directly from my other screen project

-- So basically, we should store a scrollIndex of where they are.  Display items from that index down, I guess like 5 or whatever.  
-- Though the scrollIndex itself would be a large number, equal to arrayIndex*buttonHeight, so it could scroll smoothly.
-- Not sure if we can get mouse wheel events though.  We might need up/down buttons, which would need to be pageup/pagedwn to not be annoying

-- Anyway that's the left side of the screen, a list of items with a scrollbar.  Maybe later we can categorize them.  
-- And on the right side we just have a simple number selector to pick how many batches you need
-- And a button that when pressed, shows you a new screen that just lists all the ores you should input to build it
-- With an OK button to go back.

-- When one of the options is selected it would turn like yellow, and its name will go on the right side above the quantity selector

ButtonX = 1 -- In VW
ButtonY = (y / 1024) * 100 -- Convert to VW
ButtonHeight = 10 --export: Height of buttons on the screen in vh
ButtonPadding = 1 --export: How much vertical padding there is between buttons in vh

-- I guess let's prepare the buttons.
ButtonWidth = 50 -- in vw

local defaultFill = "rgb(35,35,35)"
local selectedFill = "rgb(150,150,150)"
local defaultFontColor = "white"
local selectedFontColor = "black"
local content = "<svg width='100vw' height='100vh' style='position:absolute; top:0; left:0'>"
local recipeIndex = ScrollIndex
industriesPerPage = math.floor(((100-ButtonY)/(ButtonHeight+ButtonPadding)))-1

local count = IndustryCount
if CategoryView then
	count = #IndustryBySchematic
end


for i=recipeIndex,recipeIndex + industriesPerPage + 1,1 do 
	local buttonX = ButtonX
	local buttonY = ButtonY + (i-recipeIndex-(i-math.floor(i)))*(ButtonHeight+ButtonPadding)
	local craftablei = math.floor(i+1)
	if craftablei <= 0 then
		craftablei = count
	elseif craftablei > count then
		break -- Don't draw past it
	end
	
	local selected = (SelectedIndex > -1 and SelectedIndex == craftablei) -- or == i?
	
	local fontColor = defaultFontColor
	local fillColor = defaultFill
	if selected then
		fontColor = selectedFontColor
		fillColor = selectedFill
	end

	-- Draw a rectangle for the 'button'
	content = content .. '<rect width="' .. ButtonWidth .. 'vw" height="' .. ButtonHeight .. 'vh" x="' .. buttonX .. 'vw" y="' .. buttonY .. 'vh" style="fill:' .. fillColor .. ';stroke-width:1;stroke:white;" />'
	
	-- And, the text is complicated because I want to list a lot of info with potentially different colors.
	-- Though really, on the label, I just want the industry name top left, small.  Top middle, schematic name
	-- Bottom centered, and colored, amount in container / amount maintaining
	
	
	
	if CategoryView then
		-- So, each entry in IndustryBySchematic is a list of industryObjects, with the new schematic field (which is its name)
		-- For each button, we need to iterate them, check all their statuses, and report either OK if all are pending or running
		-- Or report the error and number of them that have that error.
		
		-- Also iterate to see status.maintainProductAmount and status.currentProductAmount
		-- For our purposes, assume all of them are maintaining into the same container
		-- So just display the one with the highest values
		
		-- Also sometimes they get bugged and show 0 while pending
		-- If this is happening, adjust it to assume that the amount in the container matches the maintain amount
		
		local industryList = IndustryBySchematic[craftablei] -- It occurs to me this is now misnamed, lol
		
		local finalState = "OK"
		local finalAmountMaintained = 0
		local finalAmountAvailable = 0
		local name = nil
		local hasPending = false
		
		for _,v in ipairs(industryList) do
			local status = json.decode(core.getElementIndustryStatus(v.id))
			if status.maintainProductAmount ~= nil and status.maintainProductAmount > finalAmountMaintained then
				finalAmountMaintained = status.maintainProductAmount
			end
			if status.currentProductAmount ~= nil and status.currentProductAmount > finalAmountAvailable then
				finalAmountAvailable = status.currentProductAmount
			end
			if status.state ~= "PENDING" and status.state ~= "RUNNING" then
				finalState = status.state
			end
			if status.state == "PENDING" then
				hasPending = true
			end
			if SchematicNames[status.schematicId] ~= nil then -- They should all have the same Schem Name
				name = SchematicNames[status.schematicId]
			end
		end
		-- After we're done, if it's still 0 but things were pending, estimate.  
		if finalAmountAvailable == 0 and hasPending then
			finalAmountAvailable = finalAmountMaintained
		end
		
		content = content .. "<text x='" .. buttonX + 0.1 .. "%' y='" .. buttonY + ButtonHeight - 3 .. "%' font-size='2.5vh' fill=" .. fontColor .. " font-family='" .. font .. "'>" .. #industryList .. " Industries</text>"
		
		if name ~= nil then
			content = content .. "<text x='" .. buttonX + ButtonWidth/2 .. "%' y='" .. buttonY + 4 .. "%' font-size='4vh' fill='" .. fontColor .. "' text-anchor='middle' font-family='" .. font .. "'>" .. name .. "</text>"
			local statusFontString = "rgb(200,50,50)" -- Default to some red stopped status
			if finalState == "OK" then
				statusFontString = "rgb(100,200,50)"
			end
			
			-- Oh right and also the status top right
			content = content .. "<text x='" .. buttonX + ButtonWidth - ButtonWidth/6 .. "%' y='" .. buttonY + 2.5 .. "%' font-size='2vh' fill=" .. statusFontString .. " text-anchor='middle' font-family='" .. font .. "'>" .. finalState .. "</text>"
			-- And, centered below
			local ratio = finalAmountAvailable/finalAmountMaintained
			local r = utils.clamp(math.floor(255 - 255 * ratio),0,200)
			local g = utils.clamp(math.floor(255 * ratio),0,200)
			local colorString = "rgb(" .. r .. "," .. g .. ",50)"
			if finalAmountMaintained > 0 and finalAmountMaintained < 1000000 then -- Don't show bugged values
				content = content .. "<text x='" .. buttonX + ButtonWidth/2 .. "%' y='" .. buttonY + ButtonHeight - 2 .. "%' font-size='3vh' fill=" .. colorString .. " text-anchor='middle' font-family='" .. font .. "'>" .. finalAmountAvailable .. " / " .. finalAmountMaintained .. "</text>"
			end
		end
		
	else
		-- First, get the info.
		local status = json.decode(core.getElementIndustryStatus(IndustryUnits[craftablei].id))
		
		--local schematic = json.decode(core.getSchematicInfo(status.schematicId))
		
		content = content .. "<text x='" .. buttonX + 0.1 .. "%' y='" .. buttonY + ButtonHeight - 3 .. "%' font-size='2.5vh' fill=" .. fontColor .. " font-family='" .. font .. "'>" .. IndustryUnits[craftablei].name .. "</text>"
		
		local name = SchematicNames[status.schematicId]
		if name ~= nil then
			content = content .. "<text x='" .. buttonX + ButtonWidth/2 .. "%' y='" .. buttonY + 4 .. "%' font-size='4vh' fill='" .. fontColor .. "' text-anchor='middle' font-family='" .. font .. "'>" .. name .. "</text>"
			local statusFontString = "rgb(200,50,50)" -- Default to some red stopped status
			if status.state == "PENDING" then
				statusFontString = "rgb(100,200,50)"
			elseif status.state == "RUNNING" then
				statusFontString = "rgb(0,200,50)"
			end
			
			-- Oh right and also the status top right
			content = content .. "<text x='" .. buttonX + ButtonWidth - ButtonWidth/6 .. "%' y='" .. buttonY + 2.5 .. "%' font-size='2vh' fill=" .. statusFontString .. " text-anchor='middle' font-family='" .. font .. "'>" .. status.state .. "</text>"
			-- And, centered below
			local ratio = status.currentProductAmount/status.maintainProductAmount
			local r = utils.clamp(math.floor(255 - 255 * ratio),0,200)
			local g = utils.clamp(math.floor(255 * ratio),0,200)
			local colorString = "rgb(" .. r .. "," .. g .. ",50)"
			if status.maintainProductAmount > 0 and status.maintainProductAmount < 1000000 then -- Don't show bugged values
				content = content .. "<text x='" .. buttonX + ButtonWidth/2 .. "%' y='" .. buttonY + ButtonHeight - 2 .. "%' font-size='3vh' fill=" .. colorString .. " text-anchor='middle' font-family='" .. font .. "'>" .. status.currentProductAmount .. " / " .. status.maintainProductAmount .. "</text>"
			end
		end
	end
end

-- Draw the header after, to be ontop of any buttons drawn early
content = content .. '<rect width="100vw" height="' .. ButtonY - ButtonPadding .. 'vh" x="0" y="0" style="fill:white;stroke-width:1;stroke:black;" />'
content = content .. "<text x='50%' y='" .. ButtonHeight/2 + 3 .. "%' font-size='8vh' fill='black' text-anchor='middle' font-family='" .. font .. "'>EZ Factory Monitor</text>"

-- Now we need scroll buttons.  No scroll wheel access, so, pageup and pagedown buttons
-- They should be the same height as these buttons, not very wide, and at the top and bottom beside them on the right
-- Our other stuff can go in the rest of that blank space between them

-- We do need these for detection purposes
scrollUpButtonX = ButtonX + ButtonWidth + ButtonPadding
scrollUpButtonY = ButtonY
scrollUpButtonWidth = 5
scrollUpButtonHeight = ButtonHeight
-- Draw a rectangle for the 'button'
content = content .. '<rect width="' .. scrollUpButtonWidth .. 'vw" height="' .. scrollUpButtonHeight .. 'vh" x="' .. scrollUpButtonX .. 'vw" y="' .. scrollUpButtonY .. 'vh" style="fill:rgb(100,100,100);stroke-width:1;stroke:white;" />'
-- And draw the text
content = content .. "<text x='" .. scrollUpButtonX + scrollUpButtonWidth/2 .. "%' y='" .. scrollUpButtonY + scrollUpButtonHeight/2 + 2 .. "%' font-size='7vh' fill='white' text-anchor='middle' font-family='" .. font .. "'>^</text>"

scrollDownButtonX = ButtonX + ButtonWidth + ButtonPadding
scrollDownButtonY = 100 - ButtonHeight - ButtonPadding
scrollDownButtonWidth = 5
scrollDownButtonHeight = ButtonHeight
-- Draw a rectangle for the 'button'

content = content .. '<rect width="' .. scrollDownButtonWidth .. 'vw" height="' .. scrollDownButtonHeight .. 'vh" x="' .. scrollDownButtonX .. 'vw" y="' .. scrollDownButtonY .. 'vh" style="fill:rgb(100,100,100);stroke-width:1;stroke:white;" />'
-- And draw the text
content = content .. "<text x='" .. scrollDownButtonX + scrollDownButtonWidth/2 .. "%' y='" .. scrollDownButtonY + scrollDownButtonHeight/2 + 2 .. "%' font-size='7vh' fill='white' text-anchor='middle' font-family='" .. font .. "'>v</text>"

-- A scroll bar is nice
scrollareaHeight = scrollDownButtonY-(scrollUpButtonY + scrollUpButtonHeight)

content = content .. '<rect width="' .. scrollUpButtonWidth .. 'vw" height="' .. scrollareaHeight .. 'vh" x="' .. scrollUpButtonX .. 'vw" y="' .. scrollUpButtonY + scrollUpButtonHeight .. 'vh" style="fill:rgb(80,80,80);stroke-width:1;stroke:black;" />'
scrollbarHeight = (industriesPerPage/(#IndustryUnits-industriesPerPage-3))*scrollareaHeight -- I have no idea why -3
local percentScroll = (ScrollIndex/(#IndustryUnits-industriesPerPage-3))
local scrollbarY = scrollUpButtonY + scrollUpButtonHeight + percentScroll*(scrollareaHeight)
content = content .. '<rect width="' .. scrollUpButtonWidth .. 'vw" height="' .. scrollbarHeight .. 'vh" x="' .. scrollUpButtonX .. 'vw" y="' .. scrollbarY .. 'vh" style="fill:rgb(110,110,110);stroke-width:1;stroke:white;" />'

--for _,uid in ipairs(IndustryUnits) do
--    local status = json.decode(core.getElementIndustryStatus(uid))
--    content = content .. "<text x='50%' y='20px' style='font-size:" .. tableFontSize .. ";fill:white;text-anchor:middle;font-family:" .. font .. "'>EZ Factory Monitor</text>"
--end

local headerTextX = (ButtonX + ButtonWidth) + (100-(ButtonX + ButtonWidth))/2
local headerTextY = (ButtonHeight + ButtonPadding)/2 + ButtonY
if SelectedIndex > -1 then
	content = content .. "<text x='" .. headerTextX .. "%' y='" .. headerTextY .. "%' font-size='3.5vh' font-weight='bold' fill='orange' text-anchor='middle' font-family='" .. font .. "'>" .. IndustryBySchematic[SelectedIndex][1].schematic .. "</text>"
end

 -- And lastly, use the other side to display info if there's something selected
local costColWidth = (100-ButtonWidth-ButtonPadding)/2-ButtonPadding
local selectedNameX = ButtonWidth + ButtonPadding*4 + scrollUpButtonWidth
local selectedAmountX = selectedNameX + costColWidth/1.5 + ButtonPadding
local selectedStateX = selectedAmountX + costColWidth/2 + ButtonPadding

local costOffsetY = 3.3
local costY = headerTextY + ButtonPadding*4
if SelectedIndex > -1 then
	for k,v in pairs(IndustryBySchematic[SelectedIndex]) do
		local status = json.decode(core.getElementIndustryStatus(v.id))
		local statusFontString = "rgb(200,50,50)" -- Default to some red stopped status
		if status.state == "PENDING" then
			statusFontString = "rgb(100,200,50)"
		elseif status.state == "RUNNING" then
			statusFontString = "rgb(0,200,50)"
		end
		
		local ratio = status.currentProductAmount/status.maintainProductAmount
		local r = utils.clamp(math.floor(255 - 255 * ratio),0,200)
		local g = utils.clamp(math.floor(255 * ratio),0,200)
		local colorString = "rgb(" .. r .. "," .. g .. ",50)"
		
		--system.print(k .. "," .. v)
		content = content .. "<text x='" .. selectedNameX .. "%' y='" .. costY .. "%' font-size='2vh' fill='orange' text-anchor='right' font-family='" .. font .. "'>" .. v.name .. "</text>"
		if status.maintainProductAmount > 0 and status.maintainProductAmount < 1000000 then -- Don't show bugged values
			content = content .. "<text x='" .. selectedAmountX .. "%' y='" .. costY .. "%' font-size='2.5vh' fill='" .. colorString .. "' text-anchor='right' font-family='" .. font .. "'>" .. status.currentProductAmount .. " / " .. status.maintainProductAmount .. "</text>"
		end
		content = content .. "<text x='" .. selectedStateX .. "%' y='" .. costY .. "%' font-size='2vh' fill=" .. statusFontString .. " text-anchor='middle' font-family='" .. font .. "'>" .. status.state .. "</text>"
		-- " .. math.ceil(v) .. "
		costY = costY + costOffsetY
	end
end



content = content .. "</svg>"
screen.setHTML(content)


-- Do any mouse hold stuff here
local convertedX = screen.getMouseX()*100
local convertedY = screen.getMouseY()*100
if screen.getMouseState() == 1 and convertedX > scrollDownButtonX and convertedX < scrollDownButtonX + scrollDownButtonWidth and convertedY > scrollUpButtonY + scrollUpButtonHeight and convertedY < scrollDownButtonY then
	-- Scroll to position using   scrollareaHeight
	local scrollPercent = (convertedY - (scrollUpButtonY + scrollUpButtonHeight + scrollbarHeight/2))/(scrollareaHeight-scrollDownButtonHeight)
	ScrollIndex = count*scrollPercent
	if ScrollIndex+industriesPerPage+1 > count then
		ScrollIndex = count - industriesPerPage - 1
	end
	if ScrollIndex < 0 then
		ScrollIndex = 0
	end
end