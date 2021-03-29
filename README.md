# DU-UI-Framework
A simple UI framework inspired by Java and C# Canvas (WIP)


This is heavily WIP and right now, doesn't work at all that I know of, I've been coding it out-of-game and trying to get the structure right.  I also haven't taken the time to investigate metatables to figure out exactly what I do and don't need to accomplish this.

The end-goal is to have modular, scrollable, clickable buttons/containers/components in very few lines of code, including centering and resizing for a given canvas size

An example (is in the .lua file right now as well):

```lua
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
```

This is an example for DU Orbital HUD's purposes, which would create a Rect planetList, which contains any number of buttons (one for each planet), and the buttons are clickable and scrollable with events assigned to each one.  TODO: allow definition of .onHovered
