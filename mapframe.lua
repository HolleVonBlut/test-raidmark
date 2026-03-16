-- ============================================================
--  RaidMark -- mapframe.lua
--  Frame principal del mapa tactico con toolbar y panel lateral
-- ============================================================

-- Debug: verificar que RaidMark existe
if not RaidMark then
    DEFAULT_CHAT_FRAME:AddMessage("RaidMark ERROR: RaidMark global es nil en mapframe.lua")
end

local RM = RaidMark
RM.MapFrame = {}
local MF = RM.MapFrame

-- Fuente +15% para labels y botones
local function BigFont(fs, base)
    fs:SetFont("Fonts\\FRIZQT__.TTF", math.floor(base * 1.15 + 0.5), "")
end
local function BigFontOutline(fs, base)
    fs:SetFont("Fonts\\FRIZQT__.TTF", math.floor(base * 1.15 + 0.5), "OUTLINE")
end

DEFAULT_CHAT_FRAME:AddMessage("RaidMark DEBUG: mapframe.lua inicio OK")

-- -- Dimensiones (+50%) --------------------------------------------
local MAP_W         = 1365  -- +30% sobre 1050
local MAP_H         = 768   -- +30% sobre 591
local TOOLBAR_H     = 48
local PANEL_W       = 312   -- +30% sobre 240
local TOTAL_W       = MAP_W + PANEL_W
local TOTAL_H       = MAP_H + TOOLBAR_H + 30  -- +30 titlebar

-- -- Crear el frame principal -------------------------------------
local mainFrame = CreateFrame("Frame", "RaidMarkMainFrame", UIParent)
mainFrame:SetWidth(TOTAL_W)
mainFrame:SetHeight(TOTAL_H)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame:SetFrameStrata("HIGH")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function() mainFrame:StartMoving() end)
mainFrame:SetScript("OnDragStop",  function() mainFrame:StopMovingOrSizing() end)
mainFrame:Hide()

-- Fondo principal
local bg = mainFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(mainFrame)
bg:SetTexture(0.05, 0.05, 0.08, 0.95)

-- Borde
local border = CreateFrame("Frame", nil, mainFrame)
border:SetAllPoints(mainFrame)
border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left=3, right=3, top=3, bottom=3 },
})
border:SetBackdropBorderColor(0.4, 0.35, 0.2, 1)

-- -- Title bar ---------------------------------------------------
local titleBar = CreateFrame("Frame", nil, mainFrame)
titleBar:SetWidth(TOTAL_W)
titleBar:SetHeight(30)
titleBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)

local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
titleBg:SetAllPoints(titleBar)
titleBg:SetTexture(0.12, 0.10, 0.05, 1)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
titleText:SetText("RaidMark -- Mesa de Tacticas")
titleText:SetTextColor(0.4, 0.8, 1, 1)

-- Boton cerrar
local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function() MF.Hide() end)

-- -- Toolbar -----------------------------------------------------
local toolbar = CreateFrame("Frame", nil, mainFrame)
toolbar:SetWidth(MAP_W)
toolbar:SetHeight(TOOLBAR_H)
toolbar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -30)

local toolbarBg = toolbar:CreateTexture(nil, "BACKGROUND")
toolbarBg:SetAllPoints(toolbar)
toolbarBg:SetTexture(0.08, 0.07, 0.04, 1)

-- -- Area de mapa (content) ---------------------------------------
local contentFrame = CreateFrame("Frame", "RaidMarkContent", mainFrame)
contentFrame:SetWidth(MAP_W)
contentFrame:SetHeight(MAP_H)
contentFrame:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, 0)
contentFrame:EnableMouse(true)

local mapTexture = contentFrame:CreateTexture(nil, "BACKGROUND")
mapTexture:SetAllPoints(contentFrame)
mapTexture:SetTexture(0.1, 0.1, 0.1, 1)   -- fondo gris hasta cargar mapa

MF.contentFrame = contentFrame

-- Click en el mapa para colocar el icono seleccionado
contentFrame:SetScript("OnMouseDown", function()
    -- SEGURO: Prioridad absoluta al puntero. Si ALT está pulsado, no colocar icono.
    if IsAltKeyDown() then return end
    
    if arg1 ~= "LeftButton" then return end
    if not RM.Permissions.CanPlace() then return end
    if not MF.selectedIconType then return end

    local mLeft = contentFrame:GetLeft()
    local mTop  = contentFrame:GetTop()
    local mW    = contentFrame:GetWidth()
local mH    = contentFrame:GetHeight()
    local cx, cy = GetCursorPosition()
    
    -- NUEVO: Lee la escala real y efectiva del mapa, no solo la de la interfaz global
    local scale = contentFrame:GetEffectiveScale() 
    
    cx = cx / scale
    cy = cy / scale
    local nx = (cx - mLeft) / mW
    local ny = (mTop - cy)  / mH

    nx = math.max(0.01, math.min(0.99, nx))
    ny = math.max(0.01, math.min(0.99, ny))

    -- Para iconos de miembro, el label es el nombre
    local label = ""
    if MF.selectedMemberName then
        label = MF.selectedMemberName
        MF.selectedMemberName = nil
    end

    RM.Icons.PlaceNew(MF.selectedIconType, nx, ny, label)
end)

-- Pausar puntero cuando se presiona cualquier boton del mouse sobre el mapa
contentFrame:SetScript("OnMouseDown", function()

if IsAltKeyDown() then return end

    RM.state.pointerMouseBtn = true
    -- logica original de colocar iconos
    if arg1 ~= "LeftButton" then return end
    if not RM.Permissions.CanPlace() then return end
    if not MF.selectedIconType then return end

    local mLeft = contentFrame:GetLeft()
    local mTop  = contentFrame:GetTop()
    local mW    = contentFrame:GetWidth()
local mH    = contentFrame:GetHeight()
    local cx, cy = GetCursorPosition()
    
    -- NUEVO: Lee la escala real y efectiva del mapa, no solo la de la interfaz global
    local scale = contentFrame:GetEffectiveScale() 
    
    cx = cx / scale
    cy = cy / scale
    local nx = (cx - mLeft) / mW
    local ny = (mTop - cy)  / mH
    nx = math.max(0.01, math.min(0.99, nx))
    ny = math.max(0.01, math.min(0.99, ny))
    local label = ""
    if MF.selectedMemberName then
        label = MF.selectedMemberName
        MF.selectedMemberName = nil
    end
    RM.Icons.PlaceNew(MF.selectedIconType, nx, ny, label)
end)

contentFrame:SetScript("OnMouseUp", function()
    RM.state.pointerMouseBtn = false
end)


-- -- Panel lateral -----------------------------------------------
local sidePanel = CreateFrame("Frame", nil, mainFrame)
sidePanel:SetWidth(PANEL_W)
sidePanel:SetHeight(TOTAL_H - 30)
sidePanel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", MAP_W, -30)

local sideBg = sidePanel:CreateTexture(nil, "BACKGROUND")
sideBg:SetAllPoints(sidePanel)
sideBg:SetTexture(0.07, 0.06, 0.03, 1)

