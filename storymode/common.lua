local story = {}

local function log(msg)
    local f = io.open("storymode/debug.log", "a")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. "[COMMON] " .. msg .. "\n")
        f:close()
    end
end

local SAVE_PATH = "save/story_progress.json"
local INTRO_CUTSCENE = "storymode/storyboards/General/cutscene.def"

local function copyTable(t)
  local out = {}
  for k, v in pairs(t or {}) do
    out[k] = v
  end
  return out
end

local function clampSubstitutionCount(value)
  local n = math.floor(tonumber(value) or 3)
  if n < 0 then return 0 end
  if n > 3 then return 3 end
  return n
end

local function buildTeamPlayerNumbers(teamSide, count)
  local players = {}
  for i = 1, math.max(1, tonumber(count) or 1) do
    table.insert(players, teamSide + (i - 1) * 2)
  end
  return players
end

local function buildCharMapScriptLines(players, mapName, value)
  local lines = {}
  for _, pn in ipairs(players or {}) do
    table.insert(lines, string.format('      charMapSet(%d, "%s", %s)', pn, mapName, tostring(value)))
  end
  return table.concat(lines, "\n")
end

function story.createMotifSpriteBackground(group, number, width, height, fallbackW, fallbackH)
  if motif == nil or motif.files == nil or motif.files.spr_data == nil then
    return nil
  end
  local expr = string.format("%d,%d, 0,0, -1", tonumber(group) or 0, tonumber(number) or 0)
  local ok, anim = pcall(function()
    return animNew(motif.files.spr_data, expr)
  end)
  if not ok or anim == nil then
    return nil
  end
  animUpdate(anim)
  local info = animGetSpriteInfo(anim)
  local spriteW = tonumber(fallbackW) or 320
  local spriteH = tonumber(fallbackH) or 240
  if type(info) == "table" and type(info.Size) == "table" then
    spriteW = tonumber(info.Size[1]) or spriteW
    spriteH = tonumber(info.Size[2]) or spriteH
  end
  if fallbackW ~= nil and spriteW > tonumber(fallbackW) then
    spriteW = tonumber(fallbackW)
  end
  if fallbackH ~= nil and spriteH > tonumber(fallbackH) then
    spriteH = tonumber(fallbackH)
  end
  if spriteW <= 0 then spriteW = tonumber(fallbackW) or 320 end
  if spriteH <= 0 then spriteH = tonumber(fallbackH) or 240 end
  local targetW = tonumber(width) or 640
  local targetH = tonumber(height) or 480
  local scale = math.max(targetW / spriteW, targetH / spriteH)
  animSetScale(anim, scale, scale)
  animSetWindow(anim, 0, 0, targetW, targetH)
  return {
    anim = anim,
    width = targetW,
    height = targetH,
    offsetX = math.floor((targetW - spriteW * scale) / 2),
    offsetY = math.floor((targetH - spriteH * scale) / 2),
  }
end

function story.drawMotifSpriteBackground(bg, x, y)
  if bg == nil or bg.anim == nil then
    return
  end
  animUpdate(bg.anim)
  animSetWindow(bg.anim, 0, 0, bg.width or 640, bg.height or 480)
  animSetPos(bg.anim, (x or 0) + (bg.offsetX or 0), (y or 0) + (bg.offsetY or 0))
  animDraw(bg.anim)
end

local function loadJson(path, defaultValue)
  if not main.f_fileExists(path) then
    return copyTable(defaultValue)
  end
  local ok, data = pcall(function()
    return json.decode(main.f_fileRead(path))
  end)
  if not ok or type(data) ~= "table" then
    return copyTable(defaultValue)
  end
  return data
end

local function saveJson(path, data)
  main.f_fileWrite(path, json.encode(data, {indent = 2}))
end

function story.loadProgress()
  local progress = loadJson(SAVE_PATH, {chapters = {}})
  if type(progress.chapters) ~= "table" then
    progress.chapters = {}
  end
  return progress
end

function story.saveProgress(progress)
  saveJson(SAVE_PATH, progress)
end

function story.chapterKey(arcId, chapterId)
  return tostring(arcId) .. ":" .. tostring(chapterId)
end

function story.getChapterEntry(arcId, chapterId, progress)
  progress = progress or story.loadProgress()
  return progress.chapters[story.chapterKey(arcId, chapterId)]
