;===============================================================================
;-------------------------------Comandos----------------------------------------
;===============================================================================
[Remap]
x = x
y = y
z = z
a = a
b = b
c = c
s = s

[Command]
name = "Super Jump"
command = ~D,U
time = 10

;-| Default Values |-------------------------------------------------------
[command]
name = "Choujuu Giga Mice"
command = ~D,DB,B,b
time = 15

[command]
name = "Choujuu Giga Snakes"
command = ~D,DB,B,a
time = 15

[command]
name = "Choujuu Giga Lion"
command = ~D,DF,F,a
time = 15

[command]
name = "Choujuu Giga Diving Birds"
command = ~D,DF,F,c
time = 15

[command]
name = "Kunai Throw"
command = ~D,DF,F,b
time = 15

[command]
name = "Choujuu Giga Eagle"
command = ~D,DB,B,c
time = 15

[Defaults]

;-| Double Tap |-----------------------------------------------------------
[Command]
name = "FF"     ;Required (do not remove)
command = F, F
time = 10

[Command]
name = "BB"     ;Required (do not remove)
command = B, B
time = 10
;-| 2/3 Button Combination |-----------------------------------------------
[Command]
name = "recovery" ;Required (do not remove)
command = x+y
time = 1

[Command]
name = "recovery"
command = y+z
time = 1

[Command]
name = "recovery"
command = x+z
time = 1

[Command]
name = "recovery"
command = a+b
time = 1

[Command]
name = "recovery"
command = b+c
time = 1

[Command]
name = "recovery"
command = a+c
time = 1
;-| Dir + Button |---------------------------------------------------------
[Command]
name = "back_x"
command = /$B,x
time = 1

[Command]
name = "back_y"
command = /$B,y
time = 1

[Command]
name = "back_z"
command = /$B,z
time = 1

[Command]
name = "down_x"
command = /$D,x
time = 1

[Command]
name = "down_y"
command = /$D,y
time = 1

[Command]
name = "down_z"
command = /$D,z
time = 1

[Command]
name = "fwd_x"
command = /$F,x
time = 1

[Command]
name = "fwd_y"
command = /$F,y
time = 1

[Command]
name = "fwd_z"
command = /$F,z
time = 1

[Command]
name = "up_x"
command = /$U,x
time = 1

[Command]
name = "up_y"
command = /$U,y
time = 1

[Command]
name = "up_z"
command = /$U,z
time = 1

[Command]
name = "back_a"
command = /$B,a
time = 1

[Command]
name = "back_b"
command = /$B,b
time = 1

[Command]
name = "back_c"
command = /$B,c
time = 1

[Command]
name = "down_a"
command = /$D,a
time = 1

[Command]
name = "down_b"
command = /$D,b
time = 1

[Command]
name = "down_c"
command = /$D,c
time = 1

[Command]
name = "fwd_a"
command = /$F,a
time = 1

[Command]
name = "fwd_b"
command = /$F,b
time = 1

[Command]
name = "fwd_c"
command = /$F,c
time = 1

[Command]
name = "up_a"
command = /$U,a
time = 1

[Command]
name = "up_b"
command = /$U,b
time = 1

[Command]
name = "up_c"
command = /$U,c
time = 1
;-| Single Button |---------------------------------------------------------
[Command]
name = "a"
command = a
time = 1

[Command]
name = "b"
command = b
time = 1

[Command]
name = "c"
command = c
time = 1

[Command]
name = "x"
command = x
time = 1

[Command]
name = "y"
command = y
time = 1

[Command]
name = "z"
command = z
time = 1

[Command]
name = "s"
command = s
time = 1
;-| Single Dir |------------------------------------------------------------
[Command]
name = "fwd" ;Required (do not remove)
command = $F
time = 1

[Command]
name = "downfwd"
command = $DF
time = 1

[Command]
name = "down" ;Required (do not remove)
command = $D
time = 1

[Command]
name = "downback"
command = $DB
time = 1

[Command]
name = "back" ;Required (do not remove)
command = $B
time = 1

[Command]
name = "upback"
command = $UB
time = 1

[Command]
name = "up" ;Required (do not remove)
command = $U
time = 1

[Command]
name = "upfwd"
command = $UF
time = 1
;-| Hold Button |--------------------------------------------------------------
[Command]
name = "hold_x"
command = /x
time = 1

[Command]
name = "hold_y"
command = /y
time = 1

[Command]
name = "hold_z"
command = /z
time = 1

[Command]
name = "hold_a"
command = /a
time = 1

[Command]
name = "hold_b"
command = /b
time = 1

[Command]
name = "hold_c"
command = /c
time = 1

[Command]
name = "hold_s"
command = /s
time = 1
;-| Hold Dir |--------------------------------------------------------------
[Command]
name = "holdfwd" ;Required (do not remove)
command = /$F
time = 1

[Command]
name = "holddownfwd"
command = /$DF
time = 1

[Command]
name = "holddown" ;Required (do not remove)
command = /$D
time = 1

[Command]
name = "holddownback"
command = /$DB
time = 1

[Command]
name = "holdback" ;Required (do not remove)
command = /$B
time = 1

[Command]
name = "holdupback"
command = /$UB
time = 1

[Command]
name = "holdup" ;Required (do not remove)
command = /$U
time = 1

[Command]
name = "holdupfwd"
command = /$UF
time = 1
;---------- Comandos de la Inteligencia Artificial-----------------
; Comandos activadores
[Command]
name = "AI Prueba"
command = y+z ; con el bot? A+B activamos la AI
time = 1