-- Separador vertical
local sep = sidePanel:CreateTexture(nil, "ARTWORK")
sep:SetWidth(1)
sep:SetHeight(TOTAL_H - 30)
sep:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 0, 0)
sep:SetTexture(0.4, 0.35, 0.2, 0.8)

-- -- Helper: boton de icono en el panel --------------------------
local function makeIconButton(parent, iconType, texPath, size, xPos, yPos, tooltip)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(size)
    btn:SetHeight(size)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xPos, yPos)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(btn)
    tex:SetTexture(texPath)
    -- Aplicar coordenadas de atlas si es necesario
    local tc = RM.ICON_TEXCOORD and RM.ICON_TEXCOORD[iconType]
    if tc then
        tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    end

    -- Highlight de seleccion
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(btn)
    hl:SetTexture(1, 1, 1, 0.2)

    btn:SetScript("OnClick", function()
        MF.selectedIconType   = iconType
        MF.selectedMemberName = nil
        MF.HighlightSelected(btn)
    end)

    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
        GameTooltip:SetText(tooltip or iconType)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:EnableMouse(true)
    return btn
end

-- -- Botones de iconos de rol ------------------------------------
local ICON_BTN = 46  -- tamanio del boton de icono en el panel
local ICON_GAP = 4

local ROLE_BUTTONS = {
    { type="TANK",      label="Tank",   x=8,                        y=-20 },
    { type="HEALER",    label="Healer", x=8+ICON_BTN+ICON_GAP,      y=-20 },
    { type="DPS",       label="DPS",    x=8+(ICON_BTN+ICON_GAP)*2,  y=-20 },
    { type="DPS_MELEE", label="Melee",  x=8+(ICON_BTN+ICON_GAP)*3,  y=-20 },
    { type="CASTER",    label="Caster", x=8,                        y=-20-(ICON_BTN+ICON_GAP) },
    { type="ARROW",     label="Flecha", x=8+ICON_BTN+ICON_GAP,      y=-20-(ICON_BTN+ICON_GAP) },
}

local AREAS_Y_START = -20 - (ICON_BTN+ICON_GAP)*2 - 20  -- offset para seccion Circulos

local CIRCLE_BUTTONS = {
    { type="CIRCLE_S",  label="S",  x=8,                        y=AREAS_Y_START },
    { type="CIRCLE_M",  label="M",  x=8+ICON_BTN+ICON_GAP,      y=AREAS_Y_START },
    { type="CIRCLE_L",  label="L",  x=8+(ICON_BTN+ICON_GAP)*2,  y=AREAS_Y_START },
    { type="CIRCLE_XL", label="XL", x=8+(ICON_BTN+ICON_GAP)*3,  y=AREAS_Y_START },
}

local SKULLS_Y_START = AREAS_Y_START - (ICON_BTN+ICON_GAP)*2 - 20

local SKULL_BUTTONS = {
    { type="SKULL1",       label="Ambush",   x=8,                        y=SKULLS_Y_START },
    { type="SKULL2",       label="DCoil",    x=8+ICON_BTN+ICON_GAP,      y=SKULLS_Y_START },
    { type="SKULL3",       label="Undead",   x=8+(ICON_BTN+ICON_GAP)*2,  y=SKULLS_Y_START },
    { type="MARK_STAR",    label="Estrella", x=8,                        y=SKULLS_Y_START-(ICON_BTN+ICON_GAP) },
    { type="MARK_CIRCLE",  label="Circulo",  x=8+ICON_BTN+ICON_GAP,      y=SKULLS_Y_START-(ICON_BTN+ICON_GAP) },
    { type="MARK_DIAMOND", label="Diamante", x=8+(ICON_BTN+ICON_GAP)*2,  y=SKULLS_Y_START-(ICON_BTN+ICON_GAP) },
    { type="MARK_TRIANGLE",label="Triangulo",x=8+(ICON_BTN+ICON_GAP)*3,  y=SKULLS_Y_START-(ICON_BTN+ICON_GAP) },
    { type="MARK_MOON",    label="Luna",     x=8,                        y=SKULLS_Y_START-(ICON_BTN+ICON_GAP)*2 },
    { type="MARK_SQUARE",  label="Cuadrado", x=8+ICON_BTN+ICON_GAP,      y=SKULLS_Y_START-(ICON_BTN+ICON_GAP)*2 },
    { type="MARK_CROSS",   label="Cruz",     x=8+(ICON_BTN+ICON_GAP)*2,  y=SKULLS_Y_START-(ICON_BTN+ICON_GAP)*2 },
    { type="MARK_SKULL",   label="Calavera", x=8+(ICON_BTN+ICON_GAP)*3,  y=SKULLS_Y_START-(ICON_BTN+ICON_GAP)*2 },
}

local MEMBER_PANEL_Y_OFFSET = SKULLS_Y_START - (ICON_BTN+ICON_GAP)*3 - 20

MF.selectedIconType   = nil
MF.selectedMemberName = nil
MF.allButtons         = {}

-- Puntero local y remoto
local localPointerFrame      = nil
local localPointerX          = 0
local localPointerY          = 0
local remotePointerPaths     = {}
local lastPointerReceived    = {}   -- [colorName] = GetTime() del ultimo PTR recibido
local POINTER_SIZE           = 24
local POINTER_PATH_MAX       = 100
local POINTER_PATH_TTL       = 2.0
local POINTER_INACTIVITY_TTL = 10   -- segundos sin PTR para auto-liberar slot



-- -- Frame de actualizacion del puntero local -------------------
local pointerUpdateFrame = CreateFrame("Frame", "RaidMarkPointerUpdate")
pointerUpdateFrame:SetScript("OnUpdate", function()
    if not RM.state.pointerActive then return end
    if not localPointerFrame then return end
    if RM.state.pointerMouseBtn or not IsAltKeyDown() then
        localPointerFrame:Hide()
        return
    end

    -- Verificar que el cursor este sobre el contentFrame
    local mLeft = contentFrame:GetLeft()
    local mTop  = contentFrame:GetTop()
    local mW    = contentFrame:GetWidth()
    local mH    = contentFrame:GetHeight()
    if not mLeft then return end

local cx, cy = GetCursorPosition()
    
    -- NUEVO: Aplica la misma corrección al puntero visual
    local scale  = contentFrame:GetEffectiveScale() 
    
    cx = cx / scale
    cy = cy / scale

    -- Solo mostrar si el cursor esta dentro del mapa

    -- Solo mostrar si el cursor esta dentro del mapa
    if cx < mLeft or cx > mLeft + mW or cy < mTop - mH or cy > mTop then
        localPointerFrame:Hide()
        return
    end

    -- Posicion normalizada
    localPointerX = (cx - mLeft) / mW
    localPointerY = (mTop - cy)  / mH
    localPointerX = math.max(0.01, math.min(0.99, localPointerX))
    localPointerY = math.max(0.01, math.min(0.99, localPointerY))

    localPointerFrame:ClearAllPoints()
    localPointerFrame:SetPoint("CENTER", contentFrame, "TOPLEFT",
                               localPointerX * mW, -localPointerY * mH)
    localPointerFrame:Show()
end)

