-- Redesigned Event GUI with Hover, Validation, and Event Name Passing

local screenW, screenH = guiGetScreenSize()
local panelW, panelH = 600, 400
local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

local showEventGUI = false
local isCreatingEvent = false
local isSettingEventDetails = false
local eventNameInput = ""
local eventDimensionInput = ""
local eventPosition = nil
local playerList = {"No players yet."}
local selectedPlayer = nil
local isEventInProgress = false
local activeTab = "main" -- default tab saat buka GUI


local isDragging = false
local dragOffsetX, dragOffsetY = 0, 0
local headerH = 40
local hoverButtonIndex = nil
buttons = {} -- global biar bisa diakses di onClientClick

function toggleEventGUI()
    local playerClass = getElementData(localPlayer, "class")
    if playerClass ~= "Admin" then return end
    showEventGUI = not showEventGUI
    showCursor(showEventGUI)
end
addCommandHandler("toggleeventgui", toggleEventGUI)
bindKey("F7", "down", toggleEventGUI)

function isCursorOnElement(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    cx, cy = cx * screenW, cy * screenH
    return (cx >= x and cx <= x + w and cy >= y and cy <= y + h)
end

addEventHandler("onClientRender", root, function()
    if not showEventGUI then return end
    if showEventGUI and not isCursorShowing() then
        showCursor(true)
    end
    if isDragging then
        local cx, cy = getCursorPosition()
        cx, cy = cx * screenW, cy * screenH
        panelX = cx - dragOffsetX
        panelY = cy - dragOffsetY
    end

    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(20, 20, 20, 220))
    dxDrawRectangle(panelX, panelY - headerH, panelW, headerH, tocolor(90, 50, 150, 220))
    dxDrawText("EVENT MANAGER", panelX, panelY - headerH, panelX + panelW, panelY, tocolor(255, 255, 255), 1.5, "default-bold", "center", "center")

    local listX, listY, listW = panelX + 20, panelY + 50, panelW / 3 - 40
    for i, name in ipairs(playerList) do
        local rowY = listY + (i - 1) * 25
        local bgColor = (selectedPlayer == i) and tocolor(100, 100, 200, 120) or tocolor(255, 255, 255, 30)
        dxDrawRectangle(listX, rowY, listW, 25, bgColor)
        dxDrawText(name, listX + 10, rowY, listX + listW, rowY + 25, tocolor(255, 255, 255), 1, "default", "left", "center")
    end

    local btnX, btnY = panelX + panelW / 3 + 30, panelY + 50
    local btnW, btnH = 240, 40
    hoverButtonIndex = nil

    if isCreatingEvent then
        -- bagian input event name
        dxDrawText("Enter Event Name:", btnX, btnY, btnX + btnW, btnY + 30, tocolor(255, 255, 255), 1, "default-bold", "left", "top")
        dxDrawRectangle(btnX, btnY + 35, btnW, 30, tocolor(50, 50, 50, 200))
        dxDrawText(eventNameInput, btnX + 5, btnY + 35, btnX + btnW, btnY + 65, tocolor(255, 255, 255), 1, "default", "left", "center")

        local okHover = isCursorOnElement(btnX, btnY + 80, 110, 30)
        local cancelHover = isCursorOnElement(btnX + 130, btnY + 80, 110, 30)

        dxDrawRectangle(btnX, btnY + 80, 110, 30, okHover and tocolor(0, 255, 120, 220) or tocolor(0, 200, 100, 180))
        dxDrawText("OK", btnX, btnY + 80, btnX + 110, btnY + 110, tocolor(255, 255, 255), 1, "default-bold", "center", "center")

        dxDrawRectangle(btnX + 130, btnY + 80, 110, 30, cancelHover and tocolor(255, 80, 80, 220) or tocolor(200, 50, 50, 180))
        dxDrawText("Cancel", btnX + 130, btnY + 80, btnX + 240, btnY + 110, tocolor(255, 255, 255), 1, "default-bold", "center", "center")
    elseif isSettingEventDetails then
        -- bagian setting detail event
        dxDrawText("Set Event Location:", btnX, btnY, btnX + btnW, btnY + 20, tocolor(255, 255, 255), 1, "default-bold", "left", "top")
        dxDrawRectangle(btnX, btnY + 30, 240, 30, tocolor(50, 50, 50, 200))
        if eventPosition then
            dxDrawText(string.format("X: %.2f, Y: %.2f, Z: %.2f", eventPosition.x, eventPosition.y, eventPosition.z), btnX + 5, btnY + 30, btnX + 240, btnY + 60, tocolor(255, 255, 255), 1, "default", "left", "center")
        else
            dxDrawText("Belum di-set", btnX + 5, btnY + 30, btnX + 240, btnY + 60, tocolor(255, 100, 100), 1, "default", "left", "center")
        end

        dxDrawText("Dimension:", btnX, btnY + 70, btnX + 240, btnY + 90, tocolor(255, 255, 255), 1, "default-bold", "left", "top")
        dxDrawRectangle(btnX, btnY + 85, 240, 30, tocolor(50, 50, 50, 200))
        dxDrawText(eventDimensionInput, btnX + 5, btnY + 85, btnX + 240, btnY + 115, tocolor(255, 255, 255), 1, "default", "left", "center")

        dxDrawRectangle(btnX, btnY + 125, 240, 30, tocolor(0, 150, 255, 180))
        dxDrawText("Set Koordinat", btnX, btnY + 125, btnX + 240, btnY + 155, tocolor(255, 255, 255), 1, "default-bold", "center", "center")

        dxDrawRectangle(btnX, panelY + panelH - 70, 110, 30, tocolor(0, 200, 100, 180))
        dxDrawText("OK", btnX, panelY + panelH - 70, btnX + 110, panelY + panelH - 40, tocolor(255, 255, 255), 1, "default-bold", "center", "center")

        dxDrawRectangle(btnX + 130, panelY + panelH - 70, 110, 30, tocolor(200, 0, 0, 180))
        dxDrawText("End Event", btnX + 130, panelY + panelH - 70, btnX + 240, panelY + panelH - 40, tocolor(255, 255, 255), 1, "default-bold", "center", "center")
    else
        -- TAMPILKAN TAB MAIN SELALU
		dxDrawRectangle(btnX, panelY + 10, 120, 30, activeTab == "main" and tocolor(90, 90, 250, 180) or tocolor(50, 50, 50, 180))
		dxDrawText("Main", btnX, panelY + 10, btnX + 120, panelY + 40, tocolor(255, 255, 255), 1, "default-bold", "center", "center")

		-- TAMPILKAN TAB WARP TOOLS HANYA SAAT EVENT SUDAH DIBUAT
		if isEventInProgress then
			dxDrawRectangle(btnX + 130, panelY + 10, 120, 30, activeTab == "warp" and tocolor(90, 90, 250, 180) or tocolor(50, 50, 50, 180))
			dxDrawText("Tools Event", btnX + 130, panelY + 10, btnX + 250, panelY + 40, tocolor(255, 255, 255), 1, "default-bold", "center", "center")
		end

        -- local buttons = {} -- diubah jadi global, udah dideklarasiin di atas
        if activeTab == "main" then
            buttons = {}
            if not isEventInProgress then
                table.insert(buttons, {label = "Create Event", y = btnY})
            end
            table.insert(buttons, {label = "End Event", y = btnY + 60})
        elseif activeTab == "warp" then
			buttons = {
				{label = "Warp Selected", y = btnY},
				{label = "Warp All", y = btnY + 60},
				{label = "Freeze All", y = btnY + 120}, -- 🧊 NEW
				{label = "Heal All", y = btnY + 180}  -- 🧊 NEW
			}
		end
        for i, btn in ipairs(buttons) do
            local isHover = isCursorOnElement(btnX, btn.y, btnW, btnH)
            if isHover then
                hoverButtonIndex = i
                dxDrawRectangle(btnX, btn.y, btnW, btnH, tocolor(70, 130, 200, 200))
            else
                dxDrawRectangle(btnX, btn.y, btnW, btnH, tocolor(40, 40, 40, 200))
            end
            dxDrawText(btn.label, btnX, btn.y, btnX + btnW, btn.y + btnH, tocolor(255, 255, 255), 1.2, "default-bold", "center", "center")
        end
    end
end)