end

function story.isChapterCleared(arcId, chapterId, progress)
  local entry = story.getChapterEntry(arcId, chapterId, progress)
  return type(entry) == "table" and entry.cleared == true
end

function story.setChapterCleared(arcId, chapterId, extraData)
  local progress = story.loadProgress()
  local key = story.chapterKey(arcId, chapterId)
  progress.chapters[key] = progress.chapters[key] or {}
  progress.chapters[key].cleared = true
  if type(extraData) == "table" then
    for k, v in pairs(extraData) do
      progress.chapters[key][k] = v
    end
  end
  story.saveProgress(progress)
end

function story.findArcIndex(catalog, arcId)
  for i, arc in ipairs(catalog or {}) do
    if arc.id == arcId then
      return i
    end
  end
  return nil
end

function story.isArcCleared(catalog, arcId, progress)
  local arcIndex = story.findArcIndex(catalog, arcId)
  if arcIndex == nil then
    return false
  end
  local arc = catalog[arcIndex]
  for _, chapter in ipairs(arc.chapters or {}) do
    if not story.isChapterCleared(arc.id, chapter.id, progress) then
      return false
    end
  end
  return true
end

function story.isArcUnlocked(catalog, arcIndex, progress)
  if arcIndex == nil or arcIndex < 1 or arcIndex > #(catalog or {}) then
    return false
  end
  if arcIndex == 1 then
    return true
  end
  return story.isArcCleared(catalog, catalog[arcIndex - 1].id, progress)
end

function story.isChapterUnlocked(catalog, arcIndex, chapterIndex, progress)
  if not story.isArcUnlocked(catalog, arcIndex, progress) then
    return false
  end
  local arc     = catalog[arcIndex]
  local chapter = arc.chapters[chapterIndex]
  if not chapter then return false end

  -- Already cleared → always accessible
  if story.isChapterCleared(arc.id, chapter.id, progress) then
    return true
  end

  -- Side-story: sequential unlocking within sibling groups
  if (chapter.type or "normal") == "sidestory" then
    -- Find this side story's parent chapter
    local parentId = chapter.sideUnlockAfter
    local parentIdx = nil
    if parentId and parentId ~= "" then
      for j, cap in ipairs(arc.chapters or {}) do
        if cap.id == parentId then
          parentIdx = j
          break
        end
      end
    end
    -- Fallback: find the previous non-sidestory chapter
    if not parentIdx then
      for j = chapterIndex - 1, 1, -1 do
        local prevType = (arc.chapters[j].type or "normal")
        if prevType ~= "sidestory" then
          parentIdx = j
          break
        end
      end
    end

    if not parentIdx then
      -- No parent found → first chapter behavior
      return true
    end

    local parentChapter = arc.chapters[parentIdx]
    -- Parent must be cleared first
    if not story.isChapterCleared(arc.id, parentChapter.id, progress) then
      return false
    end

    -- Collect all sibling side stories sharing this parent, in order
    local siblings = {}
    local parentChapterId = parentChapter.id
    for j, cap in ipairs(arc.chapters or {}) do
      if (cap.type or "normal") == "sidestory" then
        -- Check if this side story belongs to the same parent
        local capParentId = cap.sideUnlockAfter
        local capParentIdx = nil
        if capParentId and capParentId ~= "" then
          for k, pc in ipairs(arc.chapters or {}) do
            if pc.id == capParentId then
              capParentIdx = k
              break
            end
          end
        end
        if not capParentIdx then
          for k = j - 1, 1, -1 do
            if ((arc.chapters[k].type or "normal") ~= "sidestory") then
              capParentIdx = k
              break
            end
          end
        end
        if capParentIdx == parentIdx then
          table.insert(siblings, j)
        end
      end
    end

    -- First sibling → unlocked once parent is cleared (already checked above)
    if #siblings == 0 or siblings[1] == chapterIndex then
      return true
    end

    -- Find our position in the sibling list
    for pos, sibIdx in ipairs(siblings) do
      if sibIdx == chapterIndex then
        -- Must clear the previous sibling first
        local prevSibIdx = siblings[pos - 1]
        if prevSibIdx then
          local prevSib = arc.chapters[prevSibIdx]
          return prevSib and story.isChapterCleared(arc.id, prevSib.id, progress) or false
        end
        return true
      end
    end

    return true
  end

  -- Normal chapter: unlock when previous non-side chapter is cleared
  -- Find the previous non-side chapter
  for idx = chapterIndex - 1, 1, -1 do
    local cap = arc.chapters[idx]
    if (cap.type or "normal") ~= "sidestory" then
      if idx == 1 then return true end
      return story.isChapterCleared(arc.id, cap.id, progress)
    end
  end
  return true  -- first chapter in arc
