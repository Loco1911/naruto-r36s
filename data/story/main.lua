function f_menuHistoria()
    local opcion_seleccionada = 1
    local opciones = {
        { nombre = "1. Prologo: El Entrenamiento", archivo = "data/story/prologo/cap1.lua", bloqueado = false },
        { nombre = "2. Mision Rango C (Bloqueado)", archivo = nil, bloqueado = true }
    }

    -- 1. Cargamos el archivo de la fuente en memoria
    local fuente_menu = fontNew("font/f-4x6.def")

    -- 2. Preparamos el título
    local txt_titulo = textImgNew()
    textImgSetFont(txt_titulo, fuente_menu) -- Pasamos el objeto, no un número
    textImgSetText(txt_titulo, "CRONICAS NINJA")
    textImgSetPos(txt_titulo, 160, 40)

    -- 3. Preparamos las opciones
    local txt_opcion = textImgNew()
    textImgSetFont(txt_opcion, fuente_menu)

    while true do
        clearColor(0, 0, 0) 
        textImgDraw(txt_titulo) 

        for i, opcion in ipairs(opciones) do
            textImgSetText(txt_opcion, opcion.nombre)
            textImgSetPos(txt_opcion, 100, 80 + (i * 20))
            
            if i == opcion_seleccionada then
                textImgSetColor(txt_opcion, 255, 0, 0) 
            elseif opcion.bloqueado then
                textImgSetColor(txt_opcion, 100, 100, 100) 
            else
                textImgSetColor(txt_opcion, 255, 255, 255) 
            end
            
            textImgDraw(txt_opcion)
        end

        if main.f_input(main.t_players, {'u'}) then
            opcion_seleccionada = opcion_seleccionada - 1
            if opcion_seleccionada < 1 then opcion_seleccionada = #opciones end
        elseif main.f_input(main.t_players, {'d'}) then
            opcion_seleccionada = opcion_seleccionada + 1
            if opcion_seleccionada > #opciones then opcion_seleccionada = 1 end
        end

        if main.f_input(main.t_players, {'pal', 'a', 'b', 'c', 'x', 'y', 'z'}) then
            if not opciones[opcion_seleccionada].bloqueado and opciones[opcion_seleccionada].archivo ~= nil then
                dofile(opciones[opcion_seleccionada].archivo)
                main.f_cmdBufReset() 
            end
        end

        if esc() then
            break
        end

        main.f_cmdInput()
        refresh() 
    end
end

f_menuHistoria()