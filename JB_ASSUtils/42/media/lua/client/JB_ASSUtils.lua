--[[

 ▄▄▄██▀▀▀ ██▓ ███▄ ▄███▓ ▄▄▄▄   ▓█████  ▄▄▄       ███▄ ▄███▓▓█████▄  ██▓ ▄▄▄       ▄▄▄▄    ██▓     ▒█████
   ▒██   ▓██▒▓██▒▀█▀ ██▒▓█████▄ ▓█   ▀ ▒████▄    ▓██▒▀█▀ ██▒▒██▀ ██▌▓██▒▒████▄    ▓█████▄ ▓██▒    ▒██▒  ██▒
   ░██   ▒██▒▓██    ▓██░▒██▒ ▄██▒███   ▒██  ▀█▄  ▓██    ▓██░░██   █▌▒██▒▒██  ▀█▄  ▒██▒ ▄██▒██░    ▒██░  ██▒
▓██▄██▓  ░██░▒██    ▒██ ▒██░█▀  ▒▓█  ▄ ░██▄▄▄▄██ ▒██    ▒██ ░▓█▄   ▌░██░░██▄▄▄▄██ ▒██░█▀  ▒██░    ▒██   ██░
 ▓███▒   ░██░▒██▒   ░██▒░▓█  ▀█▓░▒████▒ ▓█   ▓██▒▒██▒   ░██▒░▒████▓ ░██░ ▓█   ▓██▒░▓█  ▀█▓░██████▒░ ████▓▒░
 ▒▓▒▒░   ░▓  ░ ▒░   ░  ░░▒▓███▀▒░░ ▒░ ░ ▒▒   ▓▒█░░ ▒░   ░  ░ ▒▒▓  ▒ ░▓   ▒▒   ▓▒█░░▒▓███▀▒░ ▒░▓  ░░ ▒░▒░▒░
 ▒ ░▒░    ▒ ░░  ░      ░▒░▒   ░  ░ ░  ░  ▒   ▒▒ ░░  ░      ░ ░ ▒  ▒  ▒ ░  ▒   ▒▒ ░▒░▒   ░ ░ ░ ▒  ░  ░ ▒ ▒░
 ░ ░ ░    ▒ ░░      ░    ░    ░    ░     ░   ▒   ░      ░    ░ ░  ░  ▒ ░  ░   ▒    ░    ░   ░ ░   ░ ░ ░ ▒
 ░   ░    ░         ░    ░         ░  ░      ░  ░       ░      ░     ░        ░  ░ ░          ░  ░    ░ ░

    JB_ASSUtils [B42] by jimbeamdiablo 2025
    Jim Beam Diablo's Area & Square Select Utilities for B42
    Steam: jbdiablo  /  Discord: jimbeamdiablo

Returns a single square, a table of selected squares or a square + a table of selected squares
Invoke with a callback function and as many arguments as your cold little heart desires

selectedSquare = { square = IsoGridSquare, isEdge = boolean }
selectedArea = { squares = {}, minX = int, maxX = int, minY = int, maxY = int, z = int, areaWidth = int, areaHeight = int, numSquares = int }

JB_ASSUtils.SelectSingleSquare(worldObjects, playerObj, mySkibidiCallbackFunction, var1, "var2", true, function() print("camelCase or die") end)

local option = ISContextMenu:getNew(context)
option:addOption("Change Highlight Color", worldObjects, JB_ASSUtils.PickColor, playerObj)

]]

JB_ASSUtils = JB_ASSUtils or {} -- global, make it local if you want

function JB_ASSUtils.PickColor(worldObjects, playerObj)
    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local buttonSize = FONT_HGT_SMALL + 6
    local borderSize = 11
    local x = (getCore():getScreenWidth() / 4) - (14 * buttonSize + borderSize * 2) / 2
    local y = (getCore():getScreenHeight() / 3) - (6 * buttonSize + borderSize * 2) / 2
    local ui = ISColorPicker:new(x, y)
    ui:initialise()
    ui:addToUIManager()
    ui:setPickedFunc(function()
        local color = ui.colors[ui.index]
        playerObj:getModData().highlightColorData = { red = color.r, green = color.g, blue = color.b }
        JB_ASSUtils.highlightColorData = { red = color.r, green = color.g, blue = color.b }
    end)
end

function JB_ASSUtils.GetPickedColor(playerObj)
    local highlightColorData
    if playerObj:getModData().highlightColorData then
        highlightColorData = playerObj:getModData().highlightColorData
    else
        highlightColorData = { red = 0.2, green = 0.5, blue = 0.7 }
        playerObj:getModData().highlightColorData = highlightColorData
    end
    return highlightColorData
end