-- Devuelve la ultima posicion normalizada del puntero local (para network.lua)
function MF.GetPointerPos()
    if localPointerFrame and localPointerFrame:IsVisible() then
        return localPointerX, localPointerY
    end
    return nil, nil
end

-- Función auxiliar para crear físicamente el punto del rastro
function MF.CreateShadowFrame(path, px, py, sr, sg, sb)
    local dot = CreateFrame("Frame", nil, MF.contentFrame)
    dot:SetWidth(POINTER_SIZE)
    dot:SetHeight(POINTER_SIZE)
    dot:SetFrameLevel(MF.contentFrame:GetFrameLevel() + 3)
    local mW = MF.contentFrame:GetWidth()
    local mH = MF.contentFrame:GetHeight()
    dot:SetPoint("CENTER", MF.contentFrame, "TOPLEFT", px * mW, -py * mH)

    local tex = dot:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(dot)
    tex:SetTexture(RM.ICON_PATH .. "icon_circle_S")
    tex:SetVertexColor(sr, sg, sb, 1.0)

    dot.ttl, dot.elapsed = POINTER_PATH_TTL, 0
    dot:SetScript("OnUpdate", function()
        dot.elapsed = dot.elapsed + arg1
        if dot.elapsed >= dot.ttl then
            dot:Hide()
            dot:SetScript("OnUpdate", nil)
        else
            local fade = dot.elapsed / dot.ttl
            if fade > 0.7 then
                tex:SetVertexColor(sr, sg, sb, (1 - fade) / 0.3)
            end
        end
    end)
    table.insert(path, dot)
    if table.getn(path) > POINTER_PATH_MAX then
        local oldest = table.remove(path, 1)
        oldest:Hide()
        oldest:SetScript("OnUpdate", nil)
    end
end

-- Nueva versión con interpolación para rastro unido
function MF.AddRemotePointerDot(sender, colorName, px, py)
    lastPointerReceived[colorName] = GetTime()
    
    local slot = nil
    for _, s in ipairs(RM.state.pointerSlots) do
        if s.color == colorName then slot = s; break end
    end
    if not slot then return end

    if not remotePointerPaths[sender] then remotePointerPaths[sender] = {} end
    local path = remotePointerPaths[sender]

    -- Lógica de Interpolación:
    local stepSize = 0.012  -- Densidad del rastro (menor = más sólido)
    local lastX = slot.lastX or px
    local lastY = slot.lastY or py
    
    local dx = px - lastX
    local dy = py - lastY
    local dist = math.sqrt(dx*dx + dy*dy)

    -- Si el movimiento es normal (menor al 25% del mapa), rellenamos el hueco
    if dist > 0 and dist < 0.25 then
        local steps = math.floor(dist / stepSize)
        if steps > 0 then
            for i = 1, steps do
                local t = i / steps
                MF.CreateShadowFrame(path, lastX + dx*t, lastY + dy*t, slot.r, slot.g, slot.b)
            end
        else
            MF.CreateShadowFrame(path, px, py, slot.r, slot.g, slot.b)
        end
    else
        MF.CreateShadowFrame(path, px, py, slot.r, slot.g, slot.b)
    end

    -- Guardamos la posición actual para el próximo cálculo
    slot.lastX, slot.lastY = px, py
end

-- Mini consola dinamica con fade in/out entre mensajes idle
local consolePriorityTimer = 0
local consoleIdleIndex     = 1
local CONSOLE_PRIORITY_TTL = 5
local CONSOLE_SHOW_TIME    = 3.5   -- segundos visible cada mensaje
local CONSOLE_FADE_SPEED   = 2.0   -- alpha por segundo

local consoleFadeDir    = 0    -- 0=visible, 1=fade out, -1=fade in
local consoleFadeAlpha  = 1.0
local consoleShowTimer  = CONSOLE_SHOW_TIME
local consoleCurrentMsg = nil  -- { text, r, g, b }

local consoleIdleMessages = {
    { text = "RaidMark v" .. RM.VERSION,              r = 0.4, g = 0.7, b = 1.0 },
    { text = "By Holle - South Seas Server",           r = 0.5, g = 0.5, b = 0.5 },
    { text = "Puntero: activa check, mueve sin click", r = 0.8, g = 0.8, b = 0.3 },
    { text = "Sync (RL): limpia slots de puntero",     r = 0.3, g = 1.0, b = 0.4 },
}

local function consoleApplyAlpha()
    if not MF.consoleText or not consoleCurrentMsg then return end
    MF.consoleText:SetTextColor(
        consoleCurrentMsg.r, consoleCurrentMsg.g, consoleCurrentMsg.b, consoleFadeAlpha)
end

local function consoleNextIdle()
    consoleCurrentMsg = consoleIdleMessages[consoleIdleIndex]
    consoleIdleIndex = math.mod(consoleIdleIndex, table.getn(consoleIdleMessages)) + 1
    if MF.consoleText then
        MF.consoleText:SetText(consoleCurrentMsg.text)
    end
    consoleApplyAlpha()
end

function MF.ConsoleMsg(text, r, g, b)
    r = r or 0.7
    g = g or 0.9
    b = b or 1
    consolePriorityTimer = CONSOLE_PRIORITY_TTL
    consoleFadeDir   = 0
    consoleFadeAlpha = 1.0
    consoleCurrentMsg = { text = text, r = r, g = g, b = b }
    if MF.consoleText then
        MF.consoleText:SetText(text)
        MF.consoleText:SetTextColor(r, g, b, 1)
    end
end

-- Detector de inactividad de punteros + fade de consola
local INACTIVITY_CHECK = 0
local consoleUpdateFrame = CreateFrame("Frame", "RaidMarkConsoleUpdate")
consoleUpdateFrame:SetScript("OnUpdate", function()
    local dt = arg1

    -- Detector de inactividad de slots de puntero
    INACTIVITY_CHECK = INACTIVITY_CHECK + dt
    if INACTIVITY_CHECK >= 2 then
        INACTIVITY_CHECK = 0
        local now = GetTime()
        local changed = false
        for i, slot in ipairs(RM.state.pointerSlots) do
            if slot.owner and slot.owner ~= UnitName("player") then
                local lastTime = lastPointerReceived[slot.color] or 0
if lastTime > 0 and (now - lastTime) > POINTER_INACTIVITY_TTL then
                    slot.owner = nil
                    slot.lastX = nil -- Limpiar memoria de posición
                    slot.lastY = nil -- Limpiar memoria de posición
                    lastPointerReceived[slot.color] = nil
                    changed = true
                    if RM.state.myPointerSlot == i then
                        if MF.SetPointerActive then MF.SetPointerActive(false) end
                    end
                end
            end
        end
        if changed then MF.UpdatePointerSlotUI() end
    end

    -- Fade de consola
    if consolePriorityTimer > 0 then
        consolePriorityTimer = consolePriorityTimer - dt
        if consolePriorityTimer <= 0 then
            consolePriorityTimer = 0
            consoleFadeDir   = -1
            consoleFadeAlpha = 0
            consoleNextIdle()
            consoleShowTimer = CONSOLE_SHOW_TIME
        end
        return
    end

    if not MF.consoleText then return end

    if consoleFadeDir == 0 then
        consoleShowTimer = consoleShowTimer - dt
        if consoleShowTimer <= 0 then
            consoleFadeDir = 1  -- empieza fade out
        end

    elseif consoleFadeDir == 1 then
        consoleFadeAlpha = consoleFadeAlpha - CONSOLE_FADE_SPEED * dt
        if consoleFadeAlpha <= 0 then
            consoleFadeAlpha = 0
            consoleFadeDir   = -1  -- empieza fade in del siguiente
            consoleNextIdle()
        end
        consoleApplyAlpha()

    elseif consoleFadeDir == -1 then
        consoleFadeAlpha = consoleFadeAlpha + CONSOLE_FADE_SPEED * dt
        if consoleFadeAlpha >= 1 then
            consoleFadeAlpha = 1
            consoleFadeDir   = 0
            consoleShowTimer = CONSOLE_SHOW_TIME
        end
        consoleApplyAlpha()
    end
end)

