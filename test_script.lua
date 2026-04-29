local function serializeDialogues(dialogues)
    if type(dialogues) ~= "table" or #dialogues == 0 then return "{}" end
    local str = "{"
    for i, dlg in ipairs(dialogues) do
        local spk = dlg.speaker or "p1"
        local txt = (dlg.text or ""):gsub('"', '\\"'):gsub('\n', ' '):gsub('%%', '%%%%')
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
        local txt = (dlg.text or ""):gsub('"', '\\"'):gsub('\n', ' '):gsub('%%', '%%%%')
        local tgt = dlg.target or "p1"
        local thr = tonumber(dlg.thresholdPercent) or 50
        str = str .. string.format("{speaker=\"%s\", text=\"%s\", target=\"%s\", threshold=%f},", spk, txt, tgt, thr)
    end
    str = str .. "}"
    return str
end

local aiScript = string.format([=[
    if roundno() == 1 and roundstate() == 0 then
      setCom(2, %d)
%s
%s
    end

    if _G.story_status == nil then
       _G.story_status = {
          intro_done = false, r1_done = false, r2_done = false, r3_done = false,
          health_done = {}
       }
    end

    if _G.storyDlgData == nil then
       if roundno() == 1 and roundstate() <= 1 and not _G.story_status.intro_done then
          local cand = %s
]=], 6, "", "", serializeDialogues({}), serializeDialogues({}))

print("Syntax OK!")
