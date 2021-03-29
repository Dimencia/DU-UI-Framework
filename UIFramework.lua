
-- UI Framework, which should include layout containers and auto-placement, and buttons and scrolling of course

-- All values are taken in as pixels, and translated to width/height based on the global Canvas.width and Canvas.height
-- This translation happens only when calling getSVG(), so these can be adjusted before the calls

BaseComponent = {x = 0, y = 0, width = 0, height = 0, components = {}, zlevel = 0}

function BaseComponent:new (x,y,width,height,zlevel)
   local o = {} -- ?
   setmetatable(o, self)
   self.__index = self
   self.x = x or 0
   self.y = y or 0
   self.width = width or 0
   self.height = height or 0
   self.zlevel = zlevel or 0
   self.components = {}
   return o
end

function BaseComponent:getSVG()
	-- Really nothing to get from a BaseComponent
	return self:getChildrenSVG()
end


-- Plug in an svg type, like "text" or "rect", and let it build the rest in a basic way
function BaseComponent:getBaseSVG(svgType, extraParams)
	local x = self.x
	local y = self.y
	if self.parent then -- Adjust so x,y are local coordinates relative to the parent, if there is one
		x = x + self.parent.x
		y = y + self.parent.y
	end

	local xPercent = x/Canvas.width
	local yPercent = y/Canvas.height
	
	local svg = stringf([[<%s x="%.1f%%" y="%.1f%%"]],svgType,xPercent,yPercent)
	if self.autosize then
		local widthPercent = self.width/Canvas.width -- Scales the text to the specified width
		svg = svg .. stringf([[ textLength="%.1f%%" lengthAdjust="spacingAndGlyphs"]],widthPercent)
	end
	if self.style then
		svg = svg .. stringf([[style="%s"]],self.style)
	end
	if self.class then
		svg = svg .. stringf([[class="%s"]],self.class)
	end
	if extraParams then
		svg = svg .. extraParams
	end
	if svgType == "text" and self.text then -- TODO: Generic this to content?  Or is text the only thing that does this?
		svg = svg .. stringf([[>%s</%s>]],self.text,svgType)
	else
		svg = svg .. "/>"
	end
	
	-- Draw any children last, always.  Anything can have children.
	svg = svg .. self:getChildrenSVG()
	
	return svg
end

function BaseComponent:add(component)
	component.parent = self
	table.insert(self.components,component)
end

function BaseComponent:getChildrenSVG()
	-- Returns a string with the SVG code for all children, drawn in order of zlevel
	local value = ""
	if #self.components > 0 then
		table.sort(self.components, function(a,b) return a.zlevel < b.zlevel end)
		for k,v in ipairs(self.components) do
			value = value .. v:getSVG()
		end
	end
	return value
end

-- Returns true/false on whether or not mouse is hovering over it
-- The idea is that the implementation tests if it's hovered, and if it is, we adjust colors/borders/etc before calling getSVG on it to draw
function BaseComponent:isHovered(mouseX,mouseY)
	return mouseX >= self.x and mouseX <= self.x + self.width and mouseY >= self.y and mouseY <= self.y + self.height
end

-- TODO: onHover?

function BaseComponent:onClick()
	-- Nothing for base, just putting it here so it always exists (no nil errors) and can be overriden for things that want it
	-- Though, considering making it call its parents onClick, but not sure if that's a good idea
end

function BaseComponent:centerTo(component) 
	-- Text has a special override implementation, this works for everything else
	self.x = component.width/2 + self.width/2
	self.y = component.height/2 + self.height/2
end

-- Rearranges x,y of children to make them not overlap and not exceed width/height of container
function BaseComponent:layoutChildren(vertical, xPadding, yPadding)
	xPadding = xPadding or 5
	yPadding = yPadding or 5
	-- Arrange children based on their order in the children list
	if vertical then
		local currentX = 0
		local currentY = 0
		local widestInColumn = 0
		for k,v in pairs(self.children) do
			if currentY + v.height > self.height then
				-- Go to the next line horizontally
				-- TODO: Handle issues when children are bigger than parents
				currentX = currentX + widestInColumn + xPadding
				currentY = 0
			end
			v.x = currentX
			v.y = currentY
			currentY = currentY + v.height + yPadding
			if v.width > widestInColumn then
				widestInColumn = v.width
			end
		end
	else
		local currentX = 0
		local currentY = 0
		local tallestInRow = 0
		for k,v in pairs(self.children) do
			if currentX + v.width > self.width then
				-- Go to the next line vertically
				-- TODO: Handle issues when children are bigger than parents
				currentY = currentY + tallestInRow + yPadding
				currentX = 0
			end
			v.x = currentX
			v.y = currentY
			currentX = currentX + v.width + xPadding
			if v.height > tallestInRow then
				tallestInRow = v.height
			end
		end
	end
end