-- Actualizar indicadores visuales de slots en la toolbar
function MF.UpdatePointerSlotUI()
    if not MF.slotIndicators then return end
    for i, ind in ipairs(MF.slotIndicators) do
        local slot = RM.state.pointerSlots[i]
        if slot.owner or (i == 1 and RM.Permissions.IsRL()) then
            ind:SetAlpha(1.0)
        else
            ind:SetAlpha(0.25)
        end
    end
end

local function buildPointerLocalFrame()
    localPointerFrame = CreateFrame("Frame", nil, contentFrame)
    localPointerFrame:SetWidth(POINTER_SIZE)
    localPointerFrame:SetHeight(POINTER_SIZE)
    localPointerFrame:SetFrameLevel(contentFrame:GetFrameLevel() + 5)
    local tex = localPointerFrame:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(localPointerFrame)
    tex:SetTexture(RM.ICON_PATH .. "icon_circle_S")
    tex:SetVertexColor(1, 0.1, 0.1, 0.9)  -- rojo por defecto, cambia con el slot
    localPointerFrame.tex = tex
    localPointerFrame:Hide()
end

local function buildRoleButtons()
    -- Label "Iconos de Rol" con fondo para que sea legible
    local lbl = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    lbl:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 8, -6)
    lbl:SetText("Iconos de Rol")
    BigFont(lbl, 12)
    lbl:SetTextColor(1, 0.9, 0.4, 1)

    for _, def in ipairs(ROLE_BUTTONS) do
        -- Tooltip label debajo del icono
        local tipLbl = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        tipLbl:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", def.x, def.y - ICON_BTN - 1)
        tipLbl:SetWidth(ICON_BTN)
        tipLbl:SetText(def.label)
        tipLbl:SetTextColor(0.8, 0.8, 0.6, 1)
        local btn = makeIconButton(
            sidePanel, def.type,
            RM.ICON_TEXTURE[def.type],
            ICON_BTN, def.x, def.y, def.label
        )
        table.insert(MF.allButtons, btn)
    end

    -- Label "Areas" con fondo legible
    local lbl2 = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    lbl2:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 8, AREAS_Y_START + 14)
    lbl2:SetText("Circulos")
    BigFont(lbl2, 12)
    lbl2:SetTextColor(1, 0.9, 0.4, 1)

    for _, def in ipairs(CIRCLE_BUTTONS) do
        local tipLbl = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        BigFont(tipLbl, 10)
        tipLbl:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", def.x, def.y - ICON_BTN - 1)
        tipLbl:SetWidth(ICON_BTN)
        tipLbl:SetText(def.label)
        tipLbl:SetTextColor(0.8, 0.8, 0.6, 1)
        local btn = makeIconButton(
            sidePanel, def.type,
            RM.ICON_TEXTURE[def.type],
            ICON_BTN, def.x, def.y, def.label
        )
        table.insert(MF.allButtons, btn)
    end

    -- Label seccion Calaveras y Marcas
    local lbl4 = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    lbl4:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 8, SKULLS_Y_START + 14)
    BigFont(lbl4, 12)
    lbl4:SetText("Calaveras / Marcas")
    lbl4:SetTextColor(1, 0.9, 0.4, 1)

    for _, def in ipairs(SKULL_BUTTONS) do
        local tipLbl = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        BigFont(tipLbl, 10)
        tipLbl:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", def.x, def.y - ICON_BTN - 1)
        tipLbl:SetWidth(ICON_BTN)
        tipLbl:SetText(def.label)
        tipLbl:SetTextColor(0.8, 0.8, 0.6, 1)
        local btn = makeIconButton(
            sidePanel, def.type,
            RM.ICON_TEXTURE[def.type],
            ICON_BTN, def.x, def.y, def.label
        )
        table.insert(MF.allButtons, btn)
    end

    -- Label "Miembros del Raid"
    local lbl3 = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    lbl3:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 8, MEMBER_PANEL_Y_OFFSET + 14)
    lbl3:SetText("Miembros del Raid")
    BigFont(lbl3, 12)
    lbl3:SetTextColor(1, 0.9, 0.4, 1)
end

-- -- Panel de miembros del raid (scrollable) ----------------------
local MEMBER_PANEL_Y    = MEMBER_PANEL_Y_OFFSET or -175
local MEMBER_BTN_H      = 22
local MEMBER_BTN_W      = PANEL_W - 42

-- Altura disponible desde el inicio del panel hasta el fondo de la ventana
local SCROLL_H = TOTAL_H - TOOLBAR_H - 30 - math.abs(MEMBER_PANEL_Y) - 20

-- Altura minima garantizada de 80px para el panel de miembros
local SAFE_SCROLL_H = math.max(80, SCROLL_H)

local memberScrollFrame = CreateFrame("ScrollFrame", "RaidMarkMemberScroll", sidePanel, "UIPanelScrollFrameTemplate")
memberScrollFrame:SetWidth(PANEL_W - 28)        -- espacio para la scrollbar a la derecha
memberScrollFrame:SetHeight(SAFE_SCROLL_H)
memberScrollFrame:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 4, MEMBER_PANEL_Y)
memberScrollFrame:EnableMouseWheel(true)
memberScrollFrame:SetScript("OnMouseWheel", function()
    local delta   = arg1
    local current = memberScrollFrame:GetVerticalScroll()
    local max     = memberScrollFrame:GetVerticalScrollRange()
    local newVal  = current - (delta * (MEMBER_BTN_H + 2) * 3)
    if newVal < 0 then newVal = 0 end
    if newVal > max then newVal = max end
    memberScrollFrame:SetVerticalScroll(newVal)
end)

local memberContent = CreateFrame("Frame", "RaidMarkMemberContent", memberScrollFrame)
memberContent:SetWidth(PANEL_W - 42)   -- igual que MEMBER_BTN_W
memberContent:SetHeight(1)
memberScrollFrame:SetScrollChild(memberContent)

-- Divider
local divider = sidePanel:CreateTexture(nil, "ARTWORK")
divider:SetWidth(PANEL_W - 16)
divider:SetHeight(1)
divider:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 8, MEMBER_PANEL_Y - 4)
divider:SetTexture(0.4, 0.35, 0.2, 0.6)

