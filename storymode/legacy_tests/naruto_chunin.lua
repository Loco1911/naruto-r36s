-- Arc script ejecutado por el loop de start.f_selectMode()

local SAVE_PATH = "save/naruto_chunin.json"
local DEFAULT_PROGRESS = { match = 1, flags = {} }
local STORYBOARD_DIR = "data/storymode/storyboards"
local INTRO_CUTSCENE = STORYBOARD_DIR .. "/cutscenes/01/cutscene.def"
local FALLBACK_CUTSCENE = INTRO_CUTSCENE

local function loadProgress()
  if not main.f_fileExists(SAVE_PATH) then
    return { match = DEFAULT_PROGRESS.match, flags = {} }
  end
  local ok, data = pcall(function()
    return json.decode(main.f_fileRead(SAVE_PATH))
  end)
  if not ok or type(data) ~= "table" then
    return { match = DEFAULT_PROGRESS.match, flags = {} }
  end
  data.match = tonumber(data.match) or DEFAULT_PROGRESS.match
  if type(data.flags) ~= "table" then
    data.flags = {}
  end
  return data
end

local function saveProgress(p)
  main.f_fileWrite(SAVE_PATH, json.encode(p, {indent = 2}))
end

local p = loadProgress()

-- Permite "resume": el arc se apoya en matchno() interno del engine,
-- pero también podés forzar setMatchNo(p.match) si querés que salte.
if matchno() ~= p.match then
  setMatchNo(p.match)
end

-- Helpers
local function cutscene(path, fallbackPath)
  if path ~= nil and main.f_fileExists(path) then
    launchStoryboard(path)
    return
  end
  if fallbackPath ~= nil and main.f_fileExists(fallbackPath) then
    launchStoryboard(fallbackPath)
    return
  end
  launchStoryboard(FALLBACK_CUTSCENE)
end

local function fight(cfg)
  local ok = launchFight(cfg)
  return ok
end

-- Secuencia principal
if matchno() == 1 then
  cutscene(INTRO_CUTSCENE, STORYBOARD_DIR .. "/chunin_intro.def")

  -- Ejemplo: Naruto vs Gaara (ajustá nombres a lo que tengas en select.def)
  local ok = fight{
    p1char = {"G6_Naruto_Kid"},
    p2char = {"G6_Kakashi/G6_Kakashi_story.def"},
    p1teammode = "single",
    p2teammode = "single",
    p2rounds = 2,
    stage = "stages/01-Training_Field_NSUNS4.def",
    vsscreen = false,
    victoryscreen = false,
    ai = 6,
    lua = [[
      if roundno() == 1 and roundstate() <= 1 then
        charMapSet(1, "storyNarutoChuninDialogue", 1)
        charMapSet(2, "storyNarutoChuninDialogue", 1)
      end
    ]]
  }

  if ok and winnerteam() == 1 then
    p.match = 2
    p.flags.beat_gaara = true
    saveProgress(p)
  else
    -- Derrota: checkpoint queda igual. Podés mostrar cutscene de derrota:
    cutscene(STORYBOARD_DIR .. "/chunin_fail_gaara.def")
    -- Si querés terminar el arco al perder:
    -- setMatchNo(-1)
  end

elseif matchno() == 2 then
  cutscene(STORYBOARD_DIR .. "/chunin_pre_final.def")

  local ok = fight{
    p1char = {"Naruto Baryon"},
    p2char = {"Pain (Animal Path)"},
    p1teammode = "single",
    p2teammode = "single",
    p2rounds = 2,
    stage = "stages/Konoha_Destroyed.def",
    ai = 7,
    vsscreen = false,
    victoryscreen = false,

    -- Código ejecutado cada frame: ej. 1 “heal” por match al 20% de vida
    lua = [[
      if roundstate() == 2 then
        player(1)
        if alive() and life() <= lifemax() * 0.20 and map("story_heal_used") == 0 then
          setLife(math.floor(lifemax() * 0.60))
          setPower(0)
          mapSet("story_heal_used", 1)
        end
      end
    ]]
  }

  if ok and winnerteam() == 1 then
    cutscene(STORYBOARD_DIR .. "/chunin_ending.def")
    -- terminar arco:
    setMatchNo(-1)
  else
    cutscene(STORYBOARD_DIR .. "/chunin_fail_final.def")
  end

else
  -- fallback: si no hay más contenido, salir
  setMatchNo(-1)
end