-- Adjusts the component to fit around all children.  Does not modify X or Y, only width and height
-- TODO Add a param to allow x and y modifiction
function BaseComponent:fitToChildren(xPadding, yPadding)
	local maxWidth = 0
	local maxHeight = 0
	for k,v in pairs(self.children) do
		if v.x + v.width > maxWidth then
			maxWidth = v.x+v.width
		end
		if v.y + v.height > maxHeight then
			maxHeight = v.y + v.height
		end
	end
	maxWidth = maxWidth + xPadding*2
	maxHeight = maxHeight + yPadding*2 -- Padding on both sides ofc
	self.width = maxWidth
	self.height = maxHeight
end


Canvas = BaseComponent:new(0,0,1920,1080) -- You should really only have one canvas, and it's really just to define the resolution
-- You can adjust the width/height after the fact on this global, or, dynamically at any time
-- So draw it once on HUD for example, and then change these widths/heights and draw it again on screen

local stringf = string.format -- We prob already did this tho


Label = BaseComponent:new()

function Label:new (x,y,width,text,class,style,autosize)
   o = BaseComponent:new (x,y,width) -- Width makes sense, we can scale to fit it, but not height
   setmetatable(o, self)
   self.__index = self
   self.text = text or ""
   self.class = class
   self.style = style -- Intentionally able to be nil so we can skip them
   self.autosize = autosize
   self.height = 8 -- IDK, just a guess.  This will commonly be okay... and can be set after init if not
   -- Would rather not have to specify a height each time we init if this works on its own
   
   -- TODO: Calculate width and height based on fontsize?
   -- For centering it.  But we can't really calculate it because fontsizes are all in styles
   -- Not unless we make the style not a string, but another 'class'
   -- But even then it's just an estimate, different fonts have different sizes
   -- We really only need height, but, height would be calculated via width
   -- Because the text size is limited by width.  But also should be calculated via font size in case width is higher...
   -- If autosize is on, we can roughly calculate a height given the width
   -- If it's not, we need to know the fontsize specified in the style to calculate a height
   return o
end

function Label:getSVG()
	return self:getBaseSVG("text")
end

function Label:centerTo(component, yoffset)
	-- For labels, we need to add to the style, and set the x and y to the center of the component
	-- We don't really know the height of the text, so that's a little awkward
	yoffset = yoffset or self.height/2
	
	-- For now, and because labels are usually small scale and in rare cases they're bigger than can be adjusted
	-- Let's just... do y-3 or something
	if not self.style then self.style = "" end
	self.style = self.style .. "text-anchor:middle"
	self.x = component.width/2 - self.width/2
	self.y = component.height/2 - yoffset
end




Rect = BaseComponent:new()

-- TODO: Params for borders and etc?  Or just let them be included in style?  And roundness etc?
function Rect:new (x,y,width,height,class,style)
	o = BaseComponent:new (x,y,width, height)
    setmetatable(o, self)
    self.__index = self
    self.class = class
    self.style = style -- Intentionally able to be nil so we can skip them
end

function Rect:getSVG()
	return self:getBaseSVG("rect")
end


-- Scrollbox next?  Or add scrolling to box.  Add a panel, which is just a blank baseComponent that doesn't ever call getBaseSVG
-- And panels would optionally have scrolling and optionally have borders and fill?  They're not necessarily a rect but, could require one
-- Or do we make them specifically add a rect if they want it?  That'd just be using a rect instead of a panel, they both do layouts
-- So a panel is just a rect with no fill or border.  No need for it.  Rect, or even BaseComponent, should have scroll capability built in

-- But, we should really make a good way to define classes and styles
-- Probably.  I mean, a big list of classes at the start would probably be good enough, which is what we have now
-- Not like intellisense would ever pick them up or help if we defined them in another way, it'd still be annoying like it is now to find them


-- Example:
local planetList = Rect(0,0,500,400) -- x,y,width,height
planetList.centerTo(Canvas) -- Overwrites x and y to center it
planetList.y = 100 -- We hard-set our Y probably for this
planetList.class = "rectPanel" -- Or whatever
for k,v in pairs(Atlas) do
	local label = Label(v.name)
	label.onClick = function UpdateAutopilotTarget() ToggleAutopilot() end
	planetList:add(label)
end
planetList.hScroll = true -- Enable scrollbar
planetList:layoutChildren(true, 5,5) -- Arrange children vertically, padding of 5px in X and Y
for k,v in pairs(planetList.children) do
	if v:hovered() then
		v.class = "hoveredButton"
	else
		v.class = "button"
	end
end
content = content .. planetList:getSVG() -- Looks like: <rect x=.. y=.. /><text x=.. y=..>etc</text><text .. etc>



-- Oh hey this is stupid.  We need to use Canvas:getSVG and add everything to Canvas
-- Which means we need to translate it to % as soon as we add it to canvas, and not when we call getSVG
-- Because if we give it a px value at center of 1920 and then change resolution and re-render, it'll be quite wrong
-- Either that or, much easier, have resolution changes happen only through a function which adjusts all the pixel values for the new resolution

-- No, we really should just, translate it to % as soon as it's added.  It's really easiest that way.  
-- TBH I'm not sure we shouldn't expect all values to come in as %, but doing it this way lets us copy over existing hud sections easily