local memberLabel = sidePanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
memberLabel:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 8, MEMBER_PANEL_Y - 10)
memberLabel:SetText("Miembros del Raid")
 memberLabel:SetTextColor(0.8, 0.67, 0.27, 1)

-- Botones de miembros (se reconstruyen con el roster)
local memberButtons = {}

function MF.RebuildRosterButtons()
    -- Limpiar botones previos
    for _, btn in ipairs(memberButtons) do
        btn:Hide()
    end
    memberButtons = {}

    local members = RM.Roster.GetSortedList()
    local totalH  = 0

    for i, data in ipairs(members) do
        local yOff = -(i-1) * (MEMBER_BTN_H + 2)

        local btn = CreateFrame("Button", nil, memberContent)
        btn:SetWidth(MEMBER_BTN_W)
        btn:SetHeight(MEMBER_BTN_H)
        btn:SetPoint("TOPLEFT", memberContent, "TOPLEFT", 0, yOff)

        -- Fondo
        local fbg = btn:CreateTexture(nil, "BACKGROUND")
        fbg:SetAllPoints(btn)
        local r,g,b = RM.Roster.GetColor(data.classFile)
        fbg:SetTexture(r*0.3, g*0.3, b*0.3, 0.7)

        -- Icono de clase pequeno
        local icn = btn:CreateTexture(nil, "ARTWORK")
        icn:SetWidth(16)
        icn:SetHeight(16)
        icn:SetPoint("LEFT", btn, "LEFT", 2, 0)
        icn:SetTexture(RM.Roster.GetTexturePath(data.classFile))

        -- Nombre
        local nm = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        BigFont(nm, 10)
        nm:SetPoint("LEFT", btn, "LEFT", 22, 0)
        nm:SetText(data.name)
        nm:SetTextColor(r, g, b, 1)

        -- Highlight
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(btn)
        hl:SetTexture(1, 1, 1, 0.15)

        btn:EnableMouse(true)

        -- Captura local para evitar el bug de closure en Lua 5.0
        local memberName      = data.name
        local memberClassFile = data.classFile

        btn:SetScript("OnClick", function()
            MF.selectedIconType   = "MEMBER_" .. memberClassFile
            MF.selectedMemberName = memberName
            RM.ICON_TEXTURE["MEMBER_" .. memberClassFile] =
                RM.Roster.GetTexturePath(memberClassFile)
            RM.ICON_SIZE["MEMBER_" .. memberClassFile] = 24
            MF.HighlightSelected(btn)
        end)

        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
            GameTooltip:SetText("Colocar: " .. memberName)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(memberButtons, btn)
        totalH = totalH + MEMBER_BTN_H + 2
    end

    memberContent:SetHeight(math.max(1, totalH))
end

-- -- Highlight del boton seleccionado ----------------------------
MF.lastSelectedBtn = nil

function MF.HighlightSelected(btn)
    -- Quitar highlight del anterior
    if MF.lastSelectedBtn and MF.lastSelectedBtn ~= btn then
        MF.lastSelectedBtn:SetAlpha(1.0)
    end
    btn:SetAlpha(0.6)
    MF.lastSelectedBtn = btn
end

-- ================================================================
--  TOOLBAR GRAFICA
--  Layout izq→der: [v Encounter] [Limpiar]  |  derecha: [Assist] [Cerrar]
-- ================================================================

local function makeToolbarBtn(label, width, parent)
    local btn = CreateFrame("Button", nil, parent or toolbar)
    btn:SetWidth(width)
    btn:SetHeight(24)
    btn:SetFrameLevel(toolbar:GetFrameLevel() + 1)
    btn:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left=2, right=2, top=2, bottom=2 },
    })
    btn:SetBackdropColor(0.15, 0.12, 0.06, 0.95)
    btn:SetBackdropBorderColor(0.5, 0.42, 0.22, 0.9)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(btn)
    hl:SetTexture(1, 1, 1, 0.10)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    BigFont(fs, 10)
    fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
    fs:SetText(label)
    btn.labelText = fs
    btn:EnableMouse(true)
    return btn
end

-- -- Dropdown frame con Scroll y Categorías ----------------------
local dropdownFrame = CreateFrame("Frame", "RaidMarkDropdown", UIParent)
dropdownFrame:SetWidth(180) -- Un poco más ancho para acomodar la barra de scroll
dropdownFrame:SetHeight(300) -- Altura fija máxima para el menú
dropdownFrame:SetFrameStrata("TOOLTIP")
dropdownFrame:SetFrameLevel(100)
dropdownFrame:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets   = { left=3, right=3, top=3, bottom=3 },
})
dropdownFrame:SetBackdropColor(0.08, 0.07, 0.04, 0.97)
dropdownFrame:SetBackdropBorderColor(0.5, 0.42, 0.22, 1)
dropdownFrame:Hide()

-- Contenedor con Scroll
local dropScrollFrame = CreateFrame("ScrollFrame", "RM_DropScroll", dropdownFrame, "UIPanelScrollFrameTemplate")
dropScrollFrame:SetPoint("TOPLEFT", 8, -8)
dropScrollFrame:SetPoint("BOTTOMRIGHT", -26, 8) -- Espacio para la barra de scroll

local dropScrollChild = CreateFrame("Frame", nil, dropScrollFrame)
dropScrollChild:SetWidth(140)
dropScrollChild:SetHeight(1)
dropScrollFrame:SetScrollChild(dropScrollChild)

local dropItems = {}

local function closeDropdown()
    dropdownFrame:Hide()
end

local function openDropdown(anchorBtn)
    if dropdownFrame:IsVisible() then closeDropdown() return end
    
    -- Limpiar botones anteriores
    for _, item in ipairs(dropItems) do item:Hide() end
    dropItems = {}

    if not RaidMark_Maps then
        DEFAULT_CHAT_FRAME:AddMessage("RaidMark: maps.lua no cargado.")
        return
    end

    local yOffset = 0
    local ITEM_H = 20
    local raidsOrder = {"AQ40", "Naxxramas", "BWL", "MC"}

    for _, raidName in ipairs(raidsOrder) do
        -- Cabecera de Categoría
        local header = CreateFrame("Frame", nil, dropScrollChild)
        header:SetWidth(140)
        header:SetHeight(ITEM_H)
        header:SetPoint("TOPLEFT", dropScrollChild, "TOPLEFT", 0, yOffset)
        
        local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        BigFont(headerText, 10)
        headerText:SetPoint("LEFT", header, "LEFT", 2, 0)
        headerText:SetText("--- " .. raidName .. " ---")
        headerText:SetTextColor(1, 0.82, 0)
        
        table.insert(dropItems, header)
        yOffset = yOffset - ITEM_H

        -- Botones de jefes de esa categoría
        for key, def in pairs(RaidMark_Maps) do
            if def.raid == raidName then
                local item = CreateFrame("Button", nil, dropScrollChild)
                item:SetWidth(140)
                item:SetHeight(ITEM_H)
                item:SetPoint("TOPLEFT", dropScrollChild, "TOPLEFT", 5, yOffset)
                item:EnableMouse(true)

                local hl = item:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints(item)
                hl:SetTexture(0.4, 0.35, 0.15, 0.5)

                local fs = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                BigFont(fs, 10)
                fs:SetPoint("LEFT", item, "LEFT", 5, 0)
                fs:SetText(def.label)
                fs:SetTextColor(0.9, 0.85, 0.6, 1)

                -- Captura local para el evento de clic
                local eKey   = key
                local eLabel = def.label
                item:SetScript("OnClick", function()
                    if RM.Permissions.CanPlace() then
                        RM.SetMap(eKey)
                        RM.Network.SendMapChange(eKey)
                        MF.encounterBtn.labelText:SetText("v  " .. eLabel)
                    end
                    closeDropdown()
                end)
                
                table.insert(dropItems, item)
                yOffset = yOffset - ITEM_H
            end
        end
        yOffset = yOffset - 5 -- Pequeño espacio extra después de cada grupo
    end

    dropScrollChild:SetHeight(math.abs(yOffset))

    dropdownFrame:ClearAllPoints()
    dropdownFrame:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
    dropdownFrame:Show()
