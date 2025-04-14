local eventPlayers = {}
local eventTeam = createTeam("Event Participant", 255, 100, 255)
local eventInProgress = false
local eventPosition = nil -- {x=..., y=..., z=..., dim=..., name=...}

-- JOIN EVENT
addEvent("playerJoinEvent", true)
addEventHandler("playerJoinEvent", root, function()
    if getElementData(client, "class") ~= "Admin" then return end
    if not eventPlayers[client] then
        if eventPosition then
            eventPlayers[client] = true
            setPlayerTeam(client, eventTeam)
            local r, g, b = getTeamColor(eventTeam)
            setPlayerNametagColor(client, r, g, b)

            outputChatBox("You have joined the event!", client, 0, 255, 0)
            triggerClientEvent(root, "updateEventPlayers", resourceRoot, eventPlayers)
        else
            outputChatBox("The event has not started yet. Please wait.", client, 255, 0, 0)
        end
    else
        outputChatBox("You are already in the event.", client, 255, 255, 0)
    end
end)

addEvent("requestEventPlayers", true)
addEventHandler("requestEventPlayers", root, function()
    triggerClientEvent(client, "updateEventPlayers", resourceRoot, eventPlayers)
end)

-- CREATE EVENT
addEvent("createEvent", true)
addEventHandler("createEvent", root, function(pos)
    if getElementData(client, "class") ~= "Admin" then return end
    if type(pos) == "table" and pos.x and pos.y and pos.z and pos.dim ~= nil then
        eventPosition = {
            x = tonumber(pos.x),
            y = tonumber(pos.y),
            z = tonumber(pos.z),
            dim = tonumber(pos.dim),
            name = pos.name or "Unnamed"
        }
        eventInProgress = true
        triggerClientEvent(root, "onEventStatusChanged", resourceRoot, true)
        outputChatBox("[EVENT] '" .. eventPosition.name .. "' has been created! Type /event to join.", root, 0, 255, 0)
    else
        outputChatBox("[ERROR] Failed to create event: Invalid position data.", client or source, 255, 0, 0)
    end
end)

-- END EVENT
addEvent("endEventAction", true)
addEventHandler("endEventAction", root, function()
    if getElementData(client, "class") ~= "Admin" then return end
    for p in pairs(eventPlayers) do
        if isElement(p) then
            setPlayerTeam(p, nil)
            setPlayerNametagColor(p, 255, 255, 255)
            setElementHealth(p, 0)
            outputChatBox(getPlayerName(p) .. " has been removed from the event.", root, 255, 0, 0)
            triggerClientEvent(p, "eventEnded", p)
        end
    end
    eventPlayers = {}
    eventInProgress = false
    eventPosition = nil
    triggerClientEvent(root, "onEventStatusChanged", resourceRoot, false)
    triggerClientEvent(root, "updateEventPlayers", resourceRoot, eventPlayers)
    outputChatBox("The event has ended and all players were removed.", client, 255, 0, 0)
end)

-- ENDEVENT (manual command)
addCommandHandler("endevent", function(player)
    if not eventPosition then return end
    for p in pairs(eventPlayers) do
        if isElement(p) then
            setPlayerTeam(p, nil)
            setPlayerNametagColor(p, 255, 255, 255)
            triggerClientEvent(p, "eventEnded", p)
        end
    end
    eventPlayers = {}
    eventInProgress = false
    eventPosition = nil
    triggerClientEvent(root, "onEventStatusChanged", resourceRoot, false)
    outputChatBox("The event has ended.", root, 255, 0, 0)
end)

-- WARP SELECTED
addEvent("warpSelectedPlayerToEvent", true)
addEventHandler("warpSelectedPlayerToEvent", root, function(playerName)
    if getElementData(client, "class") ~= "Admin" then return end
    if not eventPosition then return end
    for player, _ in pairs(eventPlayers) do
        if isElement(player) and getPlayerName(player) == playerName then
            setElementPosition(player, eventPosition.x, eventPosition.y, eventPosition.z)
            setElementDimension(player, eventPosition.dim)
            outputChatBox("You have been warped to the event!", player, 0, 200, 255)
            break
        end
    end
end)

-- WARP ALL
addEvent("warpAllPlayersToEvent", true)
addEventHandler("warpAllPlayersToEvent", root, function(senderName)
    if getElementData(client, "class") ~= "Admin" then return end
    if not eventPosition then return end

    -- validasi ulang pengirim
    if getPlayerName(client) ~= senderName then
        outputDebugString("[Event] Nama player tidak cocok! Akses diblok.")
        return
    end

    for player, _ in pairs(eventPlayers) do
        if isElement(player) then
            setElementPosition(player, eventPosition.x, eventPosition.y, eventPosition.z)
            setElementDimension(player, eventPosition.dim)
            outputChatBox("You have been warped to the event!", player, 0, 200, 255)
        end
    end
end)

local isFrozen = false

addEvent("freezeAllEventPlayers", true)
addEventHandler("freezeAllEventPlayers", root, function()
    if getElementData(client, "class") ~= "Admin" then return end
    isFrozen = not isFrozen
    for player in pairs(eventPlayers) do
        if isElement(player) then
            toggleAllControls(player, not isFrozen)
            setElementFrozen(player, isFrozen)
        end
    end
    outputChatBox("All event players have been " .. (isFrozen and "frozen." or "unfrozen."), client, 255, 255, 0)
end)

function toggleAllControls(player, state)
    toggleControl(player, "fire", state)
    toggleControl(player, "aim_weapon", state)
    toggleControl(player, "forwards", state)
    toggleControl(player, "backwards", state)
    toggleControl(player, "left", state)
    toggleControl(player, "right", state)
    toggleControl(player, "jump", state)
    toggleControl(player, "sprint", state)
    toggleControl(player, "crouch", state)
    toggleControl(player, "enter_exit", state)
end

addEvent("healAllEventPlayers", true)
addEventHandler("healAllEventPlayers", root, function()
    if getElementData(client, "class") ~= "Admin" then return end
    for player in pairs(eventPlayers) do
        if isElement(player) then
            setElementHealth(player, 100)
            outputChatBox("You've been healed by admin!", player, 0, 255, 0)
        end
    end
    outputChatBox("All event players have been healed.", client, 0, 255, 0)
end)

