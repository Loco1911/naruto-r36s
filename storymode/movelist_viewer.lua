-- storymode/movelist_viewer.lua
-- In-game Move List Viewer for IKEMEN GO

local function log(msg)
    local f = io.open("storymode/debug.log", "a")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. "[MOVELIST] " .. msg .. "\n")
        f:close()
    end
end

log("Move List Viewer Start")

local function main_execution()
    local lc   = motif.info.localcoord or {640, 480}
    local W, H = lc[1], lc[2]

    local C = {
      bg       = {5,  8,  14},
      panel    = {12, 18, 28},
      panelBD  = {30, 42, 58},
      header   = {20, 28, 44},
      accent   = {255, 128,  0},
      p1color  = {80, 160, 255},
      p2color  = {255, 80,  80},
      secTitle = {200, 180, 60},
      text     = {220, 228, 240},
      muted    = {120, 130, 145},
      special  = {180, 140, 255},
      normal   = {140, 210, 140},
      super    = {255, 200,  80},
    }

    log("Loading Font")
    local fntMain = fontNew("font/Open_Sans.def", -1)
    local ti = {}
    for i = 1, 8 do ti[i] = textImgNew() end

    local function fRect(x, y, w, h, c, a)
      if w > 0 and h > 0 then
        fillRect(x, y, x + w, y + h, c[1], c[2], c[3], a or 255, 0)
      end
    end

    local function drawText(idx, s, x, y, col, sx, sy, align)
      if not ti[idx] then return end
      local av = (align == "left") and 1 or (align == "right") and -1 or 0
      textImgSetFont(ti[idx], fntMain)
      textImgSetAlign(ti[idx], av)
      textImgSetText(ti[idx], tostring(s))
      textImgSetPos(ti[idx], x + main.f_alignOffset(av), y)
      textImgSetColor(ti[idx], col[1], col[2], col[3])
      textImgSetScale(ti[idx], sx or 1, sy or 1)
      textImgSetWindow(ti[idx], 0, 0, W, H)
      textImgDraw(ti[idx])
    end

    local function loadMovelist(charName)
      if not charName or charName == "" then return nil end
      local path = "moves/" .. charName .. "/movelist.json"
      if not main.f_fileExists(path) then
        local base = charName:match("^([^/]+)") or charName
        path = "moves/" .. base .. "/movelist.json"
        if not main.f_fileExists(path) then return nil end
      end
      local ok, data = pcall(function()
        return json.decode(main.f_fileRead(path))
      end)
      if ok and type(data) == "table" then return data end
      return nil
    end

    local function getCharsWithMovelist()
      local chars = {}
      local catalogStr = main.f_fileRead("storymode/catalog.json")
      local ok, catalog = pcall(function() return json.decode(catalogStr) end)
      if ok and type(catalog) == "table" then
        local seen = {}
        for _, arc in ipairs(catalog) do
          for _, cap in ipairs(arc.chapters or {}) do
            for _, c in ipairs(cap.p1 or {}) do
              local base = c:match("^([^/]+)") or c
              if not seen[base] and main.f_fileExists("moves/"..base.."/movelist.json") then
                seen[base] = true
                table.insert(chars, base)
              end
            end
            for _, c in ipairs(cap.p2 or {}) do
              local base = c:match("^([^/]+)") or c
              if not seen[base] and main.f_fileExists("moves/"..base.."/movelist.json") then
                seen[base] = true
                table.insert(chars, base)
              end
            end
          end
        end
      end
      return chars
    end

    log("Scanning characters")
    local chars    = getCharsWithMovelist()
    local charIdx  = 1
    local ml1      = nil
    local ml2      = nil
    local scroll1  = 0
    local scroll2  = 0
    local focus    = 1

    if #chars > 0 then
      ml1 = loadMovelist(chars[1])
      ml2 = #chars > 1 and loadMovelist(chars[2]) or nil
    end

    local PANEL_W = math.floor(W * 0.46)
    local P1X     = math.floor(W * 0.02)
    local P2X     = math.floor(W * 0.52)
    local PYC      = math.floor(H * 0.12)
    local PHC      = math.floor(H * 0.78)

    local function drawMovePanel(ml, px, py, pw, ph, hdr_color, scroll, charLabel)
      fRect(px, py, pw, ph, C.panel)
      fRect(px-1, py-1, pw+2, 1, C.panelBD, 120)
      fRect(px-1, py+ph, pw+2, 1, C.panelBD, 120)
      fRect(px-1, py, 1, ph, C.panelBD, 120)
      fRect(px+pw, py, 1, ph, C.panelBD, 120)

      fRect(px, py, pw, 26, C.header)
      fRect(px, py+26, pw, 2, hdr_color, 180)

      local lbl = charLabel or (ml and (ml.character or "?") or "--")
      drawText(1, lbl, px + pw/2, py + 6, hdr_color, 0.88, 0.88, "center")

      if not ml then
        drawText(2, "Sin movelist.json", px + pw/2, py + ph/2 - 10, C.muted, 0.80, 0.80, "center")
        drawText(3, "Genera uno en el editor web", px + pw/2, py + ph/2 + 8, C.muted, 0.70, 0.70, "center")
        return
      end

      local itemH  = 22
      local lineH  = 14
      local contentY = py + 32
      local clipH  = ph - 36
      local curY   = contentY - (scroll * itemH)

      for _, sec in ipairs(ml.sections or {}) do
        if curY >= contentY - lineH and curY <= contentY + clipH then
          fRect(px + 4, curY, pw - 8, lineH + 2, {20, 28, 44}, 180)
          drawText(4, sec.name or "Seccion", px + 10, curY + 1, C.secTitle, 0.72, 0.72, "left")
        end
        curY = curY + lineH + 3

        for _, move in ipairs(sec.moves or {}) do
          if curY >= contentY - itemH and curY <= contentY + clipH then
            local mt = move.type or "normal"
            local ic  = mt == "special" and C.special or mt == "super" and C.super or C.normal
            local inputW = math.min(pw * 0.42, 90)
            fRect(px + pw - inputW - 6, curY - 1, inputW, itemH - 3, {8,12,20}, 200)
            drawText(5, move.input or "", px + pw - 8, curY + 2, ic, 0.70, 0.70, "right")
            drawText(6, move.name or "Movimiento", px + 8, curY + 2, C.text, 0.74, 0.74, "left")
          end
          curY = curY + itemH
        end
        curY = curY + 4
      end

      local totalItems = 0
      for _, s in ipairs(ml.sections or {}) do
        totalItems = totalItems + (s.name and 1 or 0) + #(s.moves or {})
      end
      if totalItems * itemH > clipH + 30 then
        drawText(7, "Arriba/Abajo: scroll", px + pw - 6, py + ph - 12, C.muted, 0.62, 0.62, "right")
      end
    end

    local function totalScrollLines(ml)
      if not ml then return 0 end
      local n = 0
      for _, s in ipairs(ml.sections or {}) do
        n = n + 1 + #(s.moves or {})
      end
      return n
    end

    log("Entering Movelist loop")
    while true do
      main.f_cmdInput()
      clearColor(C.bg[1], C.bg[2], C.bg[3])

      fillRect(0, 0, W, 3, 255, 128, 0, 255, 0)
      drawText(1, "MOVE LIST", W/2, 14, C.accent, 1.15, 1.15, "center")

      if #chars > 0 then
        local charName = chars[charIdx] or "--"
        drawText(2, "< " .. charName .. " >", W/2, 42, C.text, 0.82, 0.82, "center")
      else
        drawText(2, "No hay movelists generados.", W/2, 42, C.muted, 0.80, 0.80, "center")
      end

      drawText(3, "J1 - Lista", P1X, PYC - 14, C.p1color, 0.76, 0.76, "left")
      drawText(3, "J2 - Lista", P2X, PYC - 14, C.p2color, 0.76, 0.76, "left")

      drawMovePanel(ml1, P1X, PYC, PANEL_W, PHC, C.p1color, scroll1, chars[charIdx] or "J1")
      drawMovePanel(ml2, P2X, PYC, PANEL_W, PHC, C.p2color, scroll2, nil)

      local fx = focus == 1 and P1X or P2X
      fillRect(fx, PYC, fx + PANEL_W, PYC + 2, 255, 128, 0, 180, 0)

      drawText(8, "Izq/Der: Personaje - Y: alternar panel - Arriba/Abajo: Scroll - B: Volver",
               W/2, H - 16, C.muted, 0.72, 0.72, "center")

      -- Input
      if main.f_input(main.t_players, {"$F","r"}) then
        if #chars > 0 then
          charIdx = charIdx % #chars + 1
          ml1 = loadMovelist(chars[charIdx])
          scroll1 = 0
        end
        main.f_cmdBufReset()
      elseif main.f_input(main.t_players, {"$B","l"}) then
        if #chars > 0 then
          charIdx = charIdx - 1
          if charIdx < 1 then charIdx = #chars end
          ml1 = loadMovelist(chars[charIdx])
          scroll1 = 0
        end
        main.f_cmdBufReset()
      elseif main.f_input(main.t_players, {"y","c","s"}) then
        focus = focus == 1 and 2 or 1
        main.f_cmdBufReset()
      elseif main.f_input(main.t_players, {"$U","u"}) then
        if focus == 1 then scroll1 = math.max(0, scroll1 - 1)
        else               scroll2 = math.max(0, scroll2 - 1) end
        main.f_cmdBufReset()
      elseif main.f_input(main.t_players, {"$D","d"}) then
        local maxS = focus == 1 and math.max(0, totalScrollLines(ml1) - 12) or
                                    math.max(0, totalScrollLines(ml2) - 12)
        if focus == 1 then scroll1 = math.min(maxS, scroll1 + 1)
        else               scroll2 = math.min(maxS, scroll2 + 1) end
        main.f_cmdBufReset()
      elseif esc() or main.f_input(main.t_players, {"b","x"}) then
        log("Exiting Movelist")
        esc(false); setMatchNo(-1); break
      end

      refresh()
    end
end

local ok, err = pcall(main_execution)
if not ok then
    log("MOVELIST ERROR: " .. tostring(err))
    setMatchNo(-1)
end
