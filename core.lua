-- ============================================================
--  RaidMark -- core.lua
--  Estado global, inicializacion, eventos principales
-- ============================================================

RaidMark = {}
local RM = RaidMark

-- -- Version del protocolo de red --------------------------------
RM.VERSION      = "0.59"
RM.VERSION_NUM  = 2        -- numero entero para comparar (aumentar con cada release)
RM.ADDON_PREFIX = "RaidMark"

-- -- Estado global -----------------------------------------------
RM.state = {
    currentMap    = nil,
    placedIcons   = {},
    nextIconId    = 1,
    assistCanMove = false,
    mapVisible    = false,

    -- Puntero: slots de color { owner=nombre o nil, color="RED"|"BLUE"|"GREEN"|"YELLOW" }
    pointerSlots = {
        { color = "RED",    r=1,   g=0.1, b=0.1, owner=nil },  -- Slot 1: solo RL
        { color = "BLUE",   r=0.3, g=0.5, b=1,   owner=nil },
        { color = "GREEN",  r=0.2, g=0.9, b=0.2, owner=nil },
        { color = "YELLOW", r=1,   g=0.9, b=0.1, owner=nil },
    },
    myPointerSlot   = nil,    -- indice 1-4 que tiene este jugador, nil si ninguno
    pointerActive   = false,  -- si el modo puntero esta activo localmente
    pointerMouseBtn = false,  -- true mientras un boton del mouse esta presionado
}
-- -- Constantes de tipos de icono --------------------------------
RM.ICON_TYPES = {
    "TANK", "HEALER", "DPS", "DPS_MELEE", "CASTER", "ARROW",
    "CIRCLE_S", "CIRCLE_M", "CIRCLE_L", "CIRCLE_XL",
    "SKULL1", "SKULL2", "SKULL3",
    "MARK_STAR", "MARK_CIRCLE", "MARK_DIAMOND", "MARK_TRIANGLE",
    "MARK_MOON", "MARK_SQUARE", "MARK_CROSS", "MARK_SKULL",
}

-- Ruta base de texturas
RM.ICON_PATH = "Interface\\AddOns\\RaidMark\\icons\\"
RM.MAP_PATH  = "Interface\\AddOns\\RaidMark\\maps\\"

-- Textura para cada tipo de icono
-- NOTA: Solo los 22 TGAs originales de v0.24 cargan en este cliente.
-- Iconos originales de v0.24 + iconos nativos de WoW (Interface\Icons y TargetingFrame)
RM.ICON_TEXTURE = {
    TANK      = RM.ICON_PATH .. "icon_tank",
    HEALER    = RM.ICON_PATH .. "icon_healer",
    DPS       = RM.ICON_PATH .. "icon_dps",
    DPS_MELEE = RM.ICON_PATH .. "icon_dps_melee",
    CASTER    = RM.ICON_PATH .. "icon_caster",
    ARROW     = RM.ICON_PATH .. "icon_arrow",
    CIRCLE_S  = RM.ICON_PATH .. "icon_circle_S",
    CIRCLE_M  = RM.ICON_PATH .. "icon_circle_M",
    CIRCLE_L  = RM.ICON_PATH .. "icon_circle_L",
    CIRCLE_XL = RM.ICON_PATH .. "icon_circle_XL",
    MEMBER_WARRIOR  = RM.ICON_PATH .. "icon_member_warrior",
    MEMBER_PALADIN  = RM.ICON_PATH .. "icon_member_paladin",
    MEMBER_HUNTER   = RM.ICON_PATH .. "icon_member_hunter",
    MEMBER_ROGUE    = RM.ICON_PATH .. "icon_member_rogue",
    MEMBER_PRIEST   = RM.ICON_PATH .. "icon_member_priest",
    MEMBER_SHAMAN   = RM.ICON_PATH .. "icon_member_shaman",
    MEMBER_MAGE     = RM.ICON_PATH .. "icon_member_mage",
    MEMBER_WARLOCK  = RM.ICON_PATH .. "icon_member_warlock",
    MEMBER_DRUID    = RM.ICON_PATH .. "icon_member_druid",
    MEMBER_UNKNOWN  = RM.ICON_PATH .. "icon_member_unknown",
    -- Calaveras de skills nativos de WoW
    SKULL1    = "Interface\\Icons\\Ability_Rogue_Ambush",
    SKULL2    = "Interface\\Icons\\Spell_Shadow_DeathCoil",
    SKULL3    = "Interface\\Icons\\Ability_Racial_Undead",
    -- Marcas de raid (atlas unico UI-RaidTargetingIcons, SetTexCoord en icons.lua)
    MARK_STAR     = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARK_CIRCLE   = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARK_DIAMOND  = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARK_TRIANGLE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARK_MOON     = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARK_SQUARE   = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARK_CROSS    = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARK_SKULL    = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
}

