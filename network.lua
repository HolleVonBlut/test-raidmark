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
-- Guardamos el ultimo mensaje por iconId para evitar flood
-- Solo enviamos el mas reciente si el timer lo permite
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
            -- Pedir posicion actual al MapFrame y enviarla
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
    -- Solo para pruebas en solitario
    return "WHISPER"
end

function N.SendRaw(msg)
    local channel = getChannel()
    if channel == "WHISPER" then return end  -- sin grupo, no enviamos nada
    SendAddonMessage(RM.ADDON_PREFIX, msg, channel)
end

-- -- API publica de envio -----------------------------------------

-- Colocar un icono nuevo
function N.SendPlace(iconId, iconType, x, y, label)
    label = label or ""
    N.SendRaw("PLACE" .. MSG_SEP .. iconId .. MSG_SEP
                      .. iconType .. MSG_SEP
                      .. string.format("%.4f", x) .. MSG_SEP
                      .. string.format("%.4f", y) .. MSG_SEP
                      .. label)
end

-- Mover icono (throttled -- encola en vez de enviar directo)
function N.SendMove(iconId, x, y)
    pendingMoves[iconId] = { x = x, y = y }
end

-- Eliminar icono
function N.SendRemove(iconId)
    pendingMoves[iconId] = nil
    N.SendRaw("REMOVE" .. MSG_SEP .. iconId)
end

-- Limpiar todo
function N.SendClear()
    pendingMoves = {}
    N.SendRaw("CLEAR")
end

-- Cambiar mapa
function N.SendMapChange(mapKey)
    N.SendRaw("MAP" .. MSG_SEP .. mapKey)
end

-- Cambiar permisos de asistentes
-- Cambiar permisos de asistentes
function N.SendPermissions(assistCanMove)
    local val = assistCanMove and "1" or "0"
    N.SendRaw("PERMS" .. MSG_SEP .. val)
end

-- Broadcast de version al cargar
function N.SendVersion()
    local channel = getChannel()
    if channel == "WHISPER" then return end
    N.SendRaw("VER" .. MSG_SEP .. tostring(RM.VERSION_NUM))
end

-- Notificar que este jugador libero su slot de puntero
function N.SendPointerRelease()
    if RM.state.myPointerSlot then
        local slot = RM.state.pointerSlots[RM.state.myPointerSlot]
        N.SendRaw("PTR_REL" .. MSG_SEP .. slot.color)
    end
end

-- Notificar que este jugador tomo un slot de puntero
function N.SendPointerClaim(colorName)
    N.SendRaw("PTR_CLAIM" .. MSG_SEP .. colorName)
end

-- RL limpia todos los slots de asistentes
function N.SendPointerClear()
    N.SendRaw("PTR_CLEAR")
end

-- Pedir sincronizacion al RL (cualquiera puede pedirlo)
function N.SendSyncRequest()
    N.SendRaw("SYNC_REQ")
    DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Solicitando sincronizacion...")
end

-- RL responde con estado completo a todo el raid
function N.SendSyncResponse()
    -- Primero el mapa actual
    if RM.state.currentMap then
        N.SendRaw("MAP" .. MSG_SEP .. RM.state.currentMap)
    end
    -- Luego los permisos
    local val = RM.state.assistCanMove and "1" or "0"
    N.SendRaw("PERMS" .. MSG_SEP .. val)
    -- Luego cada icono colocado
    for iconId, data in pairs(RM.state.placedIcons) do
        N.SendRaw("PLACE" .. MSG_SEP .. iconId .. MSG_SEP
                          .. data.iconType .. MSG_SEP
                          .. string.format("%.4f", data.x) .. MSG_SEP
                          .. string.format("%.4f", data.y) .. MSG_SEP
                          .. (data.label or ""))
    end
    DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Estado sincronizado enviado.")
end

-- -- Recepcion ---------------------------------------------------
function N.OnReceive(msg, channel, sender)
    -- Ignorar mensajes propios
    if sender == UnitName("player") then return end

    -- Parsear primero para conocer el comando
    local parts = {}
    for part in string.gfind(msg, "([^" .. MSG_SEP .. "]+)") do
        table.insert(parts, part)
    end
    if not parts[1] then return end
    local cmd = parts[1]

    -- SYNC_REQ: cualquier miembro puede pedirlo, solo el RL responde
    if cmd == "SYNC_REQ" then
        if RM.Permissions.IsRL() then
            N.SendSyncResponse()
        end
        return
    end

    -- El resto de comandos requieren que el sender sea RL o Assist autorizado
    if not RM.Permissions.SenderCanControl(sender) then return end

    -- -- PLACE ---------------------------------------------------
    if cmd == "PLACE" then
        local iconId   = tonumber(parts[2])
        local iconType = parts[3]
        local x        = tonumber(parts[4])
        local y        = tonumber(parts[5])
        local label    = parts[6] or ""
        if iconId and iconType and x and y then
            RM.Icons.ApplyPlace(iconId, iconType, x, y, label)
        end

    -- -- MOVE ----------------------------------------------------
    elseif cmd == "MOVE" then
        local iconId = tonumber(parts[2])
        local x      = tonumber(parts[3])
        local y      = tonumber(parts[4])
        if iconId and x and y then
            RM.Icons.ApplyMove(iconId, x, y)
        end

    -- -- REMOVE --------------------------------------------------
    elseif cmd == "REMOVE" then
        local iconId = tonumber(parts[2])
        if iconId then
            RM.Icons.ApplyRemove(iconId)
        end

    -- -- CLEAR ---------------------------------------------------
    elseif cmd == "CLEAR" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        RM.ClearAll()

    -- -- MAP -----------------------------------------------------
    elseif cmd == "MAP" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        local mapKey = parts[2]
        if mapKey then
            RM.state.currentMap = mapKey
            RM.MapFrame.LoadMap(mapKey)
        end

    -- -- PERMS ---------------------------------------------------
        -- -- PERMS ---------------------------------------------------
    elseif cmd == "PERMS" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        RM.state.assistCanMove = (parts[2] == "1")
        RM.MapFrame.UpdateAssistBtn()

    -- -- VER (version check) ------------------------------------
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

    -- -- PTR (posicion de puntero remoto) -----------------------
    elseif cmd == "PTR" then
        local colorName = parts[2]
        local px        = tonumber(parts[3])
        local py        = tonumber(parts[4])
        if colorName and px and py then
            if RM.MapFrame and RM.MapFrame.AddRemotePointerDot then
                RM.MapFrame.AddRemotePointerDot(sender, colorName, px, py)
            end
        end

    -- -- PTR_CLAIM (alguien tomo un slot) -----------------------
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

    -- -- PTR_REL (alguien libero su slot) -----------------------
elseif cmd == "PTR_REL" then
        local colorName = parts[2]
        for i, slot in ipairs(RM.state.pointerSlots) do
            if slot.color == colorName and slot.owner == sender then
                slot.owner = nil
                slot.lastX = nil -- AÑADIR ESTA
                slot.lastY = nil -- AÑADIR ESTA
                if RM.MapFrame and RM.MapFrame.UpdatePointerSlotUI then
                    RM.MapFrame.UpdatePointerSlotUI()
                end
                break
            end
        end

    -- -- PTR_CLEAR (RL limpia todos los slots de asistentes) ----
    elseif cmd == "PTR_CLEAR" then
        if not RM.Permissions.SenderIsRL(sender) then return end
        for i = 2, 4 do
            RM.state.pointerSlots[i].owner = nil
        end
        -- Si yo era asistente con slot, forzar desactivacion
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