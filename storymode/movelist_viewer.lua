-- storymode/movelist_viewer.lua
-- Standalone Move List viewer for the main menu

local function log(msg)
    local f = io.open("storymode/debug.log", "a")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. "[MOVELIST] " .. msg .. "\n")
        f:close()
    end
end

local function trimLabel(str, maxLen)
    str = tostring(str or "")
    if #str <= maxLen then
        return str
    end
    return string.sub(str, 1, math.max(1, maxLen - 2)) .. ".."
end

local function main_execution()
    log("Move List Viewer Start")

    local lc = motif.info.localcoord or {640, 480}
    local W, H = lc[1] or 640, lc[2] or 480

    local C = {
        bg         = {0, 0, 0},
        panel      = {10, 13, 19},
        panel_alt  = {14, 18, 26},
        border     = {36, 44, 58},
        accent     = {255, 132, 24},
        text       = {230, 235, 244},
        text_muted = {126, 138, 156},
        good       = {72, 194, 112},
        warn       = {118, 128, 146},
        normal     = {196, 214, 128},
        special    = {104, 176, 255},
        super      = {255, 198, 92},
        focus      = {255, 214, 90},
    }

    local fntMain = fontNew("font/Open_Sans.def", -1)
    if not fntMain then
        fntMain = fontNew("font/f-6x9.def", -1)
    end
    if not fntMain and motif.title_info and motif.title_info.menu_item_font then
        local key = motif.title_info.menu_item_font[1] .. motif.title_info.menu_item_font[7]
        fntMain = main.font[key]
    end

    local ti = {}
    for i = 1, 40 do
        ti[i] = textImgNew()
    end
    local textIdx = 1

    local function beginTextFrame()
        textIdx = 1
    end

    local function nextText()
        local obj = ti[textIdx]
        textIdx = textIdx + 1
        if textIdx > #ti then
            textIdx = 1
        end
        return obj
    end

    local function rect(x, y, w, h, col, alpha)
        if w > 0 and h > 0 then
            fillRect(x, y, w, h, col[1], col[2], col[3], alpha or 255, 0)
        end
    end

    local function frame(x, y, w, h, border, fill)
        rect(x, y, w, h, border)
        rect(x + 1, y + 1, math.max(0, w - 2), math.max(0, h - 2), fill)
    end

    local function panel(x, y, w, h, title)
        frame(x, y, w, h, C.border, C.panel)
        rect(x, y, w, 24, C.panel_alt)
        if title and title ~= "" then
            local obj = nextText()
            textImgSetFont(obj, fntMain)
            textImgSetAlign(obj, 1)
            textImgSetText(obj, tostring(title))
            textImgSetPos(obj, x + 10 + main.f_alignOffset(1), y + 6)
            textImgSetColor(obj, C.text[1], C.text[2], C.text[3])
            textImgSetScale(obj, 0.70, 0.70)
            textImgSetWindow(obj, 0, 0, W, H)
            textImgDraw(obj)
        end
    end

    local function drawText(str, x, y, col, sx, sy, align)
        if not fntMain then return end
        local obj = nextText()
        local a = 0
        if align == "left" then
            a = 1
        elseif align == "right" then
            a = -1
        end
        textImgSetFont(obj, fntMain)
        textImgSetAlign(obj, a)
        textImgSetText(obj, tostring(str or ""))
        textImgSetPos(obj, x + main.f_alignOffset(a), y)
        textImgSetColor(obj, col[1], col[2], col[3])
        textImgSetScale(obj, sx or 1, sy or 1)
        textImgSetWindow(obj, 0, 0, W, H)
        textImgDraw(obj)
    end

    local function movelistCandidates(entry)
        local candidates = {}
        local seen = {}

        local function add(path)
            if path and path ~= "" and not seen[path:lower()] then
                seen[path:lower()] = true
                table.insert(candidates, path)
            end
        end

        add("moves/" .. entry.folder .. "/movelist.json")
        add("moves/" .. entry.name .. "/movelist.json")
        return candidates
    end

    local function loadMovelist(entry)
        for _, path in ipairs(movelistCandidates(entry)) do
            if main.f_fileExists(path) then
                local ok, decoded = pcall(function()
                    return json.decode(main.f_fileRead(path))
                end)
                if ok and type(decoded) == "table" then
                    return decoded, path
                end
            end
        end
        return nil, nil
    end

    local function hasMovelistFile(entry)
        for _, path in ipairs(movelistCandidates(entry)) do
            if main.f_fileExists(path) then
                return true
            end
        end
        return false
    end

    local function buildEntryList()
        local list = {}
        local seen = {}
        for _, charData in ipairs(main.t_selChars or {}) do
            if type(charData) == "table"
                and charData.playable
                and charData.char
                and charData.char ~= "randomselect"
                and charData.name
                and charData.name ~= "null" then
                local def = tostring(charData.def or ""):gsub("\\", "/")
                local folder = def:match("^chars/([^/]+)/") or def:match("/([^/]+)/[^/]+%.def$")
                folder = folder or charData.name
                local key = tostring(folder):lower()
                if key ~= "" and not seen[key] then
                    seen[key] = true
                    local entry = {
                        name = charData.name,
                        folder = folder,
                    }
                    entry.hasMovelist = hasMovelistFile(entry)
                    entry.cached = false
                    entry.movelistData = nil
                    entry.movelistPath = nil
                    table.insert(list, entry)
                end
            end
        end
        return list
    end

    local entries = buildEntryList()
    local selected = 1
    local listTop = 1
    local moveScroll = 0
    local focus = "list"

    local function currentEntry()
        return entries[selected]
    end

    local function currentMovelist()
        local entry = currentEntry()
        if not entry then
            return nil, nil
        end
        if not entry.cached then
            entry.movelistData, entry.movelistPath = loadMovelist(entry)
            entry.cached = true
        end
        return entry.movelistData, entry.movelistPath
    end

    local function countMoveRows(data)
        if not data then return 0 end
        local total = 0
        for _, section in ipairs(data.sections or {}) do
            total = total + 1 + #(section.moves or {})
        end
        return total
    end

    local function syncListWindow(visibleRows)
        if selected < listTop then
            listTop = selected
        elseif selected > listTop + visibleRows - 1 then
            listTop = selected - visibleRows + 1
        end
        listTop = math.max(1, listTop)
    end

    while true do
        main.f_cmdInput()
        beginTextFrame()
        clearColor(C.bg[1], C.bg[2], C.bg[3])
        rect(0, 0, W, 3, C.accent)

        local listX = 24
        local listY = 72
        local listW = math.max(190, math.floor(W * 0.34))
        local listH = H - 104
        local detailX = listX + listW + 16
        local detailY = listY
        local detailW = W - detailX - 24
        local detailH = listH
        local visibleRows = math.max(6, math.floor((listH - 36) / 24))
        local entry = currentEntry()
        local data, path = currentMovelist()
        local totalRows = countMoveRows(data)
        local visibleMoveRows = math.max(8, math.floor((detailH - 72) / 20))

        syncListWindow(visibleRows)
        moveScroll = math.max(0, math.min(moveScroll, math.max(0, totalRows - visibleMoveRows)))

        drawText("MOVE LIST", W / 2, 18, C.accent, 1.16, 1.16, "center")
        drawText("Biblioteca de movimientos", W / 2, 42, C.text, 0.72, 0.72, "center")

        panel(listX, listY, listW, listH, "PERSONAJES")
        panel(detailX, detailY, detailW, detailH, "DETALLE")

        if #entries == 0 then
            drawText("No hay personajes disponibles en el roster.", W / 2, H / 2 - 8, C.text_muted, 0.76, 0.76, "center")
            drawText("B: Volver", W / 2, H - 18, C.text_muted, 0.60, 0.60, "center")
        else
            local rowY = listY + 32
            for row = listTop, math.min(#entries, listTop + visibleRows - 1) do
                local item = entries[row]
                local y = rowY + (row - listTop) * 24
                local isSelected = row == selected
                rect(listX + 8, y, listW - 16, 20, isSelected and C.panel_alt or C.panel, isSelected and 255 or 220)
                if isSelected then
                    rect(listX + 8, y, 3, 20, focus == "list" and C.focus or C.accent)
                end

                drawText(trimLabel(item.name, 22), listX + 16, y + 4, item.hasMovelist and C.text or C.text_muted, 0.58, 0.58, "left")
                drawText(item.hasMovelist and "JSON" or "--", listX + listW - 14, y + 4, item.hasMovelist and C.good or C.warn, 0.46, 0.46, "right")
            end

            if entry then
                drawText(trimLabel(entry.name, 32), detailX + 16, detailY + 38, C.text, 0.92, 0.92, "left")
                drawText(entry.folder, detailX + 16, detailY + 60, C.text_muted, 0.48, 0.48, "left")

                if data then
                    if path then
                        drawText(trimLabel(path, 54), detailX + detailW - 14, detailY + 60, C.good, 0.42, 0.42, "right")
                    end

                    local cursorY = detailY + 88 - moveScroll * 20
                    for _, section in ipairs(data.sections or {}) do
                        if cursorY >= detailY + 70 and cursorY <= detailY + detailH - 24 then
                            rect(detailX + 12, cursorY, detailW - 24, 16, C.panel_alt)
                            drawText(section.name or "Seccion", detailX + 18, cursorY + 3, C.accent, 0.54, 0.54, "left")
                        end
                        cursorY = cursorY + 20

                        for _, move in ipairs(section.moves or {}) do
                            if cursorY >= detailY + 70 and cursorY <= detailY + detailH - 24 then
                                local moveColor = C.normal
                                if move.type == "special" then
                                    moveColor = C.special
                                elseif move.type == "super" then
                                    moveColor = C.super
                                end
                                drawText(trimLabel(move.name or "Movimiento", 28), detailX + 18, cursorY + 2, C.text, 0.52, 0.52, "left")
                                drawText(move.input or "", detailX + detailW - 18, cursorY + 2, moveColor, 0.52, 0.52, "right")
                            end
                            cursorY = cursorY + 20
                        end
                    end

                    if focus == "moves" then
                        rect(detailX + 10, detailY + 28, detailW - 20, 2, C.focus)
                    end
                else
                    drawText("Sin movelist.json", detailX + detailW / 2, detailY + math.floor(detailH / 2) - 12, C.text_muted, 0.80, 0.80, "center")
                    drawText("Generalo desde el editor web.", detailX + detailW / 2, detailY + math.floor(detailH / 2) + 8, C.text_muted, 0.58, 0.58, "center")
                end
            end

            local footer = "Lista: Arriba/Abajo  A o Der: Abrir  B: Volver"
            if focus == "moves" then
                footer = "Movelist: Arriba/Abajo  Izq o B: Lista"
            end
            drawText(footer, W / 2, H - 18, C.text_muted, 0.56, 0.56, "center")
        end

        if esc() or main.f_input(main.t_players, {"x"}) or (#entries == 0 and main.f_input(main.t_players, {"b", "s"})) then
            esc(false)
            setMatchNo(-1)
            break
        elseif #entries > 0 then
            if focus == "list" then
                if main.f_input(main.t_players, {"$U", "u"}) then
                    selected = selected - 1
                    if selected < 1 then
                        selected = #entries
                    end
                    moveScroll = 0
                    main.f_cmdBufReset()
                elseif main.f_input(main.t_players, {"$D", "d"}) then
                    selected = selected + 1
                    if selected > #entries then
                        selected = 1
                    end
                    moveScroll = 0
                    main.f_cmdBufReset()
                elseif main.f_input(main.t_players, {"$F", "r", "pal", "a"}) then
                    focus = "moves"
                    main.f_cmdBufReset()
                elseif main.f_input(main.t_players, {"b", "s"}) then
                    setMatchNo(-1)
                    break
                end
            else
                if main.f_input(main.t_players, {"$U", "u"}) then
                    moveScroll = math.max(0, moveScroll - 1)
                    main.f_cmdBufReset()
                elseif main.f_input(main.t_players, {"$D", "d"}) then
                    moveScroll = math.min(math.max(0, totalRows - visibleMoveRows), moveScroll + 1)
                    main.f_cmdBufReset()
                elseif main.f_input(main.t_players, {"$B", "l", "b", "s"}) then
                    focus = "list"
                    main.f_cmdBufReset()
                end
            end
        end

        refresh()
    end
end

local ok, err = pcall(main_execution)
if not ok then
    log("MOVELIST ERROR: " .. tostring(err))
    setMatchNo(-1)
end