-- Tamano en px de cada tipo en el mapa (+30%)
RM.ICON_SIZE = {
    TANK      = 42,  HEALER = 42,  DPS    = 42,
    DPS_MELEE = 42,  CASTER = 42,  ARROW  = 36,
    CIRCLE_S  = 62,  CIRCLE_M = 104, CIRCLE_L = 169, CIRCLE_XL = 234,
    MEMBER_WARRIOR = 31, MEMBER_PALADIN = 31, MEMBER_HUNTER = 31,
    MEMBER_ROGUE   = 31, MEMBER_PRIEST  = 31, MEMBER_SHAMAN = 31,
    MEMBER_MAGE    = 31, MEMBER_WARLOCK = 31, MEMBER_DRUID  = 31,
    MEMBER_UNKNOWN = 31,
    -- Calaveras y marcas en tamaño L
    SKULL1 = 62,  SKULL2 = 62,  SKULL3 = 62,
    MARK_STAR=53,  MARK_CIRCLE=53,  MARK_DIAMOND=53,  MARK_TRIANGLE=53,
    MARK_MOON=53,  MARK_SQUARE=53,  MARK_CROSS=53,    MARK_SKULL=53,
}


-- TexCoords para iconos que usan atlas UI-RaidTargetingIcons 256x256 (4x2 grid, cada celda 64x64)
-- Para spell icons: recortar borde dorado (5/64 a 59/64)
RM.ICON_TEXCOORD = {
    SKULL1 = {0.0781, 0.9219, 0.0781, 0.9219},
    SKULL2 = {0.0781, 0.9219, 0.0781, 0.9219},
    SKULL3 = {0.0781, 0.9219, 0.0781, 0.9219},
    MARK_STAR     = {0.0000, 0.2500, 0.0000, 0.2500},
    MARK_CIRCLE   = {0.2500, 0.5000, 0.0000, 0.2500},
    MARK_DIAMOND  = {0.5000, 0.7500, 0.0000, 0.2500},
    MARK_TRIANGLE = {0.7500, 1.0000, 0.0000, 0.2500},
    MARK_MOON     = {0.0000, 0.2500, 0.2500, 0.5000},
    MARK_SQUARE   = {0.2500, 0.5000, 0.2500, 0.5000},
    MARK_CROSS    = {0.5000, 0.7500, 0.2500, 0.5000},
    MARK_SKULL    = {0.7500, 1.0000, 0.2500, 0.5000},
}

-- -- Frame de eventos principal -----------------------------------
local eventFrame = CreateFrame("Frame", "RaidMarkEventFrame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function()
    local event = event  -- vanilla usa global 'event'

    if event == "ADDON_LOADED" then
        if arg1 == "RaidMark" then
            RM.OnLoad()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        RM.OnEnterWorld()

    elseif event == "RAID_ROSTER_UPDATE" or
           event == "PARTY_MEMBERS_CHANGED" then
        RM.Roster.Rebuild()
        RM.ValidatePointerSlots()

    elseif event == "CHAT_MSG_ADDON" then
        -- arg1=prefix, arg2=msg, arg3=channel, arg4=sender
        if arg1 == RM.ADDON_PREFIX then
            RM.Network.OnReceive(arg2, arg3, arg4)
        end
    end
end)

-- -- Inicializacion -----------------------------------------------
function RM.OnLoad()
    -- RegisterAddonMessagePrefix no existe en vanilla 1.12
    -- Los mensajes addon se reciben via CHAT_MSG_ADDON sin registro previo

    if not RaidMarkDB then
        RaidMarkDB = {}
    end

    DEFAULT_CHAT_FRAME:AddMessage("RaidMark DEBUG: MapFrame=" .. tostring(RM.MapFrame) .. " Icons=" .. tostring(RM.Icons))

    if RM.MapFrame and RM.MapFrame.Build then
        RM.MapFrame.Build()
        DEFAULT_CHAT_FRAME:AddMessage("RaidMark DEBUG: Build() ejecutado OK")
    else
        DEFAULT_CHAT_FRAME:AddMessage("RaidMark DEBUG: MapFrame.Build no encontrado")
    end

        DEFAULT_CHAT_FRAME:AddMessage(
        "RaidMark v" .. RM.VERSION .. " cargado. /rm para abrir."
    )

    -- Broadcast de version al grupo (con delay para que la red este lista)
    local vDelay = CreateFrame("Frame")
    local vTimer = 0
    vDelay:SetScript("OnUpdate", function()
        vTimer = vTimer + arg1
        if vTimer >= 3 then
            RM.Network.SendVersion()
            vDelay:SetScript("OnUpdate", nil)
        end
    end)
end