end

-- Overlay invisible para cerrar dropdown al clickear fuera
local ddOverlay = CreateFrame("Frame", nil, UIParent)
ddOverlay:SetAllPoints(UIParent)
ddOverlay:SetFrameStrata("DIALOG")
ddOverlay:EnableMouse(true)
ddOverlay:Hide()
ddOverlay:SetScript("OnMouseDown", function() closeDropdown() end)
dropdownFrame:SetScript("OnShow", function() ddOverlay:Show() end)
dropdownFrame:SetScript("OnHide", function() ddOverlay:Hide() end)

-- -- Construir toolbar --------------------------------------------
local function buildToolbar()
    local xOff = 8
    -- [v Encounter]
    local encBtn = makeToolbarBtn("v  Encounter", 160)
    encBtn:SetPoint("LEFT", toolbar, "LEFT", xOff, 0)
    encBtn.labelText:SetTextColor(0.9, 0.85, 0.5, 1)
    encBtn:SetScript("OnClick", function() openDropdown(encBtn) end)
    encBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(encBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Seleccionar mapa del encuentro")
        GameTooltip:Show()
    end)
    encBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    MF.encounterBtn = encBtn
    xOff = xOff + 168

    -- Separador
    local sep1 = toolbar:CreateTexture(nil, "ARTWORK")
    sep1:SetWidth(1); sep1:SetHeight(26)
    sep1:SetPoint("LEFT", toolbar, "LEFT", xOff, 0)
    sep1:SetTexture(0.4, 0.35, 0.2, 0.6)
    xOff = xOff + 10

    -- [Limpiar]
    local clearBtn = makeToolbarBtn("Limpiar", 100)
    clearBtn.labelText:SetTextColor(1, 0.4, 0.2, 1)
    clearBtn:SetPoint("LEFT", toolbar, "LEFT", xOff, 0)
    clearBtn:SetScript("OnClick", function()
        if RM.Permissions.CanPlace() then
            RM.ClearAll()
            RM.Network.SendClear()
        else
            DEFAULT_CHAT_FRAME:AddMessage("RaidMark: Sin permisos.")
        end
    end)
    clearBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(clearBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Eliminar todos los iconos del mapa")
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    xOff = xOff + 108

    -- [Sync] -- visible para todos, pide estado al RL
    local syncBtn = makeToolbarBtn("Sync", 80)
    syncBtn.labelText:SetTextColor(0.4, 0.8, 1, 1)
    syncBtn:SetPoint("LEFT", toolbar, "LEFT", xOff, 0)
    syncBtn:SetScript("OnClick", function()
        RM.Network.SendSyncRequest()
        -- Si soy RL: limpiar slots de asistentes + refresh roster
        if RM.Permissions.IsRL() then
            for i = 2, 4 do
                RM.state.pointerSlots[i].owner = nil
            end
            RM.Network.SendPointerClear()
            RM.Roster.Rebuild()
            MF.UpdatePointerSlotUI()
            MF.ConsoleMsg("Slots PTR limpiados. Roster actualizado.", 0.4, 1, 0.5)
        end
    end)
    syncBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(syncBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Pedir al RL el estado actual del mapa")
        GameTooltip:Show()
    end)
    syncBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)


    syncBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    xOff = xOff + 88

    -- =========================================================
    -- ZONA DE PUNTERO: check + 4 indicadores de slot + consola
    -- =========================================================

    -- [Check Modo Puntero]
    local ptrCheck = CreateFrame("Button", nil, toolbar)
    ptrCheck:SetWidth(22)
    ptrCheck:SetHeight(22)
    ptrCheck:SetPoint("LEFT", toolbar, "LEFT", xOff, 0)
    ptrCheck:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left=2, right=2, top=2, bottom=2 },
    })
    ptrCheck:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    ptrCheck:SetBackdropBorderColor(0.5, 0.42, 0.22, 0.9)
    local ptrCheckMark = ptrCheck:CreateTexture(nil, "OVERLAY")
    ptrCheckMark:SetWidth(14); ptrCheckMark:SetHeight(14)
    ptrCheckMark:SetPoint("CENTER", ptrCheck, "CENTER", 0, 0)
    ptrCheckMark:SetTexture(RM.ICON_PATH .. "icon_circle_S")
    ptrCheckMark:SetVertexColor(1, 0.1, 0.1, 0.9)
    ptrCheckMark:Hide()

    -- Label "Modo Puntero" debajo
    local ptrLabel = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ptrLabel:SetPoint("TOP", ptrCheck, "BOTTOM", 0, -1)
    ptrLabel:SetText("Puntero / Alt")
    BigFont(ptrLabel, 8)
    ptrLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    ptrCheck:SetScript("OnClick", function()
        if not RM.Permissions.CanPlace() then
            MF.ConsoleMsg("Sin permisos: no eres RL ni Asistente autorizado.", 1, 0.3, 0.2)
            return
        end

        if RM.state.pointerActive then
            -- Desactivar: limpiar slot localmente primero
            local prevSlot = RM.state.myPointerSlot
            if prevSlot then
                RM.state.pointerSlots[prevSlot].owner = nil  -- <-- FIX: liberar slot local
            end
            RM.state.pointerActive = false
            RM.state.myPointerSlot = nil
            ptrCheckMark:Hide()
            ptrCheck:SetBackdropBorderColor(0.5, 0.42, 0.22, 0.9)
            if localPointerFrame then localPointerFrame:Hide() end
            RM.Network.SendPointerRelease()
            MF.ConsoleMsg("Modo puntero desactivado.")
            MF.UpdatePointerSlotUI()
        else
            -- Activar: RL siempre fuerza slot 1, asistentes buscan del 2 al 4
            local foundSlot = nil
            local myName = UnitName("player")

            if RM.Permissions.IsRL() then
                -- RL siempre toma el slot 1 (rojo), sin importar el estado
                foundSlot = 1
                RM.state.pointerSlots[1].owner = nil  -- limpiar por si quedo sucio
            else
                -- Asistentes buscan slots 2, 3, 4 libres
                for i = 2, 4 do
                    if not RM.state.pointerSlots[i].owner then
                        foundSlot = i
                        break
                    end
                end
            end

            if not foundSlot then
                MF.ConsoleMsg("Todos los slots de puntero estan ocupados.", 1, 0.6, 0.1)
                return
            end

            RM.state.pointerActive = true
            RM.state.myPointerSlot = foundSlot
            local slot = RM.state.pointerSlots[foundSlot]
            slot.owner = myName
            ptrCheckMark:Show()
            ptrCheck:SetBackdropBorderColor(slot.r, slot.g, slot.b, 1)

            if localPointerFrame then
                localPointerFrame.tex:SetVertexColor(slot.r, slot.g, slot.b, 1.0)
            end

            RM.Network.SendPointerClaim(slot.color)
            MF.ConsoleMsg("Modo puntero activado (" .. slot.color .. ").")
            MF.UpdatePointerSlotUI()
        end
    end)
    ptrCheck:SetScript("OnEnter", function()
        GameTooltip:SetOwner(ptrCheck, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Activar/desactivar modo puntero")
        GameTooltip:Show()
    end)
    ptrCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ptrCheck:EnableMouse(true)
    xOff = xOff + 28

    -- Funcion publica para forzar desactivacion desde exterior (RAID_ROSTER_UPDATE, PTR_CLEAR, timeout)
    MF.SetPointerActive = function(active)
        if active then return end  -- solo se llama con false (forzar desactivacion)
        local prevSlot = RM.state.myPointerSlot
        if prevSlot then
            RM.state.pointerSlots[prevSlot].owner = nil
        end
        RM.state.pointerActive = false
        RM.state.myPointerSlot = nil
        ptrCheckMark:Hide()
        ptrCheck:SetBackdropBorderColor(0.5, 0.42, 0.22, 0.9)
        if localPointerFrame then localPointerFrame:Hide() end
        MF.ConsoleMsg("Puntero liberado.", 1, 0.7, 0.3)
        MF.UpdatePointerSlotUI()
    end

    -- 4 indicadores de slot de color
    MF.slotIndicators = {}
    local SLOT_SZ = 16
    for i, slot in ipairs(RM.state.pointerSlots) do
        local ind = CreateFrame("Frame", nil, toolbar)
        ind:SetWidth(SLOT_SZ); ind:SetHeight(SLOT_SZ)
        ind:SetPoint("LEFT", toolbar, "LEFT", xOff + (i-1)*(SLOT_SZ+3), 0)
        local ibg = ind:CreateTexture(nil, "BACKGROUND")
        ibg:SetAllPoints(ind)
        ibg:SetTexture(slot.r * 0.3, slot.g * 0.3, slot.b * 0.3, 0.95)
        local icircle = ind:CreateTexture(nil, "ARTWORK")
        icircle:SetWidth(10); icircle:SetHeight(10)
        icircle:SetPoint("CENTER", ind, "CENTER", 0, 0)
        icircle:SetTexture(RM.ICON_PATH .. "icon_circle_S")
        icircle:SetVertexColor(slot.r, slot.g, slot.b, 0.9)
        ind:SetAlpha(0.25)  -- vacio por defecto
        table.insert(MF.slotIndicators, ind)
    end
    xOff = xOff + 4*(SLOT_SZ+3) + 8

    -- Mini consola informativa (cuadro azul)
    local consoleW = 160
    local consoleFrame = CreateFrame("Frame", nil, toolbar)
    consoleFrame:SetWidth(consoleW)
    consoleFrame:SetHeight(TOOLBAR_H - 10)
    consoleFrame:SetPoint("LEFT", toolbar, "LEFT", xOff, 0)
    -- SetClipsChildren no disponible en vanilla 1.12
    consoleFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left=3, right=3, top=3, bottom=3 },
    })
    consoleFrame:SetBackdropColor(0.04, 0.07, 0.15, 0.97)
    consoleFrame:SetBackdropBorderColor(0.2, 0.4, 0.9, 0.9)
    MF.consoleFrame = consoleFrame   -- exponer para el OnUpdate

    MF.consoleText = consoleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    MF.consoleText:SetPoint("TOPLEFT",     consoleFrame, "TOPLEFT",     5,  -5)
    MF.consoleText:SetPoint("BOTTOMRIGHT", consoleFrame, "BOTTOMRIGHT", -5,  5)
    MF.consoleText:SetJustifyH("LEFT")
    MF.consoleText:SetJustifyV("MIDDLE")
    BigFont(MF.consoleText, 9)
    MF.consoleText:SetText("RaidMark v" .. RM.VERSION)
    MF.consoleText:SetTextColor(0.4, 0.7, 1, 1)
    consoleCurrentMsg = { text = "RaidMark v" .. RM.VERSION, r = 0.4, g = 0.7, b = 1.0 }

    -- [Grid] -- cuadricula local con sliders de opacidad y densidad



    -- [Grid] -- cuadricula local con sliders de opacidad y densidad
    local gridActive = false
    local gridAlpha  = 0.3
    local gridCols   = 12
    local gridRows   = 8
    local gridLines  = {}

    local function buildGrid()
        for _, l in ipairs(gridLines) do l:Hide() end
        gridLines = {}
        if not gridActive then return end
        for i = 1, gridCols-1 do
            local l = contentFrame:CreateTexture(nil, "OVERLAY")
            l:SetWidth(1); l:SetHeight(MAP_H)
            l:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", MAP_W/gridCols*i, 0)
            l:SetTexture(1,1,1,gridAlpha)
            l:Show()
            table.insert(gridLines, l)
        end
        for i = 1, gridRows-1 do
            local l = contentFrame:CreateTexture(nil, "OVERLAY")
            l:SetWidth(MAP_W); l:SetHeight(1)
            l:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -MAP_H/gridRows*i)
            l:SetTexture(1,1,1,gridAlpha)
            l:Show()
            table.insert(gridLines, l)
        end
    end

    local gridBtn = makeToolbarBtn("Grid", 72)
    gridBtn.labelText:SetTextColor(0.6, 0.8, 1, 1)
    gridBtn:SetPoint("RIGHT", toolbar, "RIGHT", -8, 0)
    MF.gridBtn = gridBtn

    -- Panel de sliders (oculto hasta activar Grid)
    local gridPanel = CreateFrame("Frame", nil, toolbar)
    gridPanel:SetWidth(196); gridPanel:SetHeight(TOOLBAR_H)
    gridPanel:SetPoint("RIGHT", gridBtn, "LEFT", -6, 0)
    gridPanel:Hide()

    -- Label opacidad
    local lblAlpha = gridPanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lblAlpha:SetPoint("TOPLEFT", gridPanel, "TOPLEFT", 2, -4)
    lblAlpha:SetText("Opac:")
    lblAlpha:SetTextColor(0.8,0.8,0.6,1)

    -- Slider opacidad
    local slAlpha = CreateFrame("Slider","RaidMarkGridAlpha",gridPanel,"OptionsSliderTemplate")
    slAlpha:SetWidth(80); slAlpha:SetHeight(14)
    slAlpha:SetPoint("TOPLEFT", gridPanel, "TOPLEFT", 40, -8)
    slAlpha:SetMinMaxValues(0.05, 0.9)
    slAlpha:SetValue(0.3)
    slAlpha:SetValueStep(0.05)
    getglobal(slAlpha:GetName().."Low"):SetText("")
    getglobal(slAlpha:GetName().."High"):SetText("")
    getglobal(slAlpha:GetName().."Text"):SetText("")
    slAlpha:SetScript("OnValueChanged", function()
        gridAlpha = slAlpha:GetValue()
        for _, l in ipairs(gridLines) do l:SetTexture(1,1,1,gridAlpha) end
    end)

    -- Label densidad
    local lblDens = gridPanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lblDens:SetPoint("TOPLEFT", gridPanel, "TOPLEFT", 2, -24)
    lblDens:SetText("Grid:")
    lblDens:SetTextColor(0.8,0.8,0.6,1)

    -- Slider densidad (4..32 columnas/filas)
    local slDens = CreateFrame("Slider","RaidMarkGridDens",gridPanel,"OptionsSliderTemplate")
    slDens:SetWidth(80); slDens:SetHeight(14)
    slDens:SetPoint("TOPLEFT", gridPanel, "TOPLEFT", 40, -28)
    slDens:SetMinMaxValues(4, 32)
    slDens:SetValue(12)
    slDens:SetValueStep(2)
    getglobal(slDens:GetName().."Low"):SetText("")
    getglobal(slDens:GetName().."High"):SetText("")
    getglobal(slDens:GetName().."Text"):SetText("")
    slDens:SetScript("OnValueChanged", function()
        local v = math.floor(slDens:GetValue()/2+0.5)*2
        gridCols = v
        gridRows = math.floor(v * MAP_H / MAP_W + 0.5)
        if gridRows < 1 then gridRows = 1 end
        buildGrid()
    end)

    gridBtn:SetScript("OnClick", function()
        gridActive = not gridActive
        if gridActive then
            gridBtn.labelText:SetTextColor(1, 1, 0.3, 1)
            gridBtn:SetBackdropBorderColor(0.8, 0.8, 0.2, 1)
            gridPanel:Show()
        else
            gridBtn.labelText:SetTextColor(0.6, 0.8, 1, 1)
            gridBtn:SetBackdropBorderColor(0.5, 0.42, 0.22, 0.9)
            gridPanel:Hide()
        end
        buildGrid()
    end)
    gridBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(gridBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Mostrar/ocultar cuadricula (solo local)")
        GameTooltip:Show()
    end)
    gridBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- [Assist ON/OFF] -- visible para TODOS, accion solo para RL
    MF.assistBtn = makeToolbarBtn("Assist: OFF", 120)
    MF.assistBtn:SetPoint("RIGHT", gridPanel, "LEFT", -8, 0)
    MF.assistBtn:SetScript("OnClick", function()
        if RM.Permissions.IsRL() then
            RM.state.assistCanMove = not RM.state.assistCanMove
            RM.Network.SendPermissions(RM.state.assistCanMove)
            MF.UpdateAssistBtn()
        else
            UIErrorsFrame:AddMessage("No tienes permisos. No eres RL ni Asistente.", 1, 0.3, 0.3, 1, 3)
        end
    end)
    MF.assistBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(MF.assistBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Permitir a los Asistentes mover iconos")
        GameTooltip:Show()
    end)
    MF.assistBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    MF.UpdateAssistBtn()
