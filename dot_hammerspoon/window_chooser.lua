-- Window chooser with multi-select support (module)
local M = {}

local ignoreApps = {
    "Finder",
    "Simulator",
    "Reminders",
}

local function isIgnoredApp(appName)
    for _, ignoredApp in ipairs(ignoreApps) do
        if appName == ignoredApp then
            return true
        end
    end
    return false
end

function M.showAndMaximize()
    local windows = {}
    for _, win in ipairs(hs.window.visibleWindows()) do
        if win:isStandard() and not isIgnoredApp(win:application():name()) then
            table.insert(windows, win)
        end
    end

    if #windows == 0 then
        hs.alert.show("No windows available")
        return
    end

    table.sort(windows, function(a, b)
        local appA = a:application():name()
        local appB = b:application():name()
        if appA ~= appB then
            return appA < appB
        end
        return a:title() < b:title()
    end)

    local selection = {}
    for i = 1, #windows do
        selection[i] = true
    end

    local function buildChoices()
        local choices = {}
        for idx, win in ipairs(windows) do
            local prefix = selection[idx] and "✓ " or "  "
            table.insert(choices, {
                text = prefix .. win:title(),
                subText = win:application():name(),
                winIdx = idx,
            })
        end
        return choices
    end

    local chooser = hs.chooser.new(function(choice)
        if choice then
            local count = 0
            for i = 1, #windows do
                if selection[i] then
                    local win = windows[i]
                    -- local screenFrame = win:screen():frame()
                    -- local frame = {
                    --     x = screenFrame.x + 8,
                    --     y = screenFrame.y + 8,
                    --     w = screenFrame.w - 16,
                    --     h = screenFrame.h - 16,
                    -- }
                    -- win:setFrame(frame)
                    win:maximize()
                    count = count + 1
                end
            end
            hs.alert.show("Maximized " .. count .. " window" .. (count ~= 1 and "s" or ""))
        end
    end)

    local eventTap = nil
    local rowPosition = 0
    local lastQuery = ""

    local function startHandler()
        eventTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
            local keyCode = event:getKeyCode()
            local currentQuery = chooser:query() or ""

            if currentQuery ~= lastQuery then
                rowPosition = 0
                lastQuery = currentQuery
            end

            local visibleIndices = {}
            for i, win in ipairs(windows) do
                local title = win:title()
                local appName = win:application():name()
                local searchText = currentQuery:lower()
                if searchText == "" or
                    title:lower():find(searchText, 1, true) or
                    appName:lower():find(searchText, 1, true) then
                    table.insert(visibleIndices, i)
                end
            end

            local numVisible = #visibleIndices

            if keyCode == 126 then -- Up arrow
                if numVisible > 0 then
                    rowPosition = (rowPosition - 1) % numVisible
                end
                return false
            elseif keyCode == 125 then -- Down arrow
                if numVisible > 0 then
                    rowPosition = (rowPosition + 1) % numVisible
                end
                return false
            elseif keyCode == 49 then -- Space
                if numVisible > 0 and rowPosition < numVisible then
                    local winIdx = visibleIndices[rowPosition + 1]
                    selection[winIdx] = not selection[winIdx]
                    chooser:choices(buildChoices())
                    chooser:selectedRow(rowPosition + 1)
                end
                return true
            end
            return false
        end)
        eventTap:start()
    end

    chooser:showCallback(function()
        rowPosition = 0
        lastQuery = ""
        startHandler()
    end)

    chooser:hideCallback(function()
        if eventTap then
            eventTap:stop()
        end
    end)

    chooser:choices(buildChoices())
    chooser:show()
end

return M