addEventHandler("onClientClick", root, function(btn, state)
    if not showEventGUI or btn ~= "left" or state ~= "down" then return end

    if isCreatingEvent then
        if isCursorOnElement(panelX + panelW / 3 + 30, panelY + 50 + 80, 110, 30) then
            if eventNameInput ~= "" then
                isCreatingEvent = false
                isSettingEventDetails = true
            else
                outputChatBox("Masukkan nama event terlebih dahulu!", 255, 100, 100)
            end
            return
        elseif isCursorOnElement(panelX + panelW / 3 + 30 + 130, panelY + 50 + 80, 110, 30) then
            isCreatingEvent = false
            eventNameInput = ""
            return
        end
    end

    if isSettingEventDetails then
        local btnX = panelX + panelW / 3 + 30
        local btnY = panelY + 50
        if isCursorOnElement(btnX, btnY + 125, 240, 30) then
            local x, y, z = getElementPosition(localPlayer)
            local dim = tonumber(eventDimensionInput)
            if dim then
                eventPosition = {x = x, y = y, z = z, dim = dim}
                outputChatBox("Koordinat berhasil diset!", 0, 255, 0)
            else
                outputChatBox("Dimension harus berupa angka!", 255, 0, 0)
            end
            return
        elseif isCursorOnElement(btnX, panelY + panelH - 70, 110, 30) then
            if eventPosition and tonumber(eventDimensionInput) then
                triggerServerEvent("createEvent", localPlayer, {
                    x = eventPosition.x, y = eventPosition.y, z = eventPosition.z,
                    dim = tonumber(eventDimensionInput),
                    name = eventNameInput
                })
                isSettingEventDetails = false
                isEventInProgress = true
                showEventGUI = false
                showCursor(false)
            else
                outputChatBox("Isi semua data event terlebih dahulu!", 255, 100, 100)
            end
            return
        elseif isCursorOnElement(btnX + 130, panelY + panelH - 70, 110, 30) then
            triggerServerEvent("endEventAction", localPlayer)
            isEventInProgress = false
            showEventGUI = false
            showCursor(false)
            return
        end
    end

    if isCursorOnElement(panelX, panelY - headerH, panelW, headerH) then
        local cx, cy = getCursorPosition()
        cx, cy = cx * screenW, cy * screenH
        dragOffsetX = cx - panelX
        dragOffsetY = cy - panelY
        isDragging = true
        return
    end

    local btnX = panelX + panelW / 3 + 30
    local btnY = panelY + 50

    -- TAB SWITCH CLICK DETECTION
    if isCursorOnElement(btnX, panelY + 10, 120, 30) then
		activeTab = "main"
	elseif isEventInProgress and isCursorOnElement(btnX + 130, panelY + 10, 120, 30) then
		activeTab = "warp"
	end


    -- BUTTON ACTIONS PER TAB
    if activeTab == "main" then
        local btn = buttons[hoverButtonIndex]
        if btn then
            if btn.label == "Create Event" then
                isCreatingEvent = true
            elseif btn.label == "End Event" then
                triggerServerEvent("endEventAction", localPlayer)
                isEventInProgress = false
                showEventGUI = false
                showCursor(false)
            end
        end
    elseif activeTab == "warp" then
        if hoverButtonIndex == 1 then
            if selectedPlayer and playerList[selectedPlayer] then
                local target = getPlayerFromName(playerList[selectedPlayer])
                if target then
                    triggerServerEvent("warpSelectedPlayerToEvent", localPlayer, getPlayerName(target))
                else
                    outputChatBox("Player tidak ditemukan.", 255, 0, 0)
                end
            else
                outputChatBox("Pilih player terlebih dahulu.", 255, 255, 0)
            end
        elseif hoverButtonIndex == 2 then
            triggerServerEvent("warpAllPlayersToEvent", localPlayer, getPlayerName(localPlayer))
		elseif hoverButtonIndex == 3 then
			triggerServerEvent("freezeAllEventPlayers", localPlayer)
		elseif hoverButtonIndex == 4 then
		triggerServerEvent("healAllEventPlayers", localPlayer)
		end
    end

    -- SELECT PLAYER
    local listX, listY, listW = panelX + 20, panelY + 50, panelW / 3 - 40
    for i = 1, #playerList do
        local rowY = listY + (i - 1) * 25
        if isCursorOnElement(listX, rowY, listW, 25) then
            selectedPlayer = i
        end
    end
end)

