# JB_ASSUtils

This mod does nothing on it's own

Jim Beam Diablo's Area & Square Select Utilities for B42

Returns a single square, a table of selected squares or a square + a table of selected squares

Invoke with a callback function and as many arguments as your cold little heart desires

selectedSquare = IsoGridSquare
selectedArea = { squares = {}, minX = int, maxX = int, minY = int, maxY = int, z = int, areaWidth = int, areaHeight = int, numSquares = int }

Feel free to add this as a requirement, or tear it apart for it's juicy bits, or learn from it if you're new to modding.

Example:

JB_ASSUtils.SelectSingleSquare(worldObjects, playerObj, mySkibidiCallbackFunction, var1, true, function() print("camelCase or die") end)

Context Example:

local option = ISContextMenu:getNew(context)
option:addOption("Change Highlight Color", worldObjects, JB_ASSUtils.PickColor, playerObj)

Available on the Steam Workshop:
https://steamcommunity.com/sharedfiles/filedetails/?id=3439101981