end

function MF.UpdateAssistBtn()
    if not MF.assistBtn then return end
    -- El boton es visible para todos, pero con colores distintos segun estado
    MF.assistBtn:Show()
    if RM.state.assistCanMove then
        MF.assistBtn.labelText:SetText("Assist: ON")
        MF.assistBtn.labelText:SetTextColor(0.2, 1, 0.2, 1)
        MF.assistBtn:SetBackdropBorderColor(0.2, 0.6, 0.2, 1)
    else
        MF.assistBtn.labelText:SetText("Assist: OFF")
        MF.assistBtn.labelText:SetTextColor(0.6, 0.6, 0.6, 1)
        MF.assistBtn:SetBackdropBorderColor(0.5, 0.42, 0.22, 0.9)
    end
end


-- Crear el botón de Escala en la Toolbar
MF.scaleBtn = CreateFrame("Button", nil, mainFrame)
MF.scaleBtn:SetWidth(80)
MF.scaleBtn:SetHeight(24)
-- Ajusta el SetPoint según dónde estén tus otros botones (ej. al lado del botón de Assist)
MF.scaleBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -120, -12) 
MF.scaleBtn:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
MF.scaleBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

MF.scaleBtn.labelText = MF.scaleBtn:CreateFontString(nil, "OVERLAY")
BigFont(MF.scaleBtn.labelText, 12)
MF.scaleBtn.labelText:SetPoint("CENTER", 0, 0)
MF.scaleBtn.labelText:SetText("Scale: 100%")
MF.scaleBtn.labelText:SetTextColor(1, 0.8, 0, 1)

