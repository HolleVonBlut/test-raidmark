-- ============================================================
--  RaidMark -- network.lua
--  Envio y recepcion de mensajes. Throttling incluido.
-- ============================================================

local RM = RaidMark
RM.Network = {}
local N = RM.Network

-- -- Configuracion -----------------------------------------------
local SEND_INTERVAL = 0.033   -- 20 msgs/seg maximo por icono arrastrado
local MSG_SEP       = ";"   -- separador de campos (NO usar | que WoW interpreta como color code)

-- -- Cola de envio (throttling) ----------------------------------
local pendingMoves     = {}
local timeSinceSend    = 0
local throttleFrame    = CreateFrame("Frame", "RaidMarkThrottleFrame")

-- Throttle separado para el puntero (100ms = 10 msgs/seg)
local ptrTimeSinceSend = 0
local PTR_INTERVAL     = 0.033

throttleFrame:SetScript("OnUpdate", function()
    local dt = arg1
    timeSinceSend    = timeSinceSend    + dt
    ptrTimeSinceSend = ptrTimeSinceSend + dt

    -- Flush cola de movimientos de iconos
    if timeSinceSend >= SEND_INTERVAL then
        timeSinceSend = 0
        for iconId, pos in pairs(pendingMoves) do
            N.SendRaw("MOVE" .. MSG_SEP .. iconId .. MSG_SEP
                             .. string.format("%.4f", pos.x) .. MSG_SEP
                             .. string.format("%.4f", pos.y))
        end
        pendingMoves = {}
    end

    -- Flush puntero (250ms)
    if ptrTimeSinceSend >= PTR_INTERVAL then
        ptrTimeSinceSend = 0
        if RM.state.pointerActive
           and not RM.state.pointerMouseBtn
           and RM.state.myPointerSlot then
            if RM.MapFrame and RM.MapFrame.GetPointerPos then
                local px, py = RM.MapFrame.GetPointerPos()
                if px and py then
                    local slot = RM.state.pointerSlots[RM.state.myPointerSlot]
                    N.SendRaw("PTR" .. MSG_SEP .. slot.color .. MSG_SEP
                                    .. string.format("%.4f", px) .. MSG_SEP
                                    .. string.format("%.4f", py))
                end
            end
        end
    end
end)

-- -- Canal de envio -----------------------------------------------
local function getChannel()
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return "WHISPER"
end

function N.SendRaw(msg)
    local channel = getChannel()
    if channel == "WHISPER" then return end
    SendAddonMessage(RM.ADDON_PREFIX, msg, channel)
end

-- -- API publica de envio -----------------------------------------

function N.SendPlace(iconId, iconType, x, y, label)
    label = label or ""
    N.SendRaw("PLACE" .. MSG_SEP .. iconId .. MSG_SEP
                      .. iconType .. MSG_SEP
                      .. string.format("%.4f", x) .. MSG_SEP
                      .. string.format("%.4f", y) .. MSG_SEP
                      .. label)
end

function N.SendMove(iconId, x, y)
    pendingMoves[iconId] = { x = x, y = y }
end

function N.SendRemove(iconId)
    pendingMoves[iconId] = nil
    N.SendRaw("REMOVE" .. MSG_SEP .. iconId)
end

function N.SendClear()
    pendingMoves = {}
    N.SendRaw("CLEAR")
end

function N.SendMapChange(mapKey)
    N.SendRaw("MAP" .. MSG_SEP .. mapKey)
end

function N.SendPermissions(assistCanMove)
    local val = assistCanMove and "1" or "0"
    N.SendRaw("PERMS" .. MSG_SEP .. val)
end

function N.SendVersion()
    local channel = getChannel()
    if channel == "WHISPER" then return end
    N.SendRaw("VER" .. MSG_SEP .. tostring(RM.VERSION_NUM))
end

function N.SendPointerRelease()
    if RM.state.myPointerSlot then
        local slot = RM.state.pointerSlots[RM.state.myPointerSlot]
        N.SendRaw("PTR_REL" .. MSG_SEP .. slot.color)
    end
end

function N.SendPointerClaim(colorName)
    N.SendRaw("PTR_CLAIM" .. MSG_SEP .. colorName)
end

function N.SendPointerClear()
    N.SendRaw("PTR_CLEAR")
end

function N.SendSyncRequest()
    N.SendRaw("SYNC_REQ")
    DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Solicitando sincronizacion...")
end

function N.SendSyncResponse()
    if RM.state.currentMap then
        N.SendRaw("MAP" .. MSG_SEP .. RM.state.currentMap)
    end
    local val = RM.state.assistCanMove and "1" or "0"
    N.SendRaw("PERMS" .. MSG_SEP .. val)
    for iconId, data in pairs(RM.state.placedIcons) do
        N.SendRaw("PLACE" .. MSG_SEP .. iconId .. MSG_SEP
                          .. data.iconType .. MSG_SEP
                          .. string.format("%.4f", data.x) .. MSG_SEP
                          .. string.format("%.4f", data.y) .. MSG_SEP
                          .. (data.label or ""))
    end
    DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Estado sincronizado enviado.")
end

-- NUEVA FUNCION: Enviar lista de miembros
function N.SendRosterSync()
    -- FORZAR rebuild fresco desde WoW antes de enviar
    RM.Roster.Rebuild()
    
    local count = 0
    for _ in pairs(RM.Roster.members) do count = count + 1 end
    if count == 0 then return end
    
    local memberList = {}
    for name, data in pairs(RM.Roster.members) do
        table.insert(memberList, name .. ":" .. (data.classFile or "UNKNOWN") .. ":" .. (data.rank or 0))
    end
    
    N.SendRaw("ROSTER_START" .. MSG_SEP .. count)
    
    for _, memberStr in ipairs(memberList) do
        N.SendRaw("ROSTER_ADD" .. MSG_SEP .. memberStr)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Roster sincronizado (" .. count .. " miembros).")