end


function story.isCharacterUnlocked(charName)
   local catalogStr = main.f_fileRead("storymode/catalog.json")
   if catalogStr == "" then return true end
   local ok, catalog = pcall(function() return json.decode(catalogStr) end)
   if not ok or type(catalog) ~= "table" then return true end
   
   local progress = story.loadProgress()
   local isEnemyInStory = false
   for _, arc in ipairs(catalog) do
       for _, chapter in ipairs(arc.chapters or {}) do
           local p2list = chapter.p2 or {}
           for _, c in ipairs(p2list) do
               local baseName = c:match("^([^/]+)") or c
               if baseName == charName then
                   isEnemyInStory = true
                   if story.isChapterCleared(arc.id, chapter.id, progress) then
                       return true
                   end
               end
           end
       end
   end
   if not isEnemyInStory then return true end
   return false
end

function story.isKakashiArcadeUnlocked()
  return story.isCharacterUnlocked("G6_Kakashi")
end

local function launchStoryboardIfExists(path)
  if path ~= nil and path ~= "" and main.f_fileExists(path) then
    launchStoryboard(path)
  end
end

local function serializeDialogues(dialogues)
    if type(dialogues) ~= "table" or #dialogues == 0 then return "{}" end
    local str = "{"
    for i, dlg in ipairs(dialogues) do
        local spk = dlg.speaker or "p1"
        local txt = story.escape(dlg.text or "")
        str = str .. string.format("{speaker=\"%s\", text=\"%s\"},", spk, txt)
    end
    str = str .. "}"
    return str
end

local function serializeHealthDialogues(dialogues)
    if type(dialogues) ~= "table" or #dialogues == 0 then return "{}" end
    local str = "{"
    for i, dlg in ipairs(dialogues) do
        local spk = dlg.speaker or "p1"
        local txt = story.escape(dlg.text or "")
        local tgt = dlg.target or "p1"
        local thr = tonumber(dlg.thresholdPercent) or 50
        str = str .. string.format("{speaker=\"%s\", text=\"%s\", target=\"%s\", threshold=%f},", spk, txt, tgt, thr)
    end
    str = str .. "}"
    return str
end

function story.escape(s)
    if not s then return "" end
    return s:gsub('"', '\\"'):gsub('\n', ' '):gsub('%%', '%%%%')
end

