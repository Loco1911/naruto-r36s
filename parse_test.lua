local function serializeDialogues(dialogues)
    if type(dialogues) ~= "table" or #dialogues == 0 then return "{}" end
    return "{}"
end
local function serializeHealthDialogues(dialogues) return "{}" end

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
          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.intro_done = true end
          else
             _G.story_status.intro_done = true
          end
       elseif roundno() == 1 and roundstate() == 4 and not _G.story_status.r1_done then
          local cand = %s
          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.r1_done = true end
          else
             _G.story_status.r1_done = true
          end
       elseif roundno() == 2 and roundstate() == 4 and not _G.story_status.r2_done then
          local cand = %s
          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.r2_done = true end
          else
             _G.story_status.r2_done = true
          end
       elseif roundno() == 3 and roundstate() == 4 and not _G.story_status.r3_done then
          local cand = %s
          if cand and #cand > 0 then
             _G.storyDlgData = cand
             _G.storyDlgCallback = function() _G.story_status.r3_done = true end
          else
             _G.story_status.r3_done = true
          end
       elseif roundstate() >= 2 and roundstate() <= 3 then
          local healthData = %s
          local triggered = {}
          if healthData and #healthData > 0 then
             for i, hpDlg in pairs(healthData) do
             end
          end
       end
    end
]=], 6, "", "", serializeDialogues({}), serializeDialogues({}), serializeDialogues({}), serializeDialogues({}), serializeHealthDialogues({}))

local f = io.open("generated.lua", "w")
f:write(aiScript)
f:close()