[Command]
name = "AI desactivado"
command = b+c ; Con el boton B+C desactivamos la AI
time = 1

;---------- comandos para que la PC active la IA -------------------------
[command]
name = "AI1"
command = b,b,b,b,b,b,b,b,b,b,b
time = 1

[command]
name = "AI2"
command = b,c,b,c,b,c,b,c,b,c,b,c
time = 1

[command]
name = "AI3"
command = b,c,b,c,b,c,b,c,b,c,b
time = 1

[command]
name = "AI4"
command = a,b,a,b,a,b,a,b,a,b,a
time = 1

[command]
name = "AI5"
command = b,a,b,a,b,a,b,a,b,a,b
time = 1

[command]
name = "AI6"
command = b,b,b,b,z,b,z,b,z,z,z
time = 1

[command]
name = "AI7"
command = b,x,b,b,x,b,b,b,b,b,x
time = 1

[command]
name = "AI8"
command = b,y,b,b,b,y,b,b,b,b,y
time = 1

[command]
name = "AI9"
command = b,b,b,b,s,z,y,x,c,b,a
time = 1

[command]
name = "AI10"
command = z,b,x,y,b,b,c,b,b,b,a
time = 1

[command]
name = "AI11"
command = b,x,b,b,x,b,b,b,b,b,z
time = 1

[command]
name = "AI12"
command = b,y,b,s,b,y,b,b,b,b,y
time = 1

[command]
name = "AI13"
command = b,b,b,z,s,z,y,x,c,b,a
time = 1

[command]
name = "AI14"
command = z,b,x,y,b,b,c,b,b,c,a
time = 1
;---------------------------------------------------------------------------
[Statedef -1]
;===========================================================================
;---------------------------Basicos-----------------------------------------
;---------------------------------------------------------------------------
; Correr Adelante
[State -1, Correr Adelante]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 65
triggerall = stateno != 70
value = ifelse(pos y >= 0,60,65)
trigger1 = command = "FF"
trigger1 = statetype != C
trigger1 = ctrl
;---------------------------------------------------------------------------
; Correr Atras
[State -1, Correr Atras]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 65
triggerall = stateno != 70
value = 70
trigger1 = command = "BB"
trigger1 = statetype != C
trigger1 = ctrl
;===========================================================================
;--------------------------------Ataques Supers-----------------------------
;---------------------------------------------------------------------------
; 3400
[State -1, 3400]
type = ChangeState
Triggerall = power >= 1500
value = 3400
triggerall = command = "holddown"
triggerall = command = "b"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; 1800
[State -1, 1800]
type = ChangeState
triggerall = numhelper(1850) = 0
Triggerall = power >= 1500
value = 1800
triggerall = command = "holddown"
triggerall = command = "a"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; 3300
[State -1, 3300]
type = ChangeState
Triggerall = power >= 2000
value = 3300
triggerall = command = "holddown"
triggerall = command = "c"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;===========================================================================
;--------------------------------Ataques Especiales-------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; 2000
[State -1, 2000]
type = ChangeState
Triggerall = numhelper(9024) = 0
Triggerall = power >= 1000
value = 2000
triggerall = command = "Choujuu Giga Mice"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; 1900
[State -1, 1900]
type = ChangeState
Triggerall = numhelper(1950) = 0
Triggerall = power >= 1000
value = 1900
triggerall = command = "Choujuu Giga Snakes"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; 1200
[State -1, 1200]
type = ChangeState
Triggerall = numhelper(15000) = 0
Triggerall = power >= 1000
triggerall = statetype != A
value = 1200
triggerall = command = "Choujuu Giga Lion"
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; 1400
[State -1, 1400]
type = ChangeState
Triggerall = numhelper(1450) = 0
Triggerall = numhelper(1490) = 0
Triggerall = power >= 500
value = ifelse(statetype = A,1480,1400)
triggerall = command = "Kunai Throw"
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; 1700
[State -1, 1700]
type = ChangeState
Triggerall = numhelper(1730) = 0
Triggerall = power >= 1000
value = 1700
triggerall = command = "Choujuu Giga Eagle"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; 1600
[State -1, 1600]
type = ChangeState
Triggerall = numhelper(1501) = 0
Triggerall = power >= 1000
value = 1600
triggerall = command = "Choujuu Giga Diving Birds"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;===========================================================================
;--------------------------------Ataques Normales---------------------------
;---------------------------------------------------------------------------
; Combo 1
[State -1, Combo 1]
type = ChangeState
value = 200
triggerall = command = "a"
trigger1 = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Combo 2
[State -1, Combo 2]
type = ChangeState
value = 400
triggerall = command = "b"
trigger1 = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Combo 3
[State -1, Combo 3]
type = ChangeState
value = 300
triggerall = command = "c"
trigger1 = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Power Charge
[State -1, Power Charge]
type = ChangeState
Triggerall = power < 3000
value = 500
triggerall = command = "s"
trigger1 = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Awakening
[State -1, Awakening]
type = ChangeState
Triggerall = var(2) = 0
Triggerall = life < lifemax /2
Triggerall = power = 3000
value = 550
triggerall = command = "s"
trigger1 = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Combo Aire
[State -1, Combo Aire]
type = ChangeState
value = 600
triggerall = command = "a"||command = "b"||command = "c"
trigger1 = statetype = A
trigger1 = ctrl