function story.playChapter(arcId, chapterId, chapterData)
  local alreadyCleared = story.isChapterCleared(arcId, chapterId)
  main.f_cmdBufReset()
  main.f_cmdBufReset()
  
  if chapterData.introStoryboard then
      launchStoryboardIfExists(chapterData.introStoryboard)
      main.f_cmdBufReset()
  end

  local p1char = chapterData.p1 or {"Naruto Uzumaki (Kid)"}
  local p2char = chapterData.p2 or {"Kakashi Hatake"}
  
  local p2ai = chapterData.p2ai or {}
  local p1Substitutions = clampSubstitutionCount(chapterData.p1Substitutions)
  local p2Substitutions = clampSubstitutionCount(chapterData.p2Substitutions)
  local p1Players = buildTeamPlayerNumbers(1, #p1char)
  local p2Players = buildTeamPlayerNumbers(2, #p2char)
  
  local dlgIntroStr = serializeDialogues(chapterData.dialogues)
  local dlgR1Str = serializeDialogues(chapterData.round1EndDialogues)
  local dlgR2Str = serializeDialogues(chapterData.round2EndDialogues)
  local dlgR3Str = serializeDialogues(chapterData.round3EndDialogues)
  local dlgHpStr = serializeHealthDialogues(chapterData.healthDialogues)
  
  local ai1 = tostring(p2ai[1] or chapterData.ai or 6)
  local ai2str = (#p2char > 1) and ("      setCom(4, " .. tostring(p2ai[2] or chapterData.ai or 6) .. ")") or ""
  local ai3str = (#p2char > 2) and ("      setCom(6, " .. tostring(p2ai[3] or chapterData.ai or 6) .. ")") or ""
  local ai1r = tostring(p2ai[1] or chapterData.ai or 6)
  local ai2r = (#p2char > 1) and ("           setCom(4, " .. tostring(p2ai[2] or chapterData.ai or 6) .. ")") or ""
  local ai3r = (#p2char > 2) and ("           setCom(6, " .. tostring(p2ai[3] or chapterData.ai or 6) .. ")") or ""
  local p1SubOverrideStr = buildCharMapScriptLines(p1Players, "_iksys_subOverride", 1)
  local p2SubOverrideStr = buildCharMapScriptLines(p2Players, "_iksys_subOverride", 1)
  local p1SubMaxStr = buildCharMapScriptLines(p1Players, "_iksys_subMax", p1Substitutions)
  local p2SubMaxStr = buildCharMapScriptLines(p2Players, "_iksys_subMax", p2Substitutions)

  local aiScript = [=[
    if roundstate() == 0 then
]=] .. p1SubOverrideStr .. [=[
]=] .. p2SubOverrideStr .. [=[
]=] .. p1SubMaxStr .. [=[
]=] .. p2SubMaxStr .. [=[
      setCom(2, ]=] .. ai1 .. [=[)
]=] .. ai2str .. [=[
]=] .. ai3str .. [=[
    end

    if _G.story_status == nil then
       _G.story_status = {
          intro_done = false, r1_done = false, r2_done = false, r3_done = false,
          health_done = {}
       }
    end

    if _G.storyDlgData == nil then
       if roundno() == 1 and roundstate() <= 1 and not _G.story_status.intro_done then
          local cand = ]=] .. dlgIntroStr .. [=[

          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.intro_done = true end
          else
             _G.story_status.intro_done = true
          end
       elseif roundno() == 1 and roundstate() == 4 and not _G.story_status.r1_done then
          local cand = ]=] .. dlgR1Str .. [=[

          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.r1_done = true end
          else
             _G.story_status.r1_done = true
          end
       elseif roundno() == 2 and roundstate() == 4 and not _G.story_status.r2_done then
          local cand = ]=] .. dlgR2Str .. [=[

          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.r2_done = true end
          else
             _G.story_status.r2_done = true
          end
       elseif roundno() == 3 and roundstate() == 4 and not _G.story_status.r3_done then
          local cand = ]=] .. dlgR3Str .. [=[

          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.r3_done = true end
          else
             _G.story_status.r3_done = true
          end
       elseif roundstate() >= 2 and roundstate() <= 3 then
          local healthData = ]=] .. dlgHpStr .. [=[

          local triggered = {}
          if healthData and #healthData > 0 then
             for i, hpDlg in ipairs(healthData) do
                 if not _G.story_status.health_done[i] then
                     local curPct = 100
                     local oldPl = 0
                     if hpDlg.target == "p2" then
                         if player(2) then curPct = (life() / lifemax()) * 100 end
                     else
                         if player(1) then curPct = (life() / lifemax()) * 100 end
                     end
                     player(1) -- restore local context safely

                     if curPct <= hpDlg.threshold then
                         table.insert(triggered, hpDlg)
                         _G.story_status.health_done[i] = true
                     end
                 end
             end
          end
          if #triggered > 0 then
              _G.storyDlgData = triggered
              _G.storyDlgCallback = function() end
          end
       end

       if _G.storyDlgData ~= nil then
           _G.storyDlgIdx = 1
           _G.storyDlgWait = 0
           _G.storyDlgFont = fontNew("font/Open_Sans.def", -1)
           if not _G.storyDlgFont then _G.storyDlgFont = fontNew("font/f-6x9.def", -1) end
           if not _G.storyDlgFont then _G.storyDlgFont = fontNew("font/8-BIT WONDER_STORY.def", -1) end
           _G.storyDlgNameTxt = textImgNew()
           _G.storyDlgBodyTxt = textImgNew()
           _G.storyDlgHintTxt = textImgNew()
       end
    end

    local function wrapDialogueText(str, maxChars, maxLines)
       local text = tostring(str or ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
       if text == "" then
          return ""
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
          local consumed = 0
          for _, wrapped in ipairs(lines) do
             for _ in wrapped:gmatch("%S+") do
                consumed = consumed + 1
             end
          end
          if consumed < #words then
             lines[#lines] = lines[#lines]:sub(1, math.max(1, maxChars - 2)) .. ".."
          end
       end
       return table.concat(lines, "\n")
    end

    if _G.storyDlgData ~= nil then
       if _G.storyDlgIdx <= #_G.storyDlgData then
           charMapSet(1, "storyDialogue", 1)
           charMapSet(2, "storyDialogue", 1)
           setCom(1, 0)
           setCom(2, 0)
           setCom(3, 0)
           setCom(4, 0)

           local dlg = _G.storyDlgData[_G.storyDlgIdx]
           local spk = dlg.speaker or "p1"
           local isP1 = (spk == "p1")
           local isP2 = (spk == "p2")
           local sColor = isP1 and {100, 180, 255} or isP2 and {255, 80, 80} or {255, 220, 80}
           local sName  = isP1 and "Aliado:" or isP2 and "Rival:" or (spk .. ":")

           -- fillRect uses raw game pixels (640x480), textImgSetPos uses localcoord (320x240)
           local gw = 640
           local gh = 480

           -- Keep the intro frozen via storyDialogue map while letting stage and idle anims render.
           if setRoundTime then setRoundTime(time()) end

           -- Dialogue box (fillRect in game coords 640x480)
           local boxW_g = math.floor(gw * 0.94)
           local boxH_g = math.floor(gh * 0.18)
           local boxY_g = gh - boxH_g - 10
           local offX = math.floor((gw - boxW_g) / 2)

           -- Semi-transparent screen overlay
           fillRect(0, 0, gw, gh, 10, 10, 15, 18, 0)
           -- Dark dialogue box at bottom
           fillRect(offX, boxY_g, boxW_g, boxH_g, 15, 18, 28, 220, 0)
           -- Colored speaker line at top of box
           fillRect(offX, boxY_g, boxW_g, 2, sColor[1], sColor[2], sColor[3], 255, 0)

           -- TextSprite positioning in this build matches fight coordinates (640x480).
           local textPadX = 10
           local nameY = boxY_g + 12
           local bodyY = boxY_g + 34
           local promptY = boxY_g + boxH_g - 12
           local bodyText = wrapDialogueText(dlg.text, 62, 3)
           local winX = 0
           local winY = 0
           local winW = gw
           local winH = gh

           -- Speaker name
           textImgSetFont(_G.storyDlgNameTxt, _G.storyDlgFont)
           textImgSetColor(_G.storyDlgNameTxt, sColor[1], sColor[2], sColor[3])
           textImgSetPos(_G.storyDlgNameTxt, offX + textPadX, nameY)
           textImgSetAlign(_G.storyDlgNameTxt, 1)
           textImgSetWindow(_G.storyDlgNameTxt, winX, winY, winW, winH)
           textImgSetScale(_G.storyDlgNameTxt, 0.40, 0.40)
           textImgSetText(_G.storyDlgNameTxt, sName)
           textImgDraw(_G.storyDlgNameTxt)

           -- Dialogue text
           textImgSetFont(_G.storyDlgBodyTxt, _G.storyDlgFont)
           textImgSetColor(_G.storyDlgBodyTxt, 250, 250, 250)
           textImgSetPos(_G.storyDlgBodyTxt, offX + textPadX, bodyY)
           textImgSetAlign(_G.storyDlgBodyTxt, 1)
           textImgSetWindow(_G.storyDlgBodyTxt, winX, winY, winW, winH)
           textImgSetScale(_G.storyDlgBodyTxt, 0.34, 0.34)
           textImgSetText(_G.storyDlgBodyTxt, bodyText)
           textImgDraw(_G.storyDlgBodyTxt)

           -- Prompt hint (bottom-right)
           textImgSetFont(_G.storyDlgHintTxt, _G.storyDlgFont)
           textImgSetColor(_G.storyDlgHintTxt, 120, 120, 120)
           textImgSetPos(_G.storyDlgHintTxt, offX + boxW_g - textPadX, promptY)
           textImgSetAlign(_G.storyDlgHintTxt, -1)
           textImgSetWindow(_G.storyDlgHintTxt, winX, winY, winW, winH)
           textImgSetScale(_G.storyDlgHintTxt, 0.24, 0.24)
           textImgSetText(_G.storyDlgHintTxt, "[A]")
           textImgDraw(_G.storyDlgHintTxt)

           local btnA = false
           if main and main.t_cmd then
               btnA = commandGetState(main.t_cmd[1], "a") or commandGetState(main.t_cmd[1], "start") or commandGetState(main.t_cmd[1], "y") or commandGetState(main.t_cmd[1], "z")
           elseif main and main.f_input then
               btnA = main.f_input(main.t_players, {"pal", "a", "start", "y", "x"})
           end

           if btnA then
               if not _G.storyDlgSkip then
                   _G.storyDlgIdx = _G.storyDlgIdx + 1
                   _G.storyDlgSkip = true
               end
           else
               _G.storyDlgSkip = false
           end
           
           if main and main.f_cmdBufReset then main.f_cmdBufReset() end

       else
           charMapSet(1, "storyDialogue", 0)
           charMapSet(2, "storyDialogue", 0)
           setCom(2, ]=] .. ai1r .. [=[)
]=] .. ai2r .. [=[
]=] .. ai3r .. [=[
           if _G.storyDlgCallback then _G.storyDlgCallback() end
           _G.storyDlgData = nil
           _G.storyDlgIdx = 0
       end
    end
  ]=]

  local fightStage = chapterData.stage or ""
  if fightStage == "" or fightStage:lower() == "random" or not main.f_fileExists(fightStage) then
      fightStage = "stages/01-Training_Field_NSUNS4/01-Training_Field_NSUNS4.def"
      if not main.f_fileExists(fightStage) then
          fightStage = "random"
      end
  end

  local fightRoundTime = nil
  if chapterData.roundTime ~= nil then
      local parsedRoundTime = tonumber(chapterData.roundTime)
      if parsedRoundTime ~= nil then
          fightRoundTime = math.floor(parsedRoundTime)
          if fightRoundTime < 0 then
              fightRoundTime = -1
          elseif fightRoundTime == 0 then
              fightRoundTime = nil
          end
      end
  end

  _G.story_status = nil
  _G.storyDlgData = nil
  _G.storyDlgIdx = 0
  _G.storyDlgWait = 0
  _G.storyDlgSkip = false
  _G.storyDlgCallback = nil
  _G.storyDlgFont = nil
  _G.storyDlgNameTxt = nil
  _G.storyDlgBodyTxt = nil
  _G.storyDlgHintTxt = nil
  main.f_cmdBufReset()

  local ok = launchFight{
    p1char = p1char,
    p2char = p2char,
    p1teammode = chapterData.p1teammode or ((#p1char > 1) and "simul" or "single"),
    p1numchars = #p1char,
    p2teammode = chapterData.p2teammode or ((#p2char > 1) and "simul" or "single"),
    p2numchars = #p2char,
    p2rounds = chapterData.p2rounds or 2,
    roundTime = fightRoundTime,
    stage = fightStage,
    vsscreen = chapterData.vsscreen or false,
    victoryscreen = chapterData.victoryscreen or false,
    ai = chapterData.ai or 6,
    lua = aiScript
  }

  local cleared = ok and winnerteam() == 1
  if cleared and not alreadyCleared then
    story.setChapterCleared(arcId, chapterId, {last_result = "win"})
    launchStoryboardIfExists(chapterData.winStoryboard)
  elseif cleared then
    launchStoryboardIfExists(chapterData.replayWinStoryboard or chapterData.winStoryboard)
  else
    launchStoryboardIfExists(chapterData.loseStoryboard)
  end

  _G.story_status = nil
  _G.storyDlgData = nil
  _G.storyDlgIdx = 0
  _G.storyDlgWait = 0
  _G.storyDlgSkip = false
  _G.storyDlgCallback = nil
  _G.storyDlgFont = nil
  _G.storyDlgNameTxt = nil
  _G.storyDlgBodyTxt = nil
  _G.storyDlgHintTxt = nil
  
  main.f_cmdBufReset()
  return cleared
end

return story
