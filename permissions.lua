-- ============================================================
--  RaidMark -- permissions.lua
--  Logica de roles y permisos
-- ============================================================

local RM = RaidMark
RM.Permissions = {}
local P = RM.Permissions

-- -- Roles -------------------------------------------------------

function P.IsRL()
    return IsRaidLeader() == 1 or IsRaidLeader() == true
end

function P.IsAssist()
    return IsRaidOfficer() == 1 or IsRaidOfficer() == true
end

function P.IsMember()
    return not P.IsRL() and not P.IsAssist()
end

-- -- ?Puede colocar/mover iconos? --------------------------------

function P.CanPlace()
    if P.IsRL() then return true end
    if P.IsAssist() and RM.state.assistCanMove then return true end
    return false
end

-- -- Verificar que el sender de un mensaje realmente tiene el rol -
-- (anti-spoof basico: checkeamos contra el roster actual)

function P.SenderIsRL(senderName)
    local total = GetNumRaidMembers()
    if total == 0 then
        -- en party de 5
        total = GetNumPartyMembers()
        for i = 1, total do
            local unit = "party" .. i
            if UnitName(unit) == senderName then
                return UnitIsPartyLeader(unit)
            end
        end
        return false
    end

    for i = 1, 40 do
        local name, rank = GetRaidRosterInfo(i)
        -- rank: 0=member, 1=assist, 2=leader
        if name == senderName and rank == 2 then
            return true
        end
    end
    return false
end

function P.SenderIsAssist(senderName)
    local total = GetNumRaidMembers()
    if total == 0 then return false end

    for i = 1, 40 do
        local name, rank = GetRaidRosterInfo(i)
        if name == senderName and (rank == 1 or rank == 2) then
            return true
        end
    end
    return false
end

-- Valida si el sender puede enviar comandos de control
function P.SenderCanControl(senderName)
    if P.SenderIsRL(senderName) then return true end
    if P.SenderIsAssist(senderName) and RM.state.assistCanMove then
        return true
    end
    return false
end
