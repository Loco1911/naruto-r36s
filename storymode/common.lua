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

  -- Side-story: unlocked after a specific chapter is cleared
  if (chapter.type or "normal") == "sidestory" then
    local afterId = chapter.sideUnlockAfter
    if afterId and afterId ~= "" then
      -- Find the chapter with that id
      for _, cap in ipairs(arc.chapters or {}) do
        if cap.id == afterId then
          return story.isChapterCleared(arc.id, cap.id, progress)
        end
      end
    end
    -- No afterId → unlock with first chapter of arc
    if chapterIndex == 1 then return true end
    local prev = arc.chapters[chapterIndex - 1]
    return prev and story.isChapterCleared(arc.id, prev.id, progress) or false
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
  -- (Los textos ahora se renderizan in-fight, omitimos pre-looping)

  local p1char = chapterData.p1 or {"G6_Naruto_Kid"}
  local p2char = chapterData.p2 or {"G6_Kakashi/G6_Kakashi_story.def"}
  
  local p2ai = chapterData.p2ai or {}
  local dlgStr = serializeDialogues(chapterData.dialogues)
  
  local aiScript = string.format([=[
    if roundno() == 1 and roundstate() == 0 then
      setCom(2, %d)
%s
%s
    end

    if _G.story_dialog_played == nil then _G.story_dialog_played = false end

    if _G.storyDlgData == nil and not _G.story_dialog_played then
       _G.storyDlgData = %s
       _G.storyDlgIdx = 1
       _G.storyDlgWait = 0
       _G.storyDlgFont = fontNew("font/Open_Sans.def", -1)
      if not _G.storyDlgFont then
          _G.storyDlgFont = fontNew("font/f-6x9.def", -1)
      end
       _G.storyDlgTxt = textImgNew()
    end

    if roundno() == 1 and roundstate() <= 1 and not _G.story_dialog_played then
       if _G.storyDlgIdx <= #_G.storyDlgData then
           charMapSet(1, "storyDialogue", 1)
           charMapSet(2, "storyDialogue", 1)

           local w = motif.info.localcoord and motif.info.localcoord[1] or 640
           local h = motif.info.localcoord and motif.info.localcoord[2] or 480

           local dlg = _G.storyDlgData[_G.storyDlgIdx]
           local spk = dlg.speaker or "p1"
           local isP1 = (spk == "p1")
           local isP2 = (spk == "p2")
           local sColor = isP1 and {100, 180, 255} or isP2 and {255, 80, 80} or {255, 220, 80}
           local sName  = isP1 and "Aliado:" or isP2 and "Rival:" or (spk .. ":")

           local boxH = math.floor(h * 0.15)
           local boxY = h - boxH
           local px = math.floor(w * 0.04)

           fillRect(0, 0, w, h, 10, 10, 15, 120, 0)
           fillRect(0, boxY, w, boxY + boxH, 20, 26, 36, 240, 0)
           fillRect(0, boxY, w, boxY + math.max(2, math.floor(h * 0.01)), sColor[1], sColor[2], sColor[3], 255, 0)

           textImgSetFont(_G.storyDlgTxt, _G.storyDlgFont)
           local tScale = math.max(0.6, (h / 960) * 0.95)

           textImgSetColor(_G.storyDlgTxt, sColor[1], sColor[2], sColor[3])
           textImgSetPos(_G.storyDlgTxt, px, boxY + math.floor(boxH * 0.35))
           textImgSetAlign(_G.storyDlgTxt, -1)
           textImgSetScale(_G.storyDlgTxt, tScale * 1.1, tScale * 1.1)
           textImgSetText(_G.storyDlgTxt, sName)
           textImgDraw(_G.storyDlgTxt)

           textImgSetColor(_G.storyDlgTxt, 250, 250, 250)
           textImgSetPos(_G.storyDlgTxt, px, boxY + math.floor(boxH * 0.70))
           textImgSetAlign(_G.storyDlgTxt, -1)
           textImgSetScale(_G.storyDlgTxt, tScale, tScale)
           textImgSetText(_G.storyDlgTxt, dlg.text)
           textImgDraw(_G.storyDlgTxt)

           textImgSetColor(_G.storyDlgTxt, 150, 150, 150)
           textImgSetPos(_G.storyDlgTxt, w - px, h - math.floor(boxH * 0.15))
           textImgSetAlign(_G.storyDlgTxt, 1)
           textImgSetScale(_G.storyDlgTxt, tScale * 0.6, tScale * 0.6)
           textImgSetText(_G.storyDlgTxt, "Presiona A o Start para continuar")
           textImgDraw(_G.storyDlgTxt)

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
                   if main and main.f_cmdBufReset then main.f_cmdBufReset() end
               end
           else
               _G.storyDlgSkip = false
           end

       else
           charMapSet(1, "storyDialogue", 0)
           charMapSet(2, "storyDialogue", 0)
           _G.story_dialog_played = true
           _G.storyDlgData = nil
       end
    end
  ]=],
  p2ai[1] or chapterData.ai or 6,
  (#p2char > 1) and string.format("      setCom(4, %d)", p2ai[2] or chapterData.ai or 6) or "",
  (#p2char > 2) and string.format("      setCom(6, %d)", p2ai[3] or chapterData.ai or 6) or "",
  dlgStr)

  -- Reseteo general antes de una partida nueva (Reset global flag)
  _G.story_dialog_played = false
  main.f_cmdBufReset()

  local ok = launchFight{
    p1char = p1char,
    p2char = p2char,
    p1teammode = chapterData.p1teammode or ((#p1char > 1) and "simul" or "single"),
    p1numchars = #p1char,
    p2teammode = chapterData.p2teammode or ((#p2char > 1) and "simul" or "single"),
    p2numchars = #p2char,
    p2rounds = chapterData.p2rounds or 2,
    stage = chapterData.stage or "stages/01-Training_Field_NSUNS4.def",
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
  
  main.f_cmdBufReset()
  return cleared
end

return story