end

-- -- Recepcion ---------------------------------------------------
function N.OnReceive(msg, channel, sender)
    if sender == UnitName("player") then return end

    local parts = {}
    for part in string.gfind(msg, "([^" .. MSG_SEP .. "]+)") do
        table.insert(parts, part)
    end
    if not parts[1] then return end
    local cmd = parts[1]

    -- SYNC_REQ
    if cmd == "SYNC_REQ" then
        if RM.Permissions.IsRL() then
            N.SendSyncResponse()
            N.SendRosterSync()
        end
        return
    end

    -- ROSTER_START
    if cmd == "ROSTER_START" then
        RM.Roster.members = {}
        return
    end
    
  -- ROSTER_ADD
    if cmd == "ROSTER_ADD" then
        local memberStr = parts[2]
        if memberStr then
            -- Manual parse porque strsplit no existe en Lua 5.0 (Vanilla)
            local name, classFile, rank
            local firstColon = string.find(memberStr, ":")
            local secondColon = string.find(memberStr, ":", firstColon + 1)
            
            if firstColon and secondColon then
                name = string.sub(memberStr, 1, firstColon - 1)
                classFile = string.sub(memberStr, firstColon + 1, secondColon - 1)
                rank = string.sub(memberStr, secondColon + 1)
            elseif firstColon then
                name = string.sub(memberStr, 1, firstColon - 1)
                classFile = string.sub(memberStr, firstColon + 1)
                rank = "0"
            else
                name = memberStr
                classFile = "UNKNOWN"
                rank = "0"
            end
            
            if name and name ~= "" then
                RM.Roster.members[name] = {
                    name = name,
                    classFile = classFile or "UNKNOWN",
                    rank = tonumber(rank) or 0,
                }
            end
        end
        return
    end

    if not RM.Permissions.SenderCanControl(sender) then return end

    if cmd == "PLACE" then
        local iconId   = tonumber(parts[2])
        local iconType = parts[3]
        local x        = tonumber(parts[4])
        local y        = tonumber(parts[5])
        local label    = parts[6] or ""
        if iconId and iconType and x and y then
            RM.Icons.ApplyPlace(iconId, iconType, x, y, label)
        end

    elseif cmd == "MOVE" then
        local iconId = tonumber(parts[2])
        local x      = tonumber(parts[3])
        local y      = tonumber(parts[4])
        if iconId and x and y then
            RM.Icons.ApplyMove(iconId, x, y)
        end

    elseif cmd == "REMOVE" then
        local iconId = tonumber(parts[2])
        if iconId then
            RM.Icons.ApplyRemove(iconId)
        end

    elseif cmd == "CLEAR" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        RM.ClearAll()

    elseif cmd == "MAP" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        local mapKey = parts[2]
        if mapKey then
            RM.state.currentMap = mapKey
            RM.MapFrame.LoadMap(mapKey)
        end

    elseif cmd == "PERMS" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        RM.state.assistCanMove = (parts[2] == "1")
        RM.MapFrame.UpdateAssistBtn()

    elseif cmd == "VER" then
        local theirVer = tonumber(parts[2]) or 0
        if theirVer > RM.VERSION_NUM then
            local msg = "ALERTA: " .. sender .. " tiene RaidMark v?" ..
                        parts[2] .. " (tu tienes v" .. RM.VERSION ..
                        "). Actualiza en github o contacta a 'holle'."
            if RM.MapFrame and RM.MapFrame.ConsoleMsg then
                RM.MapFrame.ConsoleMsg(msg, 1, 0.4, 0.1)
            end
        end

    elseif cmd == "PTR" then
        local colorName = parts[2]
        local px        = tonumber(parts[3])
        local py        = tonumber(parts[4])
        if colorName and px and py then
            if RM.MapFrame and RM.MapFrame.AddRemotePointerDot then
                RM.MapFrame.AddRemotePointerDot(sender, colorName, px, py)
            end
        end

    elseif cmd == "PTR_CLAIM" then
        local colorName = parts[2]
        for i, slot in ipairs(RM.state.pointerSlots) do
            if slot.color == colorName and not slot.owner then
                slot.owner = sender
                if RM.MapFrame and RM.MapFrame.UpdatePointerSlotUI then
                    RM.MapFrame.UpdatePointerSlotUI()
                end
                break
            end
        end

    elseif cmd == "PTR_REL" then
        local colorName = parts[2]
        for i, slot in ipairs(RM.state.pointerSlots) do
            if slot.color == colorName and slot.owner == sender then
                slot.owner = nil
                slot.lastX = nil
                slot.lastY = nil
                if RM.MapFrame and RM.MapFrame.UpdatePointerSlotUI then
                    RM.MapFrame.UpdatePointerSlotUI()
                end
                break
            end
        end

    elseif cmd == "PTR_CLEAR" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        for i = 2, 4 do
            RM.state.pointerSlots[i].owner = nil
        end
        local mySlot = RM.state.myPointerSlot
        if mySlot and mySlot > 1 then
            if RM.MapFrame and RM.MapFrame.SetPointerActive then
                RM.MapFrame.SetPointerActive(false)
            end
        end
        if RM.MapFrame and RM.MapFrame.UpdatePointerSlotUI then
            RM.MapFrame.UpdatePointerSlotUI()
        end
    end
end