addEventHandler("onClientCharacter", root, function(char)
    if isCreatingEvent and utf8.len(eventNameInput) < 20 then
        eventNameInput = eventNameInput .. char
    elseif isSettingEventDetails and tonumber(char) and utf8.len(eventDimensionInput) < 5 then
        eventDimensionInput = eventDimensionInput .. char
    end
end)

addEventHandler("onClientKey", root, function(key, pressed)
    if pressed and key == "backspace" then
        if isCreatingEvent then
            eventNameInput = utf8.sub(eventNameInput, 1, -2)
        elseif isSettingEventDetails then
            eventDimensionInput = utf8.sub(eventDimensionInput, 1, -2)
        end
    end
end)

addEvent("updateEventPlayers", true)
addEventHandler("updateEventPlayers", root, function(players)
    playerList = {}
    for p, _ in pairs(players) do
        if isElement(p) then
            table.insert(playerList, getPlayerName(p))
        end
    end
end)

addEvent("onEventStatusChanged", true)
addEventHandler("onEventStatusChanged", root, function(status)
    isEventInProgress = status
end)

addEvent("eventEnded", true)
addEventHandler("eventEnded", root, function()
    outputChatBox("Event telah berakhir. Terima kasih telah berpartisipasi!", 255, 150, 0)
end)


