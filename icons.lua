-- ============================================================
--  RaidMark -- icons.lua
--  Sistema de iconos arrastrables sobre el mapa
-- ============================================================

local RM = RaidMark
RM.Icons = {}
local IC = RM.Icons

-- -- Pool de frames de iconos activos ----------------------------
-- [iconId] = frame
IC.activeFrames = {}


local function GetScaledCursor()
    local x, y = GetCursorPosition()
    local s = RaidMarkMainFrame:GetEffectiveScale()
    return x/s, y/s
end



-- -- Crear un frame de icono sobre el mapa -----------------------
local function createIconFrame(iconId, iconType, x, y, label)
    local mapFrame  = RM.MapFrame.contentFrame
    local mapW      = RM.MapFrame.contentFrame:GetWidth()
    local mapH      = RM.MapFrame.contentFrame:GetHeight()
    local size      = RM.ICON_SIZE[iconType] or 32
    local texPath   = RM.ICON_TEXTURE[iconType]

    -- Frame contenedor
    local f = CreateFrame("Button", "RaidMarkIcon_" .. iconId, mapFrame)
    f:SetWidth(size)
    f:SetHeight(size)
    f:SetFrameLevel(mapFrame:GetFrameLevel() + 2)

    -- Posicionar en coordenadas normalizadas (0-1)
    f:SetPoint("CENTER", mapFrame, "TOPLEFT",
               x * mapW,
               -y * mapH)

-- Textura
    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(f)
    tex:SetTexture(texPath)

    -- FIX: Aplicar el recorte para mostrar solo el icono (calavera, cruz, etc.)
    local tc = RM.ICON_TEXCOORD and RM.ICON_TEXCOORD[iconType]
    if tc then
        tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    end
    -- Label debajo del icono (para iconos de miembro)
    if label and label ~= "" then
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOP", f, "BOTTOM", 0, -2)
        fs:SetText(label)
        fs:SetTextColor(1, 1, 1, 0.9)
        f.labelText = fs
    end

-- Boton derecho para eliminar (solo si tiene permisos)
    f:RegisterForClicks("RightButtonUp")
    f:SetScript("OnClick", function()
        -- SEGURO: Si ALT está presionado, ignoramos la interacción con el icono
        if IsAltKeyDown() then return end
        
        if RM.Permissions.CanPlace() then
            RM.Network.SendRemove(iconId)
            IC.ApplyRemove(iconId)
        else
            UIErrorsFrame:AddMessage("No tienes permisos. No eres RL ni Asistente.", 1, 0.3, 0.3, 1, 3)
        end
    end)

    -- -- Drag & Drop ---------------------------------------------
    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function()
        -- SEGURO: Si ALT está presionado, evitamos que inicie el movimiento del icono
        if IsAltKeyDown() then return end
        
        if not RM.Permissions.CanPlace() then
            UIErrorsFrame:AddMessage("No tienes permisos. No eres RL ni Asistente.", 1, 0.3, 0.3, 1, 3)
            return
        end
        f:StartMoving()
        f.isDragging = true
    end)

    f:SetScript("OnDragStop", function()
        if not f.isDragging then return end
        f:StopMovingOrSizing()
        f.isDragging = false

        -- Calcular nueva posicion normalizada
        local mLeft   = mapFrame:GetLeft()
        local mTop    = mapFrame:GetTop()
        local mW      = mapFrame:GetWidth()
        local mH      = mapFrame:GetHeight()
        local fCX     = f:GetLeft() + f:GetWidth()  / 2
        local fCY     = f:GetTop()  - f:GetHeight() / 2

        local nx = (fCX - mLeft) / mW
        local ny = (mTop - fCY)  / mH

        -- Clampear dentro del mapa
        nx = math.max(0, math.min(1, nx))
        ny = math.max(0, math.min(1, ny))

        -- Re-anclar limpio
        f:ClearAllPoints()
        f:SetPoint("CENTER", mapFrame, "TOPLEFT",
                   nx * mW, -ny * mH)

        -- Actualizar estado local
        RM.state.placedIcons[iconId].x = nx
        RM.state.placedIcons[iconId].y = ny

        -- Broadcastear (throttled)
        RM.Network.SendMove(iconId, nx, ny)
    end)

    -- Tooltip al hacer hover
    f:SetScript("OnEnter", function()
        local data = RM.state.placedIcons[iconId]
        if not data then return end
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.iconType .. (data.label ~= "" and (" -- " .. data.label) or ""))
        GameTooltip:AddLine("Click derecho para eliminar", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)

    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    f:SetMovable(true)
    f:EnableMouse(true)

    return f
end

-- -- API: Aplicar colocacion (desde red o local) ------------------
function IC.ApplyPlace(iconId, iconType, x, y, label)
    -- Guardar en estado
    RM.state.placedIcons[iconId] = {
        id       = iconId,
        iconType = iconType,
        x        = x,
        y        = y,
        label    = label or "",
    }

    -- Actualizar nextIconId si hace falta
    if iconId >= RM.state.nextIconId then
        RM.state.nextIconId = iconId + 1
    end

    -- Crear frame si el mapa esta visible
    if RM.MapFrame.contentFrame and RM.MapFrame.contentFrame:IsVisible() then
        if IC.activeFrames[iconId] then
            IC.activeFrames[iconId]:Hide()
        end
        IC.activeFrames[iconId] = createIconFrame(iconId, iconType, x, y, label)
    end
end

-- -- API: Aplicar movimiento --------------------------------------
function IC.ApplyMove(iconId, x, y)
    local data = RM.state.placedIcons[iconId]
    if not data then return end

    data.x = x
    data.y = y

    local f = IC.activeFrames[iconId]
    if f then
        local mW = RM.MapFrame.contentFrame:GetWidth()
        local mH = RM.MapFrame.contentFrame:GetHeight()
        f:ClearAllPoints()
        f:SetPoint("CENTER", RM.MapFrame.contentFrame, "TOPLEFT",
                   x * mW, -y * mH)
    end
end

-- -- API: Aplicar eliminacion -------------------------------------
function IC.ApplyRemove(iconId)
    RM.state.placedIcons[iconId] = nil

    local f = IC.activeFrames[iconId]
    if f then
        f:Hide()
        IC.activeFrames[iconId] = nil
    end
end

-- -- Limpiar todos los frames -------------------------------------
function IC.ClearAllFrames()
    for id, f in pairs(IC.activeFrames) do
        f:Hide()
    end
    IC.activeFrames = {}
end

-- -- Redibujar todos los iconos (al abrir el mapa) ----------------
function IC.RedrawAll()
    IC.ClearAllFrames()
    for iconId, data in pairs(RM.state.placedIcons) do
        IC.activeFrames[iconId] = createIconFrame(
            iconId, data.iconType, data.x, data.y, data.label
        )
    end
end

-- -- Colocar icono desde el panel (accion del RL) -----------------
-- x, y son coords normalizadas en el mapa (0-1)
function IC.PlaceNew(iconType, x, y, label)
    if not RM.Permissions.CanPlace() then return end

    local iconId = RM.NextId()
    label = label or ""

    -- Aplicar localmente
    IC.ApplyPlace(iconId, iconType, x, y, label)

    -- Broadcastear
    RM.Network.SendPlace(iconId, iconType, x, y, label)
end

-- -- Reconstruir panel lateral de miembros -----------------------
-- Se llama desde roster.lua cuando el raid cambia
function IC.RebuildRosterPanel()
    if RM.MapFrame and RM.MapFrame.RebuildRosterButtons then
        RM.MapFrame.RebuildRosterButtons()
    end
end
