local storyboard = require('external/script/storyboard')

-- 1. Reproducir la cinemática en formato sprite
storyboard.f_storyboard("data/storymode/prologo/intro_video.def")

-- 2. Configurar la pelea
local fight_config = {
    p1char = {"G6_Naruto_Kid"},
    p1pal = 1,
    p2char = {"G6_Kakashi"},
    p2pal = 1,
    p2ai = 1,
    stage = "stages/01-Training_Field_NSUNS4.def",
    music = "sound/01-Training_Field_NSUNS4.mp3",
    rounds = 2
}

local winner = launchFight(fight_config)

-- ... (El resto de tu lógica de victoria/derrota sigue exactamente igual)

-- 3. INTERFAZ GRÁFICA DE RESULTADOS
local fuente_resultado = fontNew("font/menu0.fnt")
local txt_resultado = textImgNew()
textImgSetFont(txt_resultado, fuente_resultado)
textImgSetPos(txt_resultado, 160, 120)

if winner == 1 then
    textImgSetText(txt_resultado, "¡VICTORIA! KAKASHI DESBLOQUEADO")
    textImgSetColor(txt_resultado, 0, 255, 0) -- Verde
    
    -- Guardar progreso real
    main.t_stats.cap1_completado = true
    main.f_saveStats()
else
    textImgSetText(txt_resultado, "GAME OVER")
    textImgSetColor(txt_resultado, 255, 0, 0) -- Rojo
end

-- Bucle de espera
local timer = 180 
while timer > 0 do
    clearColor(0, 0, 0)
    textImgDraw(txt_resultado)
    
    if main.f_input(main.t_players, {'pal', 'a', 'b', 'c', 'x', 'y', 'z'}) then
        break
    end
    
    timer = timer - 1
    refresh()
end