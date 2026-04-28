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

local function wrapText(str, maxChars, maxLines)
    local text = tostring(str or ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
    if text == "" then
        return {""}
    end
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    local lines = {}
    local line = ""
    for _, word in ipairs(words) do
        local candidate = line == "" and word or (line .. " " .. word)
        if #candidate <= maxChars then
            line = candidate
        else
            if line ~= "" then
                table.insert(lines, line)
            end
            line = word
        end
        if maxLines and #lines >= maxLines then
            break
        end
    end
    if line ~= "" and (not maxLines or #lines < maxLines) then
        table.insert(lines, line)
    end
    if maxLines and #lines == maxLines then
        lines[#lines] = trimLabel(lines[#lines], maxChars)
    end
    return lines
end

local function prettifyInput(str)
    str = tostring(str or "")
    local repl = {
        ["↖"] = "UB",
        ["↗"] = "UF",
        ["↙"] = "DB",
        ["↘"] = "DF",
        ["↑"] = "U",
        ["↓"] = "D",
        ["←"] = "B",
        ["→"] = "F",
    }
    for src, dst in pairs(repl) do
        str = str:gsub(src, dst)
    end
    str = str:gsub("Hold%s+", "Charge ")
    str = str:gsub("rel%s+", "Release ")
    local motions = {
        {"D%s*,%s*DF%s*,%s*F", "QCF"},
        {"D%s*,%s*DB%s*,%s*B", "QCB"},
        {"F%s*,%s*D%s*,%s*DF", "DP"},
        {"B%s*,%s*D%s*,%s*DB", "RDP"},
        {"B%s*,%s*DB%s*,%s*D%s*,%s*DF%s*,%s*F", "HCF"},
        {"F%s*,%s*DF%s*,%s*D%s*,%s*DB%s*,%s*B", "HCB"},
    }
    for _, pattern in ipairs(motions) do
        str = str:gsub(pattern[1], pattern[2])
    end
    str = str:gsub("Charge%s+([UDFB][UDFB]?)%s*,%s*([UDFB][UDFB]?)", "[%1] %2")
    str = str:gsub("Release%s+([A-Za-z])", "~%1")
    str = str:gsub("%f[%a]([abcxyzs])%f[%A]", string.upper)
    str = str:gsub("%s*%+%s*", " + ")
    str = str:gsub("%s*,%s*", ", ")
    str = str:gsub("%s+", " ")
    return str:match("^%s*(.-)%s*$")
end

local function splitInputText(str, maxLen)
    str = tostring(str or ""):match("^%s*(.-)%s*$")
    maxLen = maxLen or 36
    if str == "" then
        return {""}
    end
    local lines = {}
    local line = ""
    for part in str:gmatch("[^,]+,?") do
        part = part:gsub("^%s+", ""):gsub("%s+$", "")
        if part ~= "" then
            local candidate = line == "" and part or (line .. " " .. part)
            if #candidate <= maxLen then
                line = candidate
            else
                if line ~= "" then
                    table.insert(lines, line)
                end
                while #part > maxLen do
                    table.insert(lines, part:sub(1, maxLen))
                    part = part:sub(maxLen + 1)
                end
                line = part
            end
        end
    end
    if line ~= "" then
        table.insert(lines, line)
    end
    if #lines == 0 then
        table.insert(lines, str)
    end
    return lines
end

local function isAiCommandName(name)
    local text = tostring(name or ""):lower():match("^%s*(.-)%s*$")
    return text == "ai" or text:match("^ai%d") or text:match("^ai[%s_-]")
end

local function main_execution()
    log("Move List Viewer Start")
    local story = dofile("storymode/common.lua")

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
    local PANEL_HEADER_H = 28
    local PANEL_HEADER_PAD_X = 12
    local PANEL_INSET = 16
    local LIST_ROW_H = 28
    local LIST_ROW_BOX_H = 24
    local MOVE_ROW_H = 20
    local MAIN_FONT_H = 27

    local fntTitle = fontNew("font/BigBlueTermPlusNerdFont-Regular.def", -1)
    local fntMain = fontNew("font/Open_Sans.def", -1)
    if not fntMain then
        fntMain = fontNew("font/f-6x9.def", -1)
    end
    if not fntMain and motif.title_info and motif.title_info.menu_item_font then
        local key = motif.title_info.menu_item_font[1] .. motif.title_info.menu_item_font[7]
        fntMain = main.font[key]
    end
    if not fntTitle then
        fntTitle = fntMain
    end

    local bg = story.createMotifSpriteBackground(0, 0, W, H, 320, 240)

    local ti = {}
    for i = 1, 96 do
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
        rect(x, y, w, PANEL_HEADER_H, C.panel_alt)
        if title and title ~= "" then
            local scale = 0.68
            local obj = nextText()
            textImgSetFont(obj, fntMain)
            textImgSetAlign(obj, 1)
            textImgSetText(obj, tostring(title))
            textImgSetPos(obj, x + PANEL_HEADER_PAD_X + main.f_alignOffset(1), y + math.floor((PANEL_HEADER_H - MAIN_FONT_H * scale) / 2 + 0.5))
            textImgSetColor(obj, C.text[1], C.text[2], C.text[3])
            textImgSetScale(obj, scale, scale)
            textImgSetWindow(obj, 0, 0, W, H)
            textImgDraw(obj)
        end
    end

    local function drawText(str, x, y, col, sx, sy, align, font)
        local chosenFont = font or fntMain
        if not chosenFont then return end
        local obj = nextText()
        local a = 0
        if align == "left" then
            a = 1
        elseif align == "right" then
            a = -1
        end
        textImgSetFont(obj, chosenFont)
        textImgSetAlign(obj, a)
        textImgSetText(obj, tostring(str or ""))
        textImgSetPos(obj, x + main.f_alignOffset(a), y)
        textImgSetColor(obj, col[1], col[2], col[3])
        textImgSetScale(obj, sx or 1, sy or 1)
        textImgSetWindow(obj, 0, 0, W, H)
        textImgDraw(obj)
    end

    local function textYInBox(boxY, boxH, scale)
        return boxY + math.max(0, math.floor((boxH - MAIN_FONT_H * (scale or 1)) / 2 + 0.5))
    end

    local function drawWrappedText(str, x, y, maxChars, maxLines, lineHeight, col, sx, sy, align, font)
        local lines = wrapText(str, maxChars, maxLines)
        for i, line in ipairs(lines) do
            drawText(line, x, y + (i - 1) * lineHeight, col, sx, sy, align, font)
        end
        return y + (#lines * lineHeight)
    end

    local function drawBackground()
        clearColor(C.bg[1], C.bg[2], C.bg[3])
        story.drawMotifSpriteBackground(bg, 0, 0)
        rect(0, 0, W, H, C.bg, 178)
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
                    if type(decoded.sections) ~= "table" then
                        decoded.sections = {}
                    end
                    for _, section in ipairs(decoded.sections) do
                        if type(section) == "table" and type(section.moves) ~= "table" then
                            section.moves = {}
                        end
                    end
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
    local hold = {u = 0, d = 0, l = 0, r = 0}

    local function repeatInput(id, keys, delay, step)
        if main.f_input(main.t_players, keys) then
            hold[id] = hold[id] + 1
            local d = delay or 10
            local s = step or 2
            return hold[id] == 1 or (hold[id] > d and (hold[id] - d) % s == 0)
        end
        hold[id] = 0
        return false
    end

    local function resetCommandBuffer()
        if type(main.f_cmdBufReset) == "function" then
            main.f_cmdBufReset()
        end
    end

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

    local function moveRowCount(move)
        if type(move) ~= "table" or isAiCommandName(move.name) then
            return 0
        end
        return math.max(1, #splitInputText(prettifyInput(move.input), 28))
    end

    local function sectionMoveRows(section)
        local rows = 0
        for _, move in ipairs(type(section) == "table" and type(section.moves) == "table" and section.moves or {}) do
            rows = rows + moveRowCount(move)
        end
        return rows
    end

    local function countMoveRows(data)
        if not data then return 0 end
        local total = 0
        for _, section in ipairs(type(data.sections) == "table" and data.sections or {}) do
            local rows = sectionMoveRows(section)
            if rows > 0 then
                total = total + 1 + rows
            end
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
        if getKey() ~= "" then
            resetKey()
        end
        beginTextFrame()
        drawBackground()
        rect(0, 0, W, 3, C.accent)

        local listX = 32
        local listY = 88
        local listW = math.max(204, math.floor(W * 0.35))
        local listH = H - 126
        local detailX = listX + listW + 18
        local detailY = listY
        local detailW = W - detailX - 32
        local detailH = listH
        local visibleRows = math.max(6, math.floor((listH - 48) / LIST_ROW_H))
        local entry = currentEntry()
        local data = currentMovelist()
        local totalRows = countMoveRows(data)
        local infoRowY = detailY + PANEL_HEADER_H + 8
        local infoRowH = 24
        local movesTop = infoRowY + infoRowH + 14
        local visibleMoveRows = math.max(7, math.floor((detailY + detailH - 24 - movesTop) / MOVE_ROW_H))

        syncListWindow(visibleRows)
        moveScroll = math.max(0, math.min(moveScroll, math.max(0, totalRows - visibleMoveRows)))

        drawText("MOVE LIST", W / 2, 24, C.accent, 0.72, 0.72, "center", fntTitle)
        drawText("BIBLIOTECA DE MOVIMIENTOS", W / 2, 54, C.text, 0.56, 0.56, "center", fntMain)

        panel(listX, listY, listW, listH, "PERSONAJES")
        panel(detailX, detailY, detailW, detailH, "DETALLE")

        if #entries == 0 then
            drawText("No hay personajes disponibles en el roster.", W / 2, H / 2 - 8, C.text_muted, 0.76, 0.76, "center")
            drawText("B: Volver", W / 2, H - 18, C.text_muted, 0.60, 0.60, "center")
        else
            local rowY = listY + PANEL_HEADER_H + 8
            for row = listTop, math.min(#entries, listTop + visibleRows - 1) do
                local item = entries[row]
                local y = rowY + (row - listTop) * LIST_ROW_H
                local isSelected = row == selected
                local textY = textYInBox(y, LIST_ROW_BOX_H, 0.52)
                local statusY = textYInBox(y, LIST_ROW_BOX_H, 0.34)
                rect(listX + 8, y, listW - 16, LIST_ROW_BOX_H, isSelected and C.panel_alt or C.panel, isSelected and 255 or 220)
                if isSelected then
                    rect(listX + 8, y, 3, LIST_ROW_BOX_H, C.focus)
                end

                drawText(trimLabel(item.name, 20), listX + PANEL_INSET, textY, item.hasMovelist and C.text or C.text_muted, 0.52, 0.52, "left")
                drawText(item.hasMovelist and "OK" or "--", listX + listW - 16, statusY, item.hasMovelist and C.good or C.warn, 0.34, 0.34, "right")
            end

            if entry then
                drawText(trimLabel(entry.name, 28), detailX + PANEL_INSET, textYInBox(infoRowY, infoRowH, 0.56), C.text, 0.56, 0.56, "left")

                if data then
                    local status = totalRows == 1 and "1 entrada" or (tostring(totalRows) .. " entradas")
                    drawText(status, detailX + detailW - 16, textYInBox(infoRowY, infoRowH, 0.36), C.good, 0.36, 0.36, "right")

                    local cursorY = movesTop - moveScroll * MOVE_ROW_H
                    for _, section in ipairs(type(data.sections) == "table" and data.sections or {}) do
                        if sectionMoveRows(section) > 0 then
                            if type(section) == "table" and cursorY >= movesTop - MOVE_ROW_H and cursorY <= detailY + detailH - 24 then
                                rect(detailX + 12, cursorY, detailW - 24, 18, C.panel_alt)
                                drawText(section.name or "Seccion", detailX + PANEL_INSET, textYInBox(cursorY, 18, 0.46), C.accent, 0.46, 0.46, "left")
                            end
                            cursorY = cursorY + MOVE_ROW_H

                            for _, move in ipairs(type(section) == "table" and type(section.moves) == "table" and section.moves or {}) do
                                if moveRowCount(move) > 0 then
                                    local moveColor = C.normal
                                    if move.type == "special" then
                                        moveColor = C.special
                                    elseif move.type == "super" then
                                        moveColor = C.super
                                    end
                                    local inputLines = splitInputText(prettifyInput(move.input), 28)
                                    for lineIndex, inputText in ipairs(inputLines) do
                                        if cursorY >= movesTop - MOVE_ROW_H and cursorY <= detailY + detailH - 24 then
                                            if lineIndex == 1 then
                                                drawText(trimLabel(move.name or "Movimiento", 22), detailX + PANEL_INSET, textYInBox(cursorY, MOVE_ROW_H, 0.44), C.text, 0.44, 0.44, "left")
                                            end
                                            drawText(inputText, detailX + detailW - 18, textYInBox(cursorY, MOVE_ROW_H, 0.40), moveColor, 0.40, 0.40, "right")
                                        end
                                        cursorY = cursorY + MOVE_ROW_H
                                    end
                                end
                            end
                        end
                    end
                else
                    drawText("Sin movelist.json", detailX + detailW / 2, detailY + math.floor(detailH / 2) - 10, C.text_muted, 0.70, 0.70, "center")
                    drawText("Generalo desde el editor web.", detailX + detailW / 2, detailY + math.floor(detailH / 2) + 12, C.text_muted, 0.50, 0.50, "center")
                end
            end

            local footer = "Arriba/Abajo: Lista  Izq/Der: Comandos  Esc: Volver"
            drawText(footer, W / 2, H - 22, C.text_muted, 0.52, 0.52, "center")
        end

        if esc() then
            esc(false)
            setMatchNo(-1)
            break
        elseif #entries > 0 then
            if repeatInput("u", {"$U"}) then
                selected = selected - 1
                if selected < 1 then
                    selected = #entries
                end
                moveScroll = 0
            elseif repeatInput("d", {"$D"}) then
                selected = selected + 1
                if selected > #entries then
                    selected = 1
                end
                moveScroll = 0
            elseif repeatInput("l", {"$B", "l"}) then
                moveScroll = math.max(0, moveScroll - 1)
            elseif repeatInput("r", {"$F", "r"}) then
                moveScroll = math.min(math.max(0, totalRows - visibleMoveRows), moveScroll + 1)
            end
        end

        refresh()
    end
end

local ok, err = pcall(main_execution)
if not ok then
    if tostring(err):match("<game end>") then
        os.exit()
    end
    log("MOVELIST ERROR: " .. tostring(err))
    setMatchNo(-1)
end