function JB_ASSUtils.SelectSingleSquare(worldObjects, playerObj, callbackFunc, ...)
    local args = {...}
    local mouseUpOne, onTickEvent
    local selectedSquare
    local highlightColorData = JB_ASSUtils.GetPickedColor(playerObj)

    mouseUpOne = function()
        local square = getSquare(JB_ASSUtils.GetMouseCoords(playerObj))
        if JB_ASSUtils.IsMidAir(square) then return end
        Events.OnTick.Remove(onTickEvent)
        Events.OnMouseUp.Remove(mouseUpOne)
        selectedSquare = square
        if callbackFunc then
            return callbackFunc(playerObj, worldObjects, selectedSquare, args)
        else
            return selectedSquare
        end
    end

    onTickEvent = function()
        JB_ASSUtils.HighlightMouseSquare(playerObj, highlightColorData)
        if JB_ASSUtils.CancelActions(playerObj) then
            Events.OnTick.Remove(onTickEvent)
            Events.OnMouseUp.Remove(mouseUpOne)
            return nil
        end
    end
    Events.OnMouseUp.Add(mouseUpOne)
    Events.OnTick.Add(onTickEvent)
end

function JB_ASSUtils.SelectArea(worldObjects, playerObj, callbackFunc, ...)
    local args = {...}
    local mouseDownOne, mouseUpOne, onTickEvent
    local selectedArea = { squares = {} }
    local draggingArea = false
    local startX, startY, endX, endY, areaZ
    local highlightColorData = JB_ASSUtils.GetPickedColor(playerObj)
    mouseDownOne = function()
        Events.OnMouseDown.Remove(mouseDownOne)
        startX, startY, areaZ = JB_ASSUtils.GetMouseCoords(playerObj)
        draggingArea = true
        Events.OnMouseUp.Add(mouseUpOne)
    end
    mouseUpOne = function()
        Events.OnMouseUp.Remove(mouseUpOne)
        Events.OnTick.Remove(onTickEvent)
        local minX, maxX = math.min(startX, endX), math.max(startX, endX)
        local minY, maxY = math.min(startY, endY), math.max(startY, endY)
        local areaWidth = maxX - minX
        local areaHeight = maxY - minY
        for x = minX, maxX do
            for y = minY, maxY do
                local square = getSquare(x, y, areaZ)
                if not JB_ASSUtils.IsMidAir(square) then
                    table.insert(selectedArea.squares, square)
                end
            end
        end
        draggingArea = false
        table.insert(selectedArea, { minX = minX, minY = minY, maxX = maxX, maxY = maxY, z = areaZ, areaWidth = areaWidth, areaHeight = areaHeight, numSquares = #selectedArea })
        if callbackFunc then
            return callbackFunc(playerObj, worldObjects, selectedArea, args)
        else
            return selectedArea
        end
    end
    onTickEvent = function()
        if JB_ASSUtils.CancelActions(playerObj) then
            Events.OnTick.Remove(onTickEvent)
            Events.OnMouseDown.Remove(mouseDownOne)
            Events.OnMouseUp.Remove(mouseUpOne)
            return nil
        end
        endX, endY = JB_ASSUtils.GetMouseCoords(playerObj)
        if not draggingArea then
            JB_ASSUtils.HighlightMouseSquare(playerObj, highlightColorData)
        end
        if draggingArea then
            JB_ASSUtils.HighlightArea(playerObj, startX, startY, endX, endY, areaZ, highlightColorData)
        end
    end
    Events.OnMouseDown.Add(mouseDownOne)
    Events.OnTick.Add(onTickEvent)
end

function JB_ASSUtils.SelectSquareAndArea(worldObjects, playerObj, callbackFunc, ...)
    local args = {...}
    local mouseDownOne, mouseDownTwo, mouseUpOne, mouseUpTwo, onTickEvent
    local selectedSquare
    local selectedArea = { squares = {} }
    local draggingArea = false
    local startX, startY, endX, endY, areaZ
    local highlightColorData = JB_ASSUtils.GetPickedColor(playerObj)
    mouseDownOne = function() -- only "I" can prevent misfires
        Events.OnMouseDown.Remove(mouseDownOne)
        Events.OnMouseUp.Add(mouseUpOne)
    end
    mouseUpOne = function()
        Events.OnMouseUp.Remove(mouseUpOne)
        local square = getSquare(JB_ASSUtils.GetMouseCoords(playerObj))
        --local edgeSquares = JB_ASSUtils.SquareEdges(playerObj, square)
        --selectedSquare = { square = square, edgeSquares = edgeSquares }
        selectedSquare = square
        Events.OnMouseDown.Add(mouseDownTwo)
    end
    mouseDownTwo = function()
        Events.OnMouseDown.Remove(mouseDownTwo)
        startX, startY, areaZ = JB_ASSUtils.GetMouseCoords(playerObj)
        draggingArea = true
        Events.OnMouseUp.Add(mouseUpTwo)
    end
    mouseUpTwo = function()
        Events.OnMouseUp.Remove(mouseUpTwo)
        Events.OnTick.Remove(onTickEvent)
        local minX, maxX = math.min(startX, endX), math.max(startX, endX)
        local minY, maxY = math.min(startY, endY), math.max(startY, endY)
        local areaWidth = maxX - minX
        local areaHeight = maxY - minY
        for x = minX, maxX do
            for y = minY, maxY do
                local square = getSquare(x, y, areaZ)
                if not JB_ASSUtils.IsMidAir(square) then
                    table.insert(selectedArea.squares, square)
                end
            end
        end
        draggingArea = false
        table.insert(selectedArea, { minX = minX, minY = minY, maxX = maxX, maxY = maxY, areaWidth = areaWidth, areaHeight = areaHeight, numSquares = #selectedArea })
        if callbackFunc then
            return callbackFunc(playerObj, worldObjects, selectedSquare, selectedArea, args)
        else
            return selectedSquare, selectedArea
        end
    end
    onTickEvent = function()
        if JB_ASSUtils.CancelActions(playerObj) then
            -- cancel this shit
            Events.OnTick.Remove(onTickEvent)
            Events.OnMouseDown.Remove(mouseDownOne)
            Events.OnMouseDown.Remove(mouseDownTwo)
            Events.OnMouseUp.Remove(mouseUpOne)
            Events.OnMouseUp.Remove(mouseUpTwo)
            return nil
        end
        endX, endY = JB_ASSUtils.GetMouseCoords(playerObj)
        if not draggingArea then
            JB_ASSUtils.HighlightMouseSquare(playerObj, highlightColorData)
        end
        if selectedSquare then
            JB_ASSUtils.HighlightSquare(playerObj, selectedSquare,  highlightColorData)
        end
        if draggingArea then
            JB_ASSUtils.HighlightArea(playerObj, startX, startY, endX, endY, areaZ, highlightColorData)
        end
    end
    Events.OnMouseDown.Add(mouseDownOne)
    Events.OnTick.Add(onTickEvent)
end

function JB_ASSUtils.HighlightMouseSquare(playerObj, highlightColorData)
    local x, y, z = JB_ASSUtils.GetMouseCoords(playerObj)
    local square = getSquare(x,y,z)
    if JB_ASSUtils.IsMidAir(square) then return end
    addAreaHighlight(x, y, x + 1, y + 1, z, highlightColorData.red, highlightColorData.green, highlightColorData.blue, 0)
end

function JB_ASSUtils.HighlightSquare(playerObj, square, highlightColorData)
    if not square then return end
    local x, y, z = square:getX(), square:getY(), square:getZ()
    if JB_ASSUtils.IsMidAir(square) then return end
    addAreaHighlight(x, y, x + 1, y + 1, z, highlightColorData.red, highlightColorData.green, highlightColorData.blue, 0)
end

function JB_ASSUtils.HighlightArea(playerObj, startX, startY, endX, endY, areaZ, highlightColorData)
    local minX, maxX = math.min(startX, endX), math.max(startX, endX)
    local minY, maxY = math.min(startY, endY), math.max(startY, endY)
    for x = minX, maxX do
        for y = minY, maxY do
            local square = getSquare(x, y, areaZ)
            JB_ASSUtils.HighlightSquare(playerObj, square, highlightColorData)
            --addAreaHighlight(minX, minY, maxX + 1, maxY + 1, areaZ, highlightColorData.red, highlightColorData.green, highlightColorData.blue, 0)
        end
    end
end

function JB_ASSUtils.GetMouseCoords(playerObj)
    local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), playerObj:getZ())
    local z = playerObj:getZ()
    x, y = math.floor(x), math.floor(y)
    return x, y, z
end

function JB_ASSUtils.CancelActions(playerObj)
    if instanceof(playerObj, "IsoPlayer") then
        if playerObj:pressedCancelAction() or playerObj:isAttacking() then
            return true
        end
        return false
    end
    return true
end

function JB_ASSUtils.IsMidAir(square)
    if not square then return true end
    return square:getZ() > 0 and not square:getFloor()
end

-- a simple square sorter that can be janky

function JB_ASSUtils.SortSquaresClosest(playerObj, squares)
    local sortedSquares = {}
    local nextSq = playerObj:getSquare()
    while #squares > 0 do
        local tableIndex = 1
        local hugeDist = 100
        for index, square in ipairs(squares) do
            local currentDist = square:DistTo(nextSq)
            if currentDist < hugeDist then
                hugeDist = currentDist
                tableIndex = index
            end
        end
        nextSq = squares[tableIndex]
        table.insert(sortedSquares, squares[tableIndex])
        table.remove(squares, tableIndex)
    end
    return sortedSquares
end

return JB_ASSUtils -- hell ya