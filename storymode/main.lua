-- storymode/main.lua
-- Visual Node Map Story Mode for IKEMEN GO
-- Uses pergamino-style background with horizontal node chain

local function log(msg)
    local f = io.open("storymode/debug.log", "a")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. "[MAIN] " .. msg .. "\n")
        f:close()
    end
end

log("--- Story Mode Session Start ---")

local function main_execution()
    log("Loading common.lua")
    local story   = dofile("storymode/common.lua")
    
    log("Loading catalog.lua")
    local catalog = dofile("storymode/catalog.lua")

    if not catalog or type(catalog) ~= "table" or #catalog == 0 then
        log("No catalog found, exiting")
        setMatchNo(-1)
        return
    end

    -- Screen dimensions
    log("Getting motif info")
    local lc  = motif.info.localcoord or {640, 480}
    local W, H = lc[1], lc[2]
    log("Dimensions: " .. W .. "x" .. H)

    -- ─── COLOR PALETTE ───────────────────────────────────────────────────
    local C = {
      bg        = {5,  8,  14},
      pBG       = {210, 184, 150},
      pHeader   = {180, 210, 224},
      pBorder   = {72,  52,  28},
      pShadow   = {52,  36,  16},
      pInner    = {222, 198, 166},
      nNormal   = {196, 163, 84},  nNormalBD  = {142, 108, 44},
      nSide     = {88,  148, 210}, nSideBD    = {48,   90, 160},
      nMidBoss  = {200, 72,  72},  nMidBossBD = {140,  38,  38},
      nBoss     = {165, 76,  210}, nBossBD    = {108,  38, 155},
      nLocked   = {70,  74,  80},  nLockedBD  = {48,   50,  55},
      nCleared  = {72,  192, 96},  nClearedBD = {44,  130,  60},
      selGlow   = {255, 222, 48},
      tTitle    = {255, 128,  0},
      tLight    = {238, 228, 210},
      tDark     = {44,   28,   8},
      tMuted    = {148, 158, 172},
      tLocked   = {88,   88,  90},
      tCleared  = {88,  210, 108},
      conn      = {148, 110, 56},
      accent    = {255, 128,  0},
    }

    -- ─── LAYOUT ──────────────────────────────────────────────────────────
    local PX  = math.floor(W * 0.038)
    local PY  = math.floor(H * 0.16)
    local PW  = math.floor(W * 0.924)
    local PH  = math.floor(H * 0.50)
    local PHD = 26

    local NR       = 20
    local NBOSS_R  = 26
    local NSPACING = 84
    local NY_MAIN  = PY + PHD + math.floor((PH - PHD) * 0.52)
    local NY_UP    = NY_MAIN - 60
    local NY_DOWN  = NY_MAIN + 60
    local MAX_VIS  = 7

    -- ─── FONTS / TEXT ────────────────────────────────────────────────────
    log("Loading Font: font/Open_Sans.def")
    local fntMain = fontNew("font/Open_Sans.def", -1)
    if not fntMain then
        log("WARNING: Failed to load font/Open_Sans.def, attempting fallback")
        -- Try to find any loaded font from motif title info
        local f_idx = motif.title_info.menu_item_font[1]
        local f_height = motif.title_info.menu_item_font[7]
        fntMain = main.font[f_idx .. f_height]
        if not fntMain then
            fntMain = fontNew("font/f-6x9.def", -1) -- Ultimate fallback
        end
    end

    local ti = {}
    for i = 1, 6 do ti[i] = textImgNew() end

    -- ─── HELPERS ─────────────────────────────────────────────────────────
    local function fRect(x, y, w, h, c, a, d)
      if w > 0 and h > 0 then
        fillRect(x, y, x + w, y + h, c[1], c[2], c[3], a or 255, d or 0)
      end
    end

    local function drawText(idx, s, x, y, color, sx, sy, align)
      if not ti[idx] then return end
      local av = (align == "left") and 1 or (align == "right") and -1 or 0
      textImgSetFont(ti[idx], fntMain)
      textImgSetAlign(ti[idx], av)
      textImgSetText(ti[idx], tostring(s))
      textImgSetPos(ti[idx], x + main.f_alignOffset(av), y)
      textImgSetColor(ti[idx], color[1], color[2], color[3])
      textImgSetScale(ti[idx], sx or 1, sy or 1)
      textImgSetWindow(ti[idx], 0, 0, W, H)
      textImgDraw(ti[idx])
    end

    -- ─── PERGAMINO ───────────────────────────────────────────────────────
    local function drawPergamino()
      fRect(PX+4, PY+6, PW, PH, C.pShadow, 100)
      fRect(PX-3, PY-3, PW+6, PH+6, C.pBorder)
      fRect(PX, PY, PW, PH, C.pBG)
      fRect(PX, PY, PW, PHD, C.pHeader)
      fRect(PX, PY+PHD, PW, 2, C.pBorder, 80)
      fRect(PX+4, PY+PHD+2, PW-8, math.floor((PH-PHD)*0.4), C.pInner, 90)
      -- Corner rolls
      fRect(PX-9, PY-9,  24, 24, C.pBorder)
      fRect(PX-6, PY-6,  16, 16, {185,152,108})
      fRect(PX-2, PY-2,   7,  7, {220,195,155})
      fRect(PX+PW-15, PY-9,  24, 24, C.pBorder)
      fRect(PX+PW-10, PY-6,  16, 16, {185,152,108})
      fRect(PX-2, PY-2,   7,  7, {220,195,155}) -- Fixed: was missing from earlier
      fRect(PX-9, PY+PH-15, 24, 24, C.pBorder)
      fRect(PX-6, PY+PH-10, 16, 16, {185,152,108})
      fRect(PX+PW-15, PY+PH-15, 24, 24, C.pBorder)
      fRect(PX+PW-10, PY+PH-10, 16, 16, {185,152,108})
    end

    -- ─── NODE ────────────────────────────────────────────────────────────
    local function nodeR(cap)
      local t = cap.type or "normal"
      if t == "finalboss" then return NBOSS_R end
      if t == "midboss"   then return NBOSS_R - 4 end
      return NR
    end

    local function nodeColors(cap, unlocked, cleared)
      if not unlocked  then return C.nLocked,  C.nLockedBD  end
      if cleared       then return C.nCleared, C.nClearedBD end
      local t = cap.type or "normal"
      if t == "sidestory"  then return C.nSide,    C.nSideBD    end
      if t == "midboss"    then return C.nMidBoss, C.nMidBossBD end
      if t == "finalboss"  then return C.nBoss,    C.nBossBD    end
      return C.nNormal, C.nNormalBD
    end

    local function drawNode(cap, cx, cy, selected, unlocked, cleared)
      local fill, border = nodeColors(cap, unlocked, cleared)
      local r = nodeR(cap)

      if selected then
        fRect(cx-r-6, cy-r-6, (r+6)*2, (r+6)*2, C.selGlow, 220)
        fRect(cx-r-4, cy-r-4, (r+4)*2, (r+4)*2, {0, 0, 0}, 100)
      end
      fRect(cx-r-2, cy-r-2, (r+2)*2, (r+2)*2, border)
      fRect(cx-r,   cy-r,   r*2,     r*2,     fill)

      local t = cap.type or "normal"
      local label = t == "sidestory" and "S" or t == "midboss" and "M" or
                    t == "finalboss" and "B" or tostring(cap._visIdx or "?")
      local lcol = unlocked and C.tDark or C.tLocked
      drawText(3, label, cx, cy - 9, lcol, 0.82, 0.82, "center")

      local badges = {sidestory="SIDE", midboss="MID", finalboss="BOSS", normal=""}
      local badge = badges[t] or ""
      if badge ~= "" then
        local badgeCol = t == "sidestory" and C.nSide or
                         t == "midboss"   and C.nMidBoss or C.nBoss
        drawText(4, badge, cx, cy + r + 2, badgeCol, 0.52, 0.52, "center")
      end

      local capTitle = cap.title or ""
      if #capTitle > 13 then capTitle = string.sub(capTitle, 1, 11) .. ".." end
      if cy < NY_MAIN - 20 then
        drawText(5, capTitle, cx, cy - r - 13, C.tDark, 0.60, 0.60, "center")
      elseif cy > NY_MAIN + 20 then
        drawText(5, capTitle, cx, cy + r + (badge~="" and 10 or 4), C.tDark, 0.60, 0.60, "center")
      else
        drawText(5, capTitle, cx, cy + r + (badge~="" and 12 or 4), C.tDark, 0.60, 0.60, "center")
      end
    end

    -- ─── CONNECTOR ───────────────────────────────────────────────────────
    local function drawConn(x1, y1, r1, x2, y2, r2)
      if y1 == y2 then
        local cx = math.min(x1,x2) + r1 + 2
        local cw = math.abs(x2-x1) - r1 - r2 - 4
        if cw > 2 then fRect(cx, y1-2, cw, 4, C.conn) end
      else
        local cy1 = math.min(y1,y2) + r1 + 2
        local cy2 = math.max(y1,y2) - r2 - 2
        if cy2 > cy1 then fRect(x1-2, cy1, 4, cy2-cy1, C.conn) end
      end
    end

    -- ─── LAYOUT BUILDER ──────────────────────────────────────────────────
    local function buildLayout(arc)
      local mainList   = {}
      local sideBranches = {}
      local mainIdMap  = {}

      for i, cap in ipairs(arc.chapters or {}) do
        local t = cap.type or "normal"
        if t ~= "sidestory" then
          table.insert(mainList, i)
          cap._visIdx = #mainList
          mainIdMap[cap.id or ""] = #mainList
        end
      end

      for i, cap in ipairs(arc.chapters or {}) do
        local t = cap.type or "normal"
        if t == "sidestory" then
          local afterId = cap.sideUnlockAfter or ""
          local pos = mainIdMap[afterId] or (#mainList > 0 and #mainList or 1)
          if not sideBranches[pos] then sideBranches[pos] = {} end
          table.insert(sideBranches[pos], i)
        end
      end

      return mainList, sideBranches
    end

    -- ─── VIEWPORT ────────────────────────────────────────────────────────
    local function getViewport(total, focus)
      local half  = math.floor(MAX_VIS / 2)
      local first = math.max(1, focus - half)
      if first + MAX_VIS - 1 > total then
        first = math.max(1, total - MAX_VIS + 1)
      end
      return first, math.min(total, first + MAX_VIS - 1)
    end

    local function nodeX(totalVis, slot)
      local totalW = (totalVis - 1) * NSPACING
      local startX = math.floor(W / 2 - totalW / 2)
      return startX + slot * NSPACING
    end

    -- ─── ARC SELECT ──────────────────────────────────────────────────────
    local function drawArcSelect(progress)
      drawText(1, "CRONICAS NINJA",     W/2, 32, C.tTitle, 1.28, 1.28, "center")
      drawText(2, "Selecciona una Saga", W/2, 66, C.tLight, 0.90, 0.90, "center")

      local rowH  = 50
      local startY = 105
      local listW  = math.floor(W * 0.70)
      local listX  = math.floor(W / 2 - listW / 2)

      fRect(listX-10, startY-8, listW+20, #catalog*rowH+16, {12,18,28}, 180)
      fRect(listX-10, startY-8, 4, #catalog*rowH+16, C.tTitle)

      for i, arc in ipairs(catalog) do
        local y = startY + (i-1)*rowH
        local sel = (i == _stState.arcIdx)
        local unlocked = story.isArcUnlocked(catalog, i, progress)

        if sel then
          fRect(listX, y, listW, rowH-4, {28,18,8}, 150)
          fRect(listX, y, 4, rowH-4, C.tTitle)
        end

        local tc = not unlocked and C.tLocked or (sel and C.tTitle or C.tLight)
        local sc = sel and 1.0 or 0.86
        drawText(2, arc.title or "Saga", W/2, y+8, tc, sc, sc, "center")

        local nMain, nSide, nBoss = 0, 0, 0
        for _, cap in ipairs(arc.chapters or {}) do
          local t = cap.type or "normal"
          if t == "sidestory" then nSide = nSide+1
          elseif t == "midboss" or t == "finalboss" then nBoss = nBoss+1
          else nMain = nMain+1 end
        end
        local sub = nMain .. " caps"
        if nSide > 0 then sub = sub .. " + " .. nSide .. " side" end
        if nBoss > 0 then sub = sub .. " + " .. nBoss .. " jefes" end
        drawText(3, sub, W/2, y+30, sel and C.tMuted or C.tLocked, 0.72, 0.72, "center")
      end

      drawText(6, "Arriba/Abajo: Navegar - A: Entrar - B: Volver", W/2, H-20, C.tMuted, 0.78, 0.78, "center")
    end

    -- ─── CHAPTER MAP ─────────────────────────────────────────────────────
    local function drawChapterMap(progress)
      local arc = catalog[_stState.arcIdx]
      local mainList, sideBranches = buildLayout(arc)

      drawText(1, "CRONICAS NINJA", W/2, 18, C.tTitle, 1.10, 1.10, "center")
      drawText(2, arc.title or "",  W/2, 46, C.tLight, 0.92, 0.92, "center")

      drawPergamino()
      drawText(3, "-- MAPA DE CAPITULOS --", W/2, PY+8, C.tDark, 0.76, 0.76, "center")

      if #mainList == 0 then
        drawText(2, "Esta saga no tiene capitulos aun.", W/2, NY_MAIN-12, C.tDark, 0.86, 0.86, "center")
      else
        local vFirst, vLast = getViewport(#mainList, _stState.mainIdx)
        local totalVis = vLast - vFirst + 1
        local positions = {}

        for vi = vFirst, vLast do
          local capIdx = mainList[vi]
          local slot   = vi - vFirst
          local cx     = nodeX(totalVis, slot)
          positions[capIdx] = {cx, NY_MAIN}

          if vi > vFirst then
            local prevIdx = mainList[vi-1]
            local pp = positions[prevIdx]
            if pp then
              drawConn(pp[1], NY_MAIN, nodeR(arc.chapters[prevIdx]),
                       cx,    NY_MAIN, nodeR(arc.chapters[capIdx]))
            end
          end

          if sideBranches[vi] then
            for si, sCapIdx in ipairs(sideBranches[vi]) do
              local sY = (si % 2 == 1) and NY_UP or NY_DOWN
              positions[sCapIdx] = {cx, sY}
              drawConn(cx, NY_MAIN, nodeR(arc.chapters[capIdx]),
                       cx, sY,     nodeR(arc.chapters[sCapIdx]))
            end
          end
        end

        for vi = vFirst, vLast do
          local capIdx = mainList[vi]
          local cap    = arc.chapters[capIdx]
          local pos    = positions[capIdx]
          local isSel  = (not _stState.focusSide and vi == _stState.mainIdx)
          local unlocked = story.isChapterUnlocked(catalog, _stState.arcIdx, capIdx, progress)
          local cleared  = story.isChapterCleared(arc.id, cap.id, progress)
          drawNode(cap, pos[1], pos[2], isSel, unlocked, cleared)

          if sideBranches[vi] then
            for si, sCapIdx in ipairs(sideBranches[vi]) do
              local sCap = arc.chapters[sCapIdx]
              local sPos = positions[sCapIdx]
              local sSel = _stState.focusSide and _stState.sideCapIdx == sCapIdx
              local sU = story.isChapterUnlocked(catalog, _stState.arcIdx, sCapIdx, progress)
              local sC = story.isChapterCleared(arc.id, sCap.id, progress)
              drawNode(sCap, sPos[1], sPos[2], sSel, sU, sC)
            end
          end
        end

        if vFirst > 1 then
          drawText(6, "< mas", PX+22, NY_MAIN-8, C.tTitle, 0.85, 0.85, "center")
        end
        if vLast < #mainList then
          local arrowX = nodeX(totalVis, totalVis-1) + NSPACING/2
          drawText(6, "mas >", math.min(arrowX, PX+PW-26), NY_MAIN-8, C.tTitle, 0.85, 0.85, "center")
        end
      end

      -- Info panel
      local infoY = PY + PH + 16
      local arc2  = catalog[_stState.arcIdx]
      local ml2, _ = buildLayout(arc2)
      local focusedIdx = _stState.focusSide and _stState.sideCapIdx or (ml2[_stState.mainIdx] or 1)

      if focusedIdx and arc2.chapters[focusedIdx] then
        local cap       = arc2.chapters[focusedIdx]
        local unlocked  = story.isChapterUnlocked(catalog, _stState.arcIdx, focusedIdx, progress)
        local cleared   = story.isChapterCleared(arc2.id, cap.id, progress)
        local typeNames = {normal="Capitulo", sidestory="Historia Paralela", midboss="Mid-Boss", finalboss="Jefe Final"}
        local typeName  = typeNames[cap.type or "normal"] or "Capitulo"
        local statusTxt = cleared and "COMPLETADO" or (unlocked and "DISPONIBLE" or "BLOQUEADO")
        local statusCol = cleared and C.tCleared or (unlocked and C.tTitle or C.tLocked)

        drawText(2, cap.title or "", W/2, infoY, C.tLight, 0.98, 0.98, "center")
        local subLine = typeName
        if cap.subtitle and cap.subtitle ~= "" then
          subLine = subLine .. " - " .. cap.subtitle
        end
        drawText(3, subLine, W/2, infoY+22, C.tMuted, 0.76, 0.76, "center")
        drawText(4, statusTxt, W/2, infoY+40, statusCol, 0.82, 0.82, "center")
      end

      drawText(6, "Izq/Der: Navegar - Arriba/Abajo: Side Story - A: Iniciar - B: Volver", W/2, H-18, C.tMuted, 0.74, 0.74, "center")
    end

    -- ─── STATE ───────────────────────────────────────────────────────────
    _stState = {
      screen     = "arcs",
      arcIdx     = 1,
      mainIdx    = 1,
      focusSide  = false,
      sideCapIdx = nil,
    }

    local function firstAvailableMain(aIdx, ml, progress)
      local arc = catalog[aIdx]
      for mi, capIdx in ipairs(ml) do
          local cap = arc.chapters[capIdx]
        if cap and not story.isChapterCleared(arc.id, cap.id, progress) then
          return mi
        end
      end
      return math.max(1, #ml)
    end

    log("Initializing State")
    local initProg = story.loadProgress()
    for i = 1, #catalog do
      if story.isArcUnlocked(catalog, i, initProg) then
        _stState.arcIdx = i
      end
    end

    local function inp(cmds) return main.f_input(main.t_players, cmds) end
    local function rbuf() main.f_cmdBufReset() end

    -- ─── MAIN LOOP ───────────────────────────────────────────────────────
    log("Entering Main Loop")
    while true do
      main.f_cmdInput()
      local progress = story.loadProgress()

      clearColor(C.bg[1], C.bg[2], C.bg[3])
      fillRect(0, 0, W, 3, 255, 128, 0, 255, 0)
      fillRect(0, H-3, W, 3, 255, 128, 0, 255, 0)

      if _stState.screen == "arcs" then
        drawArcSelect(progress)
      else
        drawChapterMap(progress)
      end

      -- INPUT: ARC SELECT
      if _stState.screen == "arcs" then
        if inp({"$U","u"}) then
          _stState.arcIdx = _stState.arcIdx - 1
          if _stState.arcIdx < 1 then _stState.arcIdx = #catalog end
          rbuf()
        elseif inp({"$D","d"}) then
          _stState.arcIdx = _stState.arcIdx + 1
          if _stState.arcIdx > #catalog then _stState.arcIdx = 1 end
          rbuf()
        elseif inp({"pal","a"}) then
          if story.isArcUnlocked(catalog, _stState.arcIdx, progress) then
            log("Entering Saga: " .. _stState.arcIdx)
            local arc = catalog[_stState.arcIdx]
            local ml  = buildLayout(arc)
            _stState.mainIdx   = firstAvailableMain(_stState.arcIdx, ml, progress)
            _stState.focusSide = false
            _stState.sideCapIdx = nil
            _stState.screen = "map"
          end
          rbuf()
        elseif esc() or inp({"b","s"}) then
          log("Exiting Story Mode (Select Screen)")
          esc(false); setMatchNo(-1); break
        end

      -- INPUT: CHAPTER MAP
      else
        local arc = catalog[_stState.arcIdx]
        local ml, sb = buildLayout(arc)

        if inp({"$B","l"}) then
          if not _stState.focusSide then
            _stState.mainIdx = _stState.mainIdx - 1
            if _stState.mainIdx < 1 then _stState.mainIdx = #ml end
          end
          rbuf()
        elseif inp({"$F","r"}) then
          if not _stState.focusSide then
            _stState.mainIdx = _stState.mainIdx + 1
            if _stState.mainIdx > #ml then _stState.mainIdx = 1 end
          end
          rbuf()
        elseif inp({"$U","u"}) then
          if not _stState.focusSide then
            if sb[_stState.mainIdx] then
              for si, sCapIdx in ipairs(sb[_stState.mainIdx]) do
                if si % 2 == 1 then
                  _stState.focusSide  = true
                  _stState.sideCapIdx = sCapIdx
                  break
                end
              end
            end
          else
            _stState.focusSide = false; _stState.sideCapIdx = nil
          end
          rbuf()
        elseif inp({"$D","d"}) then
          if not _stState.focusSide then
            if sb[_stState.mainIdx] then
              for si, sCapIdx in ipairs(sb[_stState.mainIdx]) do
                if si % 2 == 0 then
                  _stState.focusSide  = true
                  _stState.sideCapIdx = sCapIdx
                  break
                end
              end
            end
          else
            _stState.focusSide = false; _stState.sideCapIdx = nil
          end
          rbuf()
        elseif inp({"pal","a"}) then
          local capIdx = _stState.focusSide and _stState.sideCapIdx or ml[_stState.mainIdx]
          if capIdx and arc.chapters[capIdx] then
            local cap = arc.chapters[capIdx]
            if story.isChapterUnlocked(catalog, _stState.arcIdx, capIdx, progress) then
              log("Starting Chapter: " .. cap.id)
              story.playChapter(arc.id, cap.id, cap)
              main.f_cmdBufReset()
            end
          end
          rbuf()
        elseif esc() or inp({"b","s"}) then
          log("Back to Arc Selection")
          esc(false); _stState.screen = "arcs"; rbuf()
        end
      end

      refresh()
    end
end

-- SAFETY WRAPPER
local ok, err = pcall(main_execution)
if not ok then
    log("CRITICAL LUA ERROR: " .. tostring(err))
    -- Attempt to return to menu instead of crashing hard
    main.f_bgReset(motif[main.background].bg)
    main.f_fadeReset('fadein', motif[main.group])
    setMatchNo(-1)
end
