-- Hyper key configuration (Cmd+Ctrl+Opt+Shift)
local hyper = { "cmd", "ctrl", "alt", "shift" }

-- Function to focus or launch an application
local function focusOrLaunch(appName)
	local app = hs.application.find(appName)
	if app then
		app:activate()
	else
		hs.application.launchOrFocus(appName)
	end
end

-- Function to focus previous window of current application
local function focusPreviousWindow()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local app = win:application()
	if not app then
		return
	end

	local windows = {}
	for _, w in ipairs(hs.window.orderedWindows()) do
		if w:application():name() == app:name() and w:isStandard() then
			table.insert(windows, w)
		end
	end

	if #windows > 1 then
		-- Focus the second window (reverse of macOS next window)
		windows[2]:focus()
	end
end
--
-- Window chooser with multi-select support
-- Window chooser moved to module: window_chooser.lua
local windowChooser = require("window_chooser")

-- Application shortcuts
-- hs.hotkey.bind(hyper, "u", function() focusOrLaunch("Safari") end)
hs.hotkey.bind(hyper, "u", function()
	focusOrLaunch("Zen")
end)
hs.hotkey.bind(hyper, "i", function()
	focusOrLaunch("Visual Studio Code")
end)
hs.hotkey.bind(hyper, "n", function()
	focusOrLaunch("Ghostty")
end)
hs.hotkey.bind(hyper, "y", function()
	focusOrLaunch("Finder")
end)
hs.hotkey.bind(hyper, "o", function()
	focusOrLaunch("Obsidian")
end)
-- hs.hotkey.bind(hyper, "s", function()
-- 	focusOrLaunch("Simulator")
-- end)
-- hs.hotkey.bind(hyper, "f", function()
-- 	focusOrLaunch("Fork")
-- end)

-- Window navigation
-- hs.hotkey.bind(hyper, "h", focusPreviousWindow)

-- Window chooser and multi-maximize
hs.hotkey.bind(hyper, "w", function()
	windowChooser.showAndMaximize()
end)

-- Show alert when config is loaded
hs.alert.show("Hammerspoon config loaded")