MF.scaleBtn:SetScript("OnClick", function()
    -- Lógica cíclica: 1.0 -> 0.9 -> 0.8 -> 1.0
    if RM.state.currentScale == 1.0 then
        RM.state.currentScale = 0.9
        MF.scaleBtn.labelText:SetText("Scale: 90%")
    elseif RM.state.currentScale == 0.9 then
        RM.state.currentScale = 0.8
        MF.scaleBtn.labelText:SetText("Scale: 80%")
    else
        RM.state.currentScale = 1.0
        MF.scaleBtn.labelText:SetText("Scale: 100%")
    end
    
    -- Aplicar la escala a todo el marco principal
    mainFrame:SetScale(RM.state.currentScale)
end)



-- -- Cargar textura del mapa --------------------------------------
function MF.LoadMap(mapKey)
    local mapDef = RaidMark_Maps[mapKey]
    if not mapDef then return end

    mapTexture:SetTexture(nil)
    mapTexture:SetTexture(mapDef.file)
    mapTexture:SetTexCoord(0, mapDef.u2, 0, mapDef.v2)
    mapTexture:SetAllPoints(contentFrame)
    titleText:SetText("RaidMark -- " .. mapDef.label)
    titleText:SetTextColor(0.4, 0.8, 1, 1)
    RM.Icons.RedrawAll()
end

-- -- Mostrar / Ocultar / Toggle -----------------------------------
function MF.Show()
    mainFrame:Show()
    RM.state.mapVisible = true
    if RM.state.currentMap then
        MF.LoadMap(RM.state.currentMap)
    end
    MF.RebuildRosterButtons()
    MF.UpdateAssistBtn()
end

function MF.Hide()
    mainFrame:Hide()
    RM.state.mapVisible = false
end

function MF.Toggle()
    if mainFrame:IsVisible() then
        MF.Hide()
    else
        MF.Show()
    end
end

-- -- Construir UI -- llamado desde core.lua en ADDON_LOADED --------
function MF.Build()
    buildRoleButtons()
    buildToolbar()
    buildPointerLocalFrame()
    MF.ConsoleMsg("RaidMark v" .. RM.VERSION .. " listo.")
end