function RM.OnEnterWorld()
    RM.Roster.Rebuild()
end

-- -- Helpers globales --------------------------------------------

-- Genera un ID unico para iconos
function RM.NextId()
    local id = RM.state.nextIconId
    RM.state.nextIconId = id + 1
    return id
end


-- Validar slots de puntero contra el roster actual
function RM.ValidatePointerSlots()
    local myName = UnitName("player")
    local changed = false

    local function isInRaid(name)
        if GetNumRaidMembers() > 0 then
            for i = 1, 40 do
                local n = GetRaidRosterInfo(i)
                if n == name then return true end
            end
        else
            if UnitName("player") == name then return true end
            for i = 1, GetNumPartyMembers() do
                if UnitName("party"..i) == name then return true end
            end
        end
        return false
    end

    for i, slot in ipairs(RM.state.pointerSlots) do
        if slot.owner and not isInRaid(slot.owner) then
            slot.owner = nil
            changed = true
            -- Si era mi slot, desactivar localmente
            if RM.state.myPointerSlot == i then
                if RM.MapFrame and RM.MapFrame.SetPointerActive then
                    RM.MapFrame.SetPointerActive(false)
                end
            end
        end
    end

    -- Verificar que yo aun tengo el rango correcto para mi slot
    local mySlot = RM.state.myPointerSlot
    if mySlot == 1 and not RM.Permissions.IsRL() then
        RM.state.pointerSlots[1].owner = nil
        if RM.MapFrame and RM.MapFrame.SetPointerActive then
            RM.MapFrame.SetPointerActive(false)
        end
        changed = true
    end

    if changed and RM.MapFrame and RM.MapFrame.UpdatePointerSlotUI then
        RM.MapFrame.UpdatePointerSlotUI()
    end
end



-- Limpia todo el estado de iconos
function RM.ClearAll()
    RM.state.placedIcons = {}
    RM.state.nextIconId  = 1
    if RM.Icons and RM.Icons.ClearAllFrames then
        RM.Icons.ClearAllFrames()
    end
end

-- Cambia el mapa activo
function RM.SetMap(mapKey)
    if not RaidMark_Maps or not RaidMark_Maps[mapKey] then
        DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Mapa desconocido: " .. tostring(mapKey))
        return
    end
    RM.state.currentMap = mapKey
    if RM.MapFrame and RM.MapFrame.LoadMap then
        RM.MapFrame.LoadMap(mapKey)
    end
end

-- -- Comandos slash -----------------------------------------------
SLASH_RAIDMARK1 = "/raidmark"
SLASH_RAIDMARK2 = "/rm"

-- Helper seguro: llama funcion de MapFrame solo si ya existe
local function safeMapFrame(fn)
    if RM.MapFrame and RM.MapFrame[fn] then
        RM.MapFrame[fn]()
    else
        DEFAULT_CHAT_FRAME:AddMessage("RaidMark: UI no inicializada todavia.")
    end
end

SlashCmdList["RAIDMARK"] = function(msg)
    local cmd = string.lower(msg or "")

    if cmd == "" or cmd == "open" then
        safeMapFrame("Toggle")

    elseif cmd == "close" then
        safeMapFrame("Hide")

    elseif cmd == "clear" then
        if RM.Permissions.CanPlace() then
            RM.ClearAll()
            RM.Network.SendClear()
        else
            DEFAULT_CHAT_FRAME:AddMessage("RaidMark: No tenes permisos para limpiar.")
        end

    elseif string.sub(cmd, 1, 4) == "map " then
        local mapKey = string.sub(cmd, 5)
        if RM.Permissions.CanPlace() then
            RM.SetMap(mapKey)
            RM.Network.SendMapChange(mapKey)
        else
            DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Solo el RL puede cambiar el mapa.")
        end

    elseif cmd == "assist on" then
        if RM.Permissions.IsRL() then
            RM.state.assistCanMove = true
            RM.Network.SendPermissions(true)
            DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Asistentes pueden mover iconos.")
        end

    elseif cmd == "assist off" then
        if RM.Permissions.IsRL() then
            RM.state.assistCanMove = false
            RM.Network.SendPermissions(false)
            DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Solo el RL puede mover iconos.")
        end

    else
        DEFAULT_CHAT_FRAME:AddMessage("RaidMark comandos:")
        DEFAULT_CHAT_FRAME:AddMessage("  /rm           -- abrir/cerrar mapa")
        DEFAULT_CHAT_FRAME:AddMessage("  /rm map <key> -- cambiar mapa (twin_emperors, cthun_normal, cthun_stomach)")
        DEFAULT_CHAT_FRAME:AddMessage("  /rm clear     -- limpiar todos los iconos")
        DEFAULT_CHAT_FRAME:AddMessage("  /rm assist on/off -- permisos de asistentes")
    end
end
