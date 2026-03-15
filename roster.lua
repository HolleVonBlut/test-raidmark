-- ============================================================
--  RaidMark -- roster.lua
--  Deteccion de miembros del raid y generacion de sus iconos
-- ============================================================

local RM = RaidMark
RM.Roster = {}
local R = RM.Roster

-- -- Estado ------------------------------------------------------
R.members = {}
-- { [name] = { name, class, classFile } }

-- Colores por clase (r, g, b) en escala 0-1
local CLASS_COLORS = {
    WARRIOR = { 0.78, 0.61, 0.43 },
    PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER  = { 0.67, 0.83, 0.45 },
    ROGUE   = { 1.00, 0.96, 0.41 },
    PRIEST  = { 1.00, 1.00, 1.00 },
    MAGE    = { 0.41, 0.80, 0.94 },
    WARLOCK = { 0.58, 0.51, 0.79 },
    DRUID   = { 1.00, 0.49, 0.04 },
    SHAMAN  = { 0.14, 0.35, 1.00 },
}

local CLASS_TEXTURE = {
    WARRIOR = "icon_member_warrior",
    PALADIN = "icon_member_paladin",
    HUNTER  = "icon_member_hunter",
    ROGUE   = "icon_member_rogue",
    PRIEST  = "icon_member_priest",
    MAGE    = "icon_member_mage",
    WARLOCK = "icon_member_warlock",
    DRUID   = "icon_member_druid",
    SHAMAN  = "icon_member_shaman",
}

-- -- Reconstruir roster desde la API -----------------------------
function R.Rebuild()
    R.members = {}

    local total = GetNumRaidMembers()

    if total > 0 then
        -- En raid
        for i = 1, 40 do
            local name, rank, _, _, _, classFile = GetRaidRosterInfo(i)
            -- classFile: "WARRIOR", "PRIEST", etc.
            if name and name ~= "" then
                R.members[name] = {
                    name      = name,
                    classFile = classFile or "UNKNOWN",
                    rank      = rank,  -- 0=member, 1=assist, 2=RL
                }
            end
        end
    else
        -- En party de 5
        local partyTotal = GetNumPartyMembers()
        for i = 1, partyTotal do
            local unit = "party" .. i
            local name = UnitName(unit)
            if name then
                local _, classFile = UnitClass(unit)
                R.members[name] = {
                    name      = name,
                    classFile = classFile or "UNKNOWN",
                    rank      = 0,
                }
            end
        end
        -- Agregar al propio jugador
        local myName = UnitName("player")
        local _, myClass = UnitClass("player")
        R.members[myName] = {
            name      = myName,
            classFile = myClass or "UNKNOWN",
            rank      = 0,
        }
    end

    -- Notificar al panel de iconos para que regenere la lista
    if RM.Icons and RM.Icons.RebuildRosterPanel then
        RM.Icons.RebuildRosterPanel()
    end
end

-- -- Helpers -----------------------------------------------------

function R.GetColor(classFile)
    local c = CLASS_COLORS[classFile]
    if c then return c[1], c[2], c[3] end
    return 0.7, 0.7, 0.7  -- gris para clase desconocida
end

function R.GetTexturePath(classFile)
    local t = CLASS_TEXTURE[classFile]
    if t then
        return RM.ICON_PATH .. t
    end
    return RM.ICON_PATH .. "icon_member_unknown"
end

-- Devuelve lista ordenada de miembros (por nombre)
function R.GetSortedList()
    local list = {}
    for name, data in pairs(R.members) do
        table.insert(list, data)
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

function R.Count()
    local n = 0
    for _ in pairs(R.members) do n = n + 1 end
    return n
end