-- Quick commands
local eventPos = nil
function setEventPos()
    local x, y, z = getElementPosition(localPlayer)
    local dim = getElementDimension(localPlayer)
    eventPos = { x = x, y = y, z = z, dim = dim }
    outputChatBox("Event position set!", 0, 255, 0)
end
addCommandHandler("seteventpos", setEventPos)

function createEventNow()
    if eventPos then
        triggerServerEvent("createEvent", localPlayer, eventPos)
    else
        outputChatBox("Please set the event position first using /seteventpos", 255, 0, 0)
    end
end
addCommandHandler("createevent", createEventNow)

-- ==== PLAYER EVENT JOIN GUI ====
local showJoinEventGUI = false

addCommandHandler("event", function()
    local playerClass = getElementData(localPlayer, "class")
    if isEventInProgress then
        showJoinEventGUI = not showJoinEventGUI
        showCursor(showJoinEventGUI)
    else
        outputChatBox("Belum ada event yang berlangsung.", 255, 255, 0)
    end
end)

addEventHandler("onClientRender", root, function()
    if not showJoinEventGUI then return end

    local w, h = 400, 200
    local x, y = (screenW - w)/2, (screenH - h)/2

    dxDrawRectangle(x, y, w, h, tocolor(30, 30, 30, 230))
    dxDrawText("Event Sedang Berlangsung", x, y + 20, x + w, y + 60, tocolor(255,255,255), 1.5, "default-bold", "center", "top")

    dxDrawText("Klik tombol di bawah untuk bergabung!", x, y + 60, x + w, y + 90, tocolor(200,200,200), 1.1, "default", "center", "top")

    local joinX, joinY, joinW, joinH = x + 50, y + 120, 130, 40
    local closeX = x + w - 180

    local joinHover = isCursorOnElement(joinX, joinY, joinW, joinH)
    local closeHover = isCursorOnElement(closeX, joinY, joinW, joinH)

    dxDrawRectangle(joinX, joinY, joinW, joinH, joinHover and tocolor(0,200,100,220) or tocolor(0,150,80,180))
    dxDrawText("Gabung", joinX, joinY, joinX + joinW, joinY + joinH, tocolor(255,255,255), 1.2, "default-bold", "center", "center")

    dxDrawRectangle(closeX, joinY, joinW, joinH, closeHover and tocolor(200,0,0,220) or tocolor(150,0,0,180))
    dxDrawText("Tutup", closeX, joinY, closeX + joinW, joinY + joinH, tocolor(255,255,255), 1.2, "default-bold", "center", "center")
end)

addEventHandler("onClientClick", root, function(btn, state)
    if not showJoinEventGUI or btn ~= "left" or state ~= "down" then return end
	if showJoinEventGUI and not isCursorShowing() then
    showCursor(true)
	end
    local w, h = 400, 200
    local x, y = (screenW - w)/2, (screenH - h)/2

    local joinX, joinY, joinW, joinH = x + 50, y + 120, 130, 40
    local closeX = x + w - 180

    if isCursorOnElement(joinX, joinY, joinW, joinH) then
        showJoinEventGUI = false
        showCursor(false)
        triggerServerEvent("playerJoinEvent", localPlayer) -- panggil ulang /event biar ikut
    elseif isCursorOnElement(closeX, joinY, joinW, joinH) then
        showJoinEventGUI = false
        showCursor(false)
    end
end)
