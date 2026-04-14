-- storymode/main.lua
-- Timeline-based story mode UI for IKEMEN GO

local function log(msg)
    local f = io.open("storymode/debug.log", "a")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. "[MAIN] " .. msg .. "\n")
        f:close()
    end
end

log("--- Story Mode Session Start ---")

local function clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function trimLabel(str, maxLen)
    str = tostring(str or "")
    if #str <= maxLen then
        return str
    end
    return string.sub(str, 1, math.max(1, maxLen - 2)) .. ".."
end

local function safeString(str, fallback)
    if str == nil or str == "" then
        return fallback or ""
    end
    return tostring(str)
end

local function main_execution()
    log("Loading common.lua")
    local story = dofile("storymode/common.lua")

    log("Loading catalog.lua")
    local catalog = dofile("storymode/catalog.lua")

    if type(catalog) ~= "table" or #catalog == 0 then
        log("No catalog found, exiting")
        setMatchNo(-1)
        return
    end

    local lc = motif.info.localcoord or {640, 480}
    local W, H = lc[1] or 640, lc[2] or 480

    local C = {
        bg         = {0, 0, 0},
        panel      = {10, 13, 19},
        panel_alt  = {14, 18, 26},
        panel_hi   = {18, 24, 34},
        border     = {36, 44, 58},
        accent     = {255, 132, 24},
        accent_dim = {140, 88, 32},
        text       = {228, 234, 244},
        text_muted = {130, 142, 160},
        text_dark  = {26, 28, 34},
        track      = {92, 104, 124},
        locked     = {70, 76, 88},
        locked_bd  = {54, 58, 66},
        cleared    = {62, 190, 104},
        cleared_bd = {30, 120, 62},
        normal     = {210, 176, 84},
        normal_bd  = {120, 88, 28},
        side       = {86, 154, 232},
        side_bd    = {38, 88, 154},
        mid        = {224, 88, 88},
        mid_bd     = {130, 40, 40},
        boss       = {180, 96, 232},
        boss_bd    = {102, 48, 140},
        select     = {255, 210, 64},
    }
    local PANEL_HEADER_H = 24
    local PANEL_INSET = 16

    local SCALE = {
        title = 0.68,
        subtitle = 0.50,
        panel = 0.58,
        rowTitle = 0.54,
        rowMeta = 0.46,
        detailTitle = 0.58,
        detailLabel = 0.50,
        detailBody = 0.48,
        footer = 0.46,
        node = 0.62,
        nodeMeta = 0.60,
    }

    local fntBody = fontNew("font/BigBlueTermPlusNerdFont-Regular.def", -1)
    if not fntBody then
        fntBody = fontNew("font/FORCED SQUARE.def", -1)
    end
    if not fntBody and motif.title_info and motif.title_info.menu_item_font then
        local key = motif.title_info.menu_item_font[1] .. motif.title_info.menu_item_font[7]
        fntBody = main.font[key]
    end
    local fntTitle = fntBody
    local fntSmall = fntBody

    local storyBg = story.createMotifSpriteBackground(0, 0, W, H, 320, 240)

    local ti = {}
    for i = 1, 48 do
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

    local function rect(x, y, w, h, col, alpha, depth)
        if w > 0 and h > 0 then
            fillRect(x, y, w, h, col[1], col[2], col[3], alpha or 255, depth or 0)
        end
    end

    local function frame(x, y, w, h, border, fill, borderAlpha, fillAlpha)
        rect(x, y, w, h, border, borderAlpha or 255)
        rect(x + 1, y + 1, math.max(0, w - 2), math.max(0, h - 2), fill, fillAlpha or borderAlpha or 255)
    end

    local function panel(x, y, w, h, title, accent)
        frame(x, y, w, h, C.border, C.panel, 245, 242)
        rect(x, y, w, PANEL_HEADER_H, accent or C.panel_hi, 236)
        if title and title ~= "" then
            local obj = nextText()
            textImgSetFont(obj, fntSmall)
            textImgSetAlign(obj, 1)
            textImgSetText(obj, tostring(title))
            textImgSetPos(obj, x + 10 + main.f_alignOffset(1), y + 5)
            textImgSetColor(obj, C.text[1], C.text[2], C.text[3])
            textImgSetScale(obj, SCALE.panel, SCALE.panel)
            textImgSetWindow(obj, 0, 0, W, H)
            textImgDraw(obj)
        end
    end

    local function drawText(str, x, y, col, sx, sy, align, font)
        local chosenFont = font or fntBody
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
        if maxLines and #lines > maxLines then
            while #lines > maxLines do
                table.remove(lines)
            end
        end
        if maxLines and #lines == maxLines and #words > 0 then
            local consumed = 0
            for _, wrapped in ipairs(lines) do
                for _ in wrapped:gmatch("%S+") do
                    consumed = consumed + 1
                end
            end
            if consumed < #words then
                lines[#lines] = trimLabel(lines[#lines], math.max(1, maxChars - 1))
            end
        end
        return lines
    end

    local function drawWrappedText(str, x, y, maxChars, maxLines, lineHeight, col, sx, sy, align, font)
        local lines = wrapText(str, maxChars, maxLines)
        for i, line in ipairs(lines) do
            drawText(line, x, y + (i - 1) * lineHeight, col, sx, sy, align, font)
        end
        return y + (#lines * lineHeight)
    end

    local function arcHeader(index)
        return "SAGA " .. tostring(index)
    end

    local function arcName(index, title)
        local raw = safeString(title, "Saga " .. tostring(index))
        local stripped = raw:gsub("^%s*[Ss]aga%s*[%w]+%s*[:%-]?%s*", "")
        if stripped == "" or stripped == raw then
            return raw
        end
        return stripped
    end

    local function drawBackground()
        clearColor(0, 0, 0)
        story.drawMotifSpriteBackground(storyBg, 0, 0)
        rect(0, 0, W, H, C.bg, 112)
    end

    local function summarizeTeam(list, maxLen)
        return trimLabel(table.concat(list or {}, ", "), maxLen or 42)
    end

    local function stageLabel(path)
        local raw = safeString(path, "No definido"):gsub("\\", "/")
        local name = raw:match("([^/]+)%.def$") or raw:match("([^/]+)$") or raw
        name = name:gsub("_", " ")
        name = name:gsub("%s+", " ")
        return trimLabel(name, 28)
    end

    local function battleFormat(chapter)
        local p1Count = math.max(1, #(chapter.p1 or {}))
        local p2Count = math.max(1, #(chapter.p2 or {}))
        return tostring(p1Count) .. " VS " .. tostring(p2Count)
    end

    local function battleTimeLabel()
        local roundTime = type(config) == "table" and config.RoundTime or 99
        if roundTime == nil or roundTime == -1 then
            return "SIN LIMITE"
        end
        return tostring(roundTime) .. " SEG"
    end

    local function cpuLabel(chapter)
        local ai = tonumber(chapter.p2ai or chapter.ai or 0) or 0
        if ai <= 0 then
            return "CPU AUTO"
        end
        return "CPU NIVEL " .. tostring(ai)
    end

    local function typeColors(chapterType, unlocked, cleared)
        if not unlocked then
            return C.locked, C.locked_bd, C.text_muted
        end
        if cleared then
            return C.cleared, C.cleared_bd, C.text_dark
        end
        if chapterType == "sidestory" then
            return C.side, C.side_bd, C.text
        elseif chapterType == "midboss" then
            return C.mid, C.mid_bd, C.text
        elseif chapterType == "finalboss" then
            return C.boss, C.boss_bd, C.text
        end
        return C.normal, C.normal_bd, C.text_dark
    end

    local function typeLabel(chapterType)
        if chapterType == "sidestory" then
            return "SIDE STORY"
        elseif chapterType == "midboss" then
            return "MID BOSS"
        elseif chapterType == "finalboss" then
            return "FINAL BOSS"
        end
        return "CAPITULO"
    end

    local function nodeSize(chapterType)
        if chapterType == "finalboss" then
            return 34
        elseif chapterType == "midboss" then
            return 32
        end
        return 30
    end

    local function lettersForIndex(n)
        local s = ""
        n = math.max(1, tonumber(n) or 1)
        while n > 0 do
            local rem = (n - 1) % 26
            s = string.char(97 + rem) .. s
            n = math.floor((n - 1) / 26)
        end
        return s
    end

    local function buildLayout(arc)
        local chapters = arc.chapters or {}
        local byId = {}
        local mainOrder = {}
        local parentOf = {}
        local childMap = {}
        local columnOf = {}
        local laneOf = {}
        local labelOf = {}

        for i, chapter in ipairs(chapters) do
            if chapter.id and chapter.id ~= "" then
                byId[chapter.id] = i
            end
        end

        for i, chapter in ipairs(chapters) do
            local chapterType = chapter.type or "normal"
            if chapterType ~= "sidestory" then
                table.insert(mainOrder, i)
                columnOf[i] = #mainOrder
                laneOf[i] = 0
                labelOf[i] = tostring(#mainOrder)
            end
        end

        local function addChild(parentIdx, childIdx)
            if not childMap[parentIdx] then
                childMap[parentIdx] = {}
            end
            table.insert(childMap[parentIdx], childIdx)
            parentOf[childIdx] = parentIdx
        end

        local orphanSides = {}
        for i, chapter in ipairs(chapters) do
            if (chapter.type or "normal") == "sidestory" then
                local parentIdx = nil
                if chapter.sideUnlockAfter and byId[chapter.sideUnlockAfter] then
                    parentIdx = byId[chapter.sideUnlockAfter]
                end
                if not parentIdx then
                    for j = i - 1, 1, -1 do
                        local prevType = chapters[j].type or "normal"
                        if prevType ~= "sidestory" then
                            parentIdx = j
                            break
                        end
                    end
                end
                if parentIdx then
                    addChild(parentIdx, i)
                else
                    table.insert(orphanSides, i)
                end
            end
        end

        local function assignChildren(parentIdx)
            local children = childMap[parentIdx] or {}
            if #children == 0 then
                return
            end
            table.sort(children)

            if (laneOf[parentIdx] or 0) == 0 then
                local topCount = 0
                local bottomCount = 0
                for pos, childIdx in ipairs(children) do
                    if pos % 2 == 1 then
                        topCount = topCount + 1
                        laneOf[childIdx] = -topCount
                    else
                        bottomCount = bottomCount + 1
                        laneOf[childIdx] = bottomCount
                    end
                    columnOf[childIdx] = columnOf[parentIdx] or 1
                    labelOf[childIdx] = safeString(labelOf[parentIdx], "1") .. lettersForIndex(pos)
                    assignChildren(childIdx)
                end
            else
                local sign = laneOf[parentIdx] < 0 and -1 or 1
                local base = math.abs(laneOf[parentIdx])
                for pos, childIdx in ipairs(children) do
                    laneOf[childIdx] = sign * (base + pos)
                    columnOf[childIdx] = columnOf[parentIdx] or 1
                    labelOf[childIdx] = safeString(labelOf[parentIdx], "1") .. lettersForIndex(pos)
                    assignChildren(childIdx)
                end
            end
        end

        for _, idx in ipairs(mainOrder) do
            assignChildren(idx)
        end

        for i, idx in ipairs(orphanSides) do
            columnOf[idx] = 1
            laneOf[idx] = (i % 2 == 1) and -math.ceil(i / 2) or math.ceil(i / 2)
            labelOf[idx] = "1" .. lettersForIndex(i)
            assignChildren(idx)
        end

        local nodes = {}
        local maxAbsLane = 0
        for i, chapter in ipairs(chapters) do
            nodes[i] = {
                idx = i,
                chapter = chapter,
                col = columnOf[i] or clamp(i, 1, math.max(1, #mainOrder)),
                lane = laneOf[i] or 0,
                parent = parentOf[i],
                label = safeString(labelOf[i], tostring(i)),
            }
            maxAbsLane = math.max(maxAbsLane, math.abs(nodes[i].lane))
        end

        return {
            nodes = nodes,
            mainOrder = mainOrder,
            columns = math.max(1, #mainOrder),
            maxAbsLane = maxAbsLane,
        }
    end

    local function buildArcStats(arc, progress)
        local normalCount = 0
        local sideCount = 0
        local bossCount = 0
        local clearedCount = 0
        local total = #(arc.chapters or {})
        for _, chapter in ipairs(arc.chapters or {}) do
            local chapterType = chapter.type or "normal"
            if chapterType == "sidestory" then
                sideCount = sideCount + 1
            elseif chapterType == "midboss" or chapterType == "finalboss" then
                bossCount = bossCount + 1
            else
                normalCount = normalCount + 1
            end
            if story.isChapterCleared(arc.id, chapter.id, progress) then
                clearedCount = clearedCount + 1
            end
        end
        return {
            normalCount = normalCount,
            sideCount = sideCount,
            bossCount = bossCount,
            clearedCount = clearedCount,
            total = total,
        }
    end

    local function findInitialChapter(arcIdx, progress)
        local arc = catalog[arcIdx]
        if not arc then
            return 1
        end
        local layout = buildLayout(arc)
        for _, idx in ipairs(layout.mainOrder) do
            local chapter = arc.chapters[idx]
            if chapter
                and story.isChapterUnlocked(catalog, arcIdx, idx, progress)
                and not story.isChapterCleared(arc.id, chapter.id, progress) then
                return idx
            end
        end
        for _, idx in ipairs(layout.mainOrder) do
            local chapter = arc.chapters[idx]
            if chapter and story.isChapterUnlocked(catalog, arcIdx, idx, progress) then
                return idx
            end
        end
        return 1
    end

    local function moveHorizontal(layout, currentIdx, dir)
        local current = layout.nodes[currentIdx]
        if not current then
            return currentIdx
        end
        local bestIdx = currentIdx
        local bestScore = nil
        for idx, node in pairs(layout.nodes) do
            if dir < 0 and node.col < current.col or dir > 0 and node.col > current.col then
                local sameLanePenalty = node.lane == current.lane and 0 or 1000
                local score = sameLanePenalty + math.abs(node.col - current.col) * 10 + math.abs(node.lane - current.lane)
                if bestScore == nil or score < bestScore then
                    bestScore = score
                    bestIdx = idx
                end
            end
        end
        return bestIdx
    end

    local function moveVertical(layout, currentIdx, dir)
        local current = layout.nodes[currentIdx]
        if not current then
            return currentIdx
        end
        local bestIdx = currentIdx
        local bestScore = nil
        for idx, node in pairs(layout.nodes) do
            if dir < 0 and node.lane < current.lane or dir > 0 and node.lane > current.lane then
                local sameColPenalty = node.col == current.col and 0 or 100
                local score = sameColPenalty + math.abs(node.lane - current.lane) * 10 + math.abs(node.col - current.col)
                if bestScore == nil or score < bestScore then
                    bestScore = score
                    bestIdx = idx
                end
            end
        end
        return bestIdx
    end

    local state = {
        screen = "arcs",
        arcIdx = 1,
        chapterIdx = 1,
    }

    local initProgress = story.loadProgress()
    for i = 1, #catalog do
        if story.isArcUnlocked(catalog, i, initProgress) then
            state.arcIdx = i
        end
    end
    state.chapterIdx = findInitialChapter(state.arcIdx, initProgress)
    local function drawArcSelect(progress)
        local listX = 28
        local listY = 92
        local listW = math.floor(W * 0.38)
        local listH = H - 132
        local detailX = listX + listW + 16
        local detailY = listY
        local detailW = W - detailX - 28
        local detailH = listH
        local rowHeight = 62
        local rowsVisible = math.max(3, math.min(5, math.floor((listH - 42) / rowHeight)))
        local startRow = clamp(state.arcIdx - math.floor(rowsVisible / 2), 1, math.max(1, #catalog - rowsVisible + 1))
        local endRow = math.min(#catalog, startRow + rowsVisible - 1)

        drawText("MODO HISTORIA", W / 2, 24, C.accent, SCALE.title, SCALE.title, "center", fntTitle)

        panel(listX, listY, listW, listH, "SAGAS", C.panel_hi)
        panel(detailX, detailY, detailW, detailH, "DETALLES", C.panel_hi)

        local rowY = listY + PANEL_HEADER_H + 8
        for i = startRow, endRow do
            local arc = catalog[i]
            local y = rowY + (i - startRow) * rowHeight
            local selected = i == state.arcIdx
            local unlocked = story.isArcUnlocked(catalog, i, progress)

            rect(listX + 8, y, listW - 16, rowHeight - 6, selected and C.panel_hi or C.panel_alt, selected and 238 or 198)
            if selected then
                rect(listX + 8, y, 3, rowHeight - 6, C.accent, 255)
            end

            local headerCol = unlocked and (selected and C.accent or C.text_muted) or C.locked
            local titleCol = unlocked and C.text or C.text_muted
            drawText(arcHeader(i), listX + PANEL_INSET, y + 8, headerCol, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            drawWrappedText(arcName(i, arc.title), listX + PANEL_INSET, y + 24, 17, 2, 13, titleCol, SCALE.rowTitle, SCALE.rowTitle, "left", fntBody)
        end

        local arc = catalog[state.arcIdx]
        if arc then
            local unlocked = story.isArcUnlocked(catalog, state.arcIdx, progress)
            local cleared = story.isArcCleared(catalog, arc.id, progress)
            local stats = buildArcStats(arc, progress)
            local progressRatio = stats.total > 0 and (stats.clearedCount / stats.total) or 0
            local barW = detailW - 40

            local contentY = detailY + PANEL_HEADER_H + 8
            drawText(arcHeader(state.arcIdx), detailX + PANEL_INSET, contentY, C.text_muted, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            local titleBottom = drawWrappedText(arcName(state.arcIdx, arc.title), detailX + PANEL_INSET, contentY + 18, 22, 2, 15, C.text, SCALE.detailTitle, SCALE.detailTitle, "left", fntBody)
            local descY = titleBottom + 2
            local descBottom = drawWrappedText(safeString(arc.subtitle, "Sin descripcion"), detailX + PANEL_INSET, descY, 33, 4, 12, C.text_muted, SCALE.detailBody, SCALE.detailBody, "left", fntBody)

            local statusY = math.max(contentY + 98, descBottom + 14)
            drawText("ESTADO", detailX + PANEL_INSET, statusY, C.text_muted, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(unlocked and (cleared and "COMPLETADA" or "DISPONIBLE") or "BLOQUEADA", detailX + PANEL_INSET, statusY + 18, unlocked and (cleared and C.cleared or C.accent) or C.locked, SCALE.detailTitle, SCALE.detailTitle, "left", fntBody)

            local progressY = statusY + 50
            drawText("PROGRESO", detailX + PANEL_INSET, progressY, C.text_muted, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            frame(detailX + PANEL_INSET, progressY + 18, barW, 10, C.border, C.panel_alt, 220, 180)
            rect(detailX + PANEL_INSET + 2, progressY + 20, math.floor((barW - 4) * progressRatio), 6, C.accent, 240)
            drawText(stats.clearedCount .. " / " .. stats.total .. " CAPITULOS", detailX + PANEL_INSET, progressY + 34, C.text, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)

            local summaryY = progressY + 62
            drawText("RESUMEN", detailX + PANEL_INSET, summaryY, C.text_muted, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText("PRINCIPALES: " .. stats.normalCount, detailX + PANEL_INSET, summaryY + 18, C.text, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            drawText("SIDE STORIES: " .. stats.sideCount, detailX + PANEL_INSET, summaryY + 32, C.side, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            drawText("BOSSES: " .. stats.bossCount, detailX + PANEL_INSET, summaryY + 46, C.mid, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)

            if not unlocked and state.arcIdx > 1 then
                drawText("REQUISITO", detailX + PANEL_INSET, summaryY + 72, C.text_muted, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
                drawWrappedText("COMPLETA LA SAGA ANTERIOR PARA DESBLOQUEARLA.", detailX + PANEL_INSET, summaryY + 90, 30, 2, 14, C.locked, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            end
        end

        drawText("Arriba/Abajo: Navegar  A: Entrar  B: Volver", W / 2, H - 18, C.text_muted, SCALE.footer, SCALE.footer, "center", fntSmall)
    end

    local function drawNode(node, x, y, selected, unlocked, cleared)
        local nodeType = node.chapter.type or "normal"
        local fill, border, textCol = typeColors(nodeType, unlocked, cleared)
        local size = nodeSize(nodeType)

        if selected then
            rect(x - 3, y - 3, size + 6, size + 6, C.select, 230)
        end
        frame(x, y, size, size, border, fill)

        local badge = safeString(node.label, "?")
        local badgeScale = SCALE.node
        if #badge >= 4 then
            badgeScale = 0.38
        elseif #badge >= 3 then
            badgeScale = 0.46
        elseif #badge >= 2 then
            badgeScale = 0.54
        else
            badgeScale = 0.62
        end
        drawText(badge, x + math.floor(size / 2), y + math.floor(size / 2) - math.floor(5 * badgeScale), textCol, badgeScale, badgeScale, "center", fntBody)
        return size
    end

    local function drawMap(progress)
        local arc = catalog[state.arcIdx]
        local layout = buildLayout(arc)
        local currentNode = layout.nodes[state.chapterIdx] or layout.nodes[1]
        local visibleCols = clamp(math.floor((W - 120) / 104), 4, 6)
        local focusCol = currentNode and currentNode.col or 1
        local firstCol = clamp(focusCol - math.floor(visibleCols / 2), 1, math.max(1, layout.columns - visibleCols + 1))
        local lastCol = math.min(layout.columns, firstCol + visibleCols - 1)
        local colCount = math.max(1, lastCol - firstCol + 1)

        local mapX = 24
        local mapY = 96
        local mapW = W - 48
        local mapH = math.floor(H * 0.31)
        local infoY = mapY + mapH + 10
        local infoH = H - infoY - 34
        local visibleMaxLane = 0

        local visibleNodes = {}
        for idx, node in pairs(layout.nodes) do
            if node.col >= firstCol and node.col <= lastCol then
                visibleNodes[idx] = node
                visibleMaxLane = math.max(visibleMaxLane, math.abs(node.lane))
            end
        end

        local laneSpacing = math.max(34, math.min(50, math.floor((mapH - 52) / math.max(1, visibleMaxLane * 2 + 1))))
        local midY = mapY + math.floor(mapH / 2) - math.floor(nodeSize("normal") / 2)
        local colSpacing = colCount > 1 and math.max(84, math.floor((mapW - 96) / (colCount - 1))) or 0
        local startX = colCount > 1 and math.floor(mapX + (mapW - ((colCount - 1) * colSpacing)) / 2) or math.floor(mapX + mapW / 2)
        local pos = {}

        for idx, node in pairs(visibleNodes) do
            local slot = node.col - firstCol
            pos[idx] = {
                x = startX + slot * colSpacing,
                y = midY + node.lane * laneSpacing,
            }
        end

        drawText("MODO HISTORIA", W / 2, 24, C.accent, SCALE.title, SCALE.title, "center", fntTitle)
        drawWrappedText(arcName(state.arcIdx, arc.title), W / 2, 50, 28, 2, 14, C.text, SCALE.subtitle, SCALE.subtitle, "center", fntBody)

        panel(mapX, mapY, mapW, mapH, "TIMELINE", C.panel_hi)
        panel(mapX, infoY, mapW, infoH, "DETALLES", C.panel_hi)

        if #layout.mainOrder == 0 then
            drawText("Esta saga no tiene capitulos.", W / 2, mapY + math.floor(mapH / 2), C.text_muted, 0.76, 0.76, "center")
        else
            for i = 1, #layout.mainOrder - 1 do
                local aIdx = layout.mainOrder[i]
                local bIdx = layout.mainOrder[i + 1]
                if pos[aIdx] and pos[bIdx] then
                    local ax = pos[aIdx].x
                    local bx = pos[bIdx].x
                    local aHalf = math.floor(nodeSize(layout.nodes[aIdx].chapter.type or "normal") / 2)
                    local bHalf = math.floor(nodeSize(layout.nodes[bIdx].chapter.type or "normal") / 2)
                    rect(ax + aHalf, pos[aIdx].y + aHalf, math.max(0, (bx + bHalf) - (ax + aHalf)), 3, C.track, 230)
                end
            end

            for idx, node in pairs(visibleNodes) do
                if node.parent and pos[node.parent] then
                    local from = pos[node.parent]
                    local to = pos[idx]
                    local fromHalf = math.floor(nodeSize(layout.nodes[node.parent].chapter.type or "normal") / 2)
                    local toHalf = math.floor(nodeSize(node.chapter.type or "normal") / 2)
                    local lineX = to.x + toHalf
                    local y1 = math.min(from.y + fromHalf, to.y + toHalf)
                    local y2 = math.max(from.y + fromHalf, to.y + toHalf)
                    rect(lineX, y1, 3, math.max(0, y2 - y1), C.track, 230)
                end
            end

            for idx, node in pairs(visibleNodes) do
                local chapter = node.chapter
                local unlocked = story.isChapterUnlocked(catalog, state.arcIdx, idx, progress)
                local cleared = story.isChapterCleared(arc.id, chapter.id, progress)
                local selected = idx == state.chapterIdx
                drawNode(node, pos[idx].x, pos[idx].y, selected, unlocked, cleared)
            end

            if firstCol > 1 then
                drawText("<", mapX + 14, midY + 10, C.accent, 0.74, 0.74, "center", fntBody)
            end
            if lastCol < layout.columns then
                drawText(">", mapX + mapW - 14, midY + 10, C.accent, 0.74, 0.74, "center", fntBody)
            end
        end

        local chapter = arc.chapters[state.chapterIdx]
        if chapter then
            local unlocked = story.isChapterUnlocked(catalog, state.arcIdx, state.chapterIdx, progress)
            local cleared = story.isChapterCleared(arc.id, chapter.id, progress)
            local statusText = cleared and "COMPLETADO" or (unlocked and "DISPONIBLE" or "BLOQUEADO")
            local statusCol = cleared and C.cleared or (unlocked and C.accent or C.locked)
            local typeText = typeLabel(chapter.type or "normal")

            local detailBaseY = infoY + PANEL_HEADER_H + 8
            local chapterTitleBottom = drawWrappedText(safeString(chapter.title, chapter.id or "Capitulo"), mapX + PANEL_INSET, detailBaseY, 28, 2, 14, C.text, SCALE.detailTitle, SCALE.detailTitle, "left", fntBody)
            drawText(typeText, mapX + PANEL_INSET, chapterTitleBottom + 2, C.text_muted, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(statusText, mapX + mapW - PANEL_INSET, detailBaseY, statusCol, SCALE.detailTitle, SCALE.detailTitle, "right", fntBody)

            local subtitle = safeString(chapter.subtitle, "Sin descripcion.")
            local subtitleBottom = drawWrappedText(subtitle, mapX + PANEL_INSET, chapterTitleBottom + 18, 56, 2, 13, C.text, SCALE.detailBody, SCALE.detailBody, "left", fntBody)

            local infoLeftX = mapX + PANEL_INSET
            local infoRightX = mapX + math.floor(mapW * 0.54)
            local infoY1 = subtitleBottom + 12
            drawText("P1", infoLeftX, infoY1, C.accent, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(summarizeTeam(chapter.p1, 40), infoLeftX, infoY1 + 14, C.text_muted, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            drawText("CPU", infoRightX, infoY1, C.accent, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(summarizeTeam(chapter.p2, 34), infoRightX, infoY1 + 14, C.text_muted, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)

            local infoY2 = infoY1 + 32
            drawText("IA", infoLeftX, infoY2, C.accent, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(cpuLabel(chapter), infoLeftX + 26, infoY2, C.text_muted, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            drawText("TIEMPO", infoRightX, infoY2, C.accent, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(battleTimeLabel(), infoRightX + 44, infoY2, C.text_muted, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)

            local infoY3 = infoY2 + 18
            drawText("FORMATO", infoLeftX, infoY3, C.accent, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(battleFormat(chapter), infoLeftX + 56, infoY3, C.text_muted, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            drawText("ESCENARIO", infoRightX, infoY3, C.accent, SCALE.detailLabel, SCALE.detailLabel, "left", fntSmall)
            drawText(stageLabel(chapter.stage), infoRightX + 64, infoY3, C.text_muted, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)

            if chapter.type == "sidestory" and chapter.sideUnlockAfter and chapter.sideUnlockAfter ~= "" then
                drawText("SE DESBLOQUEA TRAS: " .. trimLabel(chapter.sideUnlockAfter, 28), mapX + PANEL_INSET, infoY3 + 20, C.side, SCALE.rowMeta, SCALE.rowMeta, "left", fntSmall)
            end
        end

        drawText("Izq/Der: Timeline  Arriba/Abajo: Ramas  A: Iniciar  B: Volver", W / 2, H - 16, C.text_muted, SCALE.footer, SCALE.footer, "center", fntSmall)
    end

    local function inp(keys)
        return main.f_input(main.t_players, keys)
    end

    local function resetBuf()
        main.f_cmdBufReset()
    end

    log("Entering story loop")
    while true do
        main.f_cmdInput()
        local progress = story.loadProgress()

        drawBackground()
        rect(0, 0, W, 3, C.accent, 255)
        rect(0, H - 3, W, 3, C.accent_dim, 255)
        beginTextFrame()

        if state.screen == "arcs" then
            drawArcSelect(progress)
        else
            drawMap(progress)
        end

        if state.screen == "arcs" then
            if inp({"$U", "u"}) then
                state.arcIdx = state.arcIdx - 1
                if state.arcIdx < 1 then
                    state.arcIdx = #catalog
                end
                resetBuf()
            elseif inp({"$D", "d"}) then
                state.arcIdx = state.arcIdx + 1
                if state.arcIdx > #catalog then
                    state.arcIdx = 1
                end
                resetBuf()
            elseif inp({"pal", "a"}) then
                if story.isArcUnlocked(catalog, state.arcIdx, progress) then
                    state.chapterIdx = findInitialChapter(state.arcIdx, progress)
                    state.screen = "map"
                    log("Entering arc " .. tostring(state.arcIdx))
                end
                resetBuf()
            elseif esc() or inp({"b", "x", "s"}) then
                log("Exiting Story Mode from arc select")
                esc(false)
                setMatchNo(-1)
                break
            end
        else
            local arc = catalog[state.arcIdx]
            local layout = buildLayout(arc)
            if inp({"$B", "l"}) then
                state.chapterIdx = moveHorizontal(layout, state.chapterIdx, -1)
                resetBuf()
            elseif inp({"$F", "r"}) then
                state.chapterIdx = moveHorizontal(layout, state.chapterIdx, 1)
                resetBuf()
            elseif inp({"$U", "u"}) then
                state.chapterIdx = moveVertical(layout, state.chapterIdx, -1)
                resetBuf()
            elseif inp({"$D", "d"}) then
                state.chapterIdx = moveVertical(layout, state.chapterIdx, 1)
                resetBuf()
            elseif inp({"pal", "a"}) then
                local chapter = arc.chapters[state.chapterIdx]
                if chapter and story.isChapterUnlocked(catalog, state.arcIdx, state.chapterIdx, progress) then
                    log("Starting chapter " .. tostring(chapter.id))
                    story.playChapter(arc.id, chapter.id, chapter)
                    resetBuf()
                end
            elseif esc() or inp({"b", "x", "s"}) then
                state.screen = "arcs"
                resetBuf()
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
    log("CRITICAL LUA ERROR: " .. tostring(err))
    main.f_bgReset(motif[main.background].bg)
    main.f_fadeReset("fadein", motif[main.group])
    setMatchNo(-1)
end
