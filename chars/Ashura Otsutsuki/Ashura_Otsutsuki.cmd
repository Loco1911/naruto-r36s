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
name = "Sempou Rasengan"
command = ~D,DF,F,a
time = 15

[command]
name = "Kage Bunshin no Jutsu"
command = ~D,DB,B,a
time = 15

[command]
name = "Fuuma Shuriken"
command = ~D,DF,F,b
time = 15

[command]
name = "Kuchiyose Gamakichi"
command = ~D,DB,B,b
time = 15

[command]
name = "Rasenrengan"
command = ~D,DF,F,c
time = 15

[command]
name = "Bijuu Senkoodan"
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
command = y+z ; con el botón A+B activamos la AI
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
; Super Jump
[State -1, Super Jump]
type = ChangeState
value = 80
trigger1 = command = "Super Jump"
trigger1 = statetype = S
trigger1 = ctrl
;--------------------------------------------------------------------------
; Correr Adelante Ashura Mode
[State -1, Correr Adelante Ashura Mode]
type = ChangeState
value = 13060
Triggerall = var(4) = 1
trigger1 = command = "FF"
trigger1 = statetype != C
trigger1 = ctrl
;---------------------------------------------------------------------------
; Correr Atras Ashura Mode
[State -1, Correr Atras Ashura Mode]
type = ChangeState
value = 13070
Triggerall = var(4) = 1
trigger1 = command = "BB"
trigger1 = statetype != C
trigger1 = ctrl
;===========================================================================
;--------------------------------Ataques Supers-----------------------------
;---------------------------------------------------------------------------
; Kurama Mode
[State -1, Kurama Mode]
type = ChangeState
Triggerall = var(5) >= 250
Triggerall = var(3) = 1||var(4) = 1
value = 3400
triggerall = command = "holddown"
triggerall = command = "s"
trigger1 = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Kurama Mode Fin
[State -1, Kurama Mode Fin]
type = ChangeState
Triggerall = stateno = 3401||stateno = 3470
value = 3402
triggerall = command = "holddown"
triggerall = command = "s"
trigger1 = statetype != A
;---------------------------------------------------------------------------
; Senpo Yoton Rasen Shuriken
[State -1, Senpo Yoton Rasen Shuriken]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 2000
value = 3000
triggerall = command = "holddown"
triggerall = command = "a"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; Naruto Ittai Rendan
[State -1, Naruto Ittai Rendan]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 2500
value = 3100
triggerall = command = "holddown"
triggerall = command = "b"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; Senpo Cho Bijuu Rasen Shuriken
[State -1, Senpo Cho Bijuu Rasen Shuriken]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 3000
value = 3200
triggerall = command = "holddown"
triggerall = command = "c"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;===========================================================================
;--------------------------------Ataques Especiales-------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; 1
[State -1, 1]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 1000
value = 1000
triggerall = command = "Sempou Rasengan"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; 2
[State -1, 2]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 1000
value = 1100
triggerall = command = "Kage Bunshin no Jutsu"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; 3
[State -1, 3]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 1000
value = 1200
triggerall = command = "Fuuma Shuriken"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; 4
[State -1, 4]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 1000
value = 1300
triggerall = command = "Kuchiyose Gamakichi"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; 5
[State -1, 5]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 1500
value = 1400
triggerall = command = "Rasenrengan"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; 6
[State -1, 6]
type = ChangeState
Triggerall = var(4) = 1
Triggerall = power >= 1500
value = 1500
triggerall = command = "Bijuu Senkoodan"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = movecontact && (stateno = 13200||stateno = 13210||stateno = 13300||stateno = 13310||stateno = 13400||stateno = 13410||stateno = 13420)
trigger3 = stateno = 132200||stateno = 13323||stateno = 14003
trigger4 = time >= 120 && (stateno = 14500)
;===========================================================================
;--------------------------------Ataques Normales---------------------------
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
; Combo 1 Ashura Mode
[State -1, Combo 1 Ashura Mode]
type = ChangeState
Triggerall = var(4) = 1
value = 200
triggerall = command = "a"
trigger1 = statetype != A
trigger1 = ctrl
trigger3 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; Combo 2 Ashura Mode
[State -1, Combo 2 Ashura Mode]
type = ChangeState
Triggerall = var(4) = 1
value = 300
triggerall = command = "b"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; Combo 3 Ashura Mode
[State -1, Combo 3 Ashura Mode]
type = ChangeState
Triggerall = var(4) = 1
value = 400
triggerall = command = "c"
trigger1 = statetype != A
trigger1 = ctrl
trigger2 = stateno = 14003
trigger3 = time >= 120 && (stateno = 14500)
;---------------------------------------------------------------------------
; Combo Aire Ashura Mode
[State -1, Combo Aire Ashura Mode]
type = ChangeState
Triggerall = var(4) = 1
value = 600
triggerall = command = "a"||command = "b"||command = "c"
trigger1 = statetype = A
trigger1 = ctrl
trigger2 = time >= 190 && (stateno = 14100)
trigger3 = time >= 180 && (stateno = 14110)
;-------------------------------------------------------------------------------
; Activar IA
;-------------------------------------------------------------------------------
[State -2, Activar IA]
type = VarSet
trigger1 = (command = "AI1") ||(Command = "AI2") || (Command = "AI3") || (Command = "AI4") || (Command = "AI5")
trigger2 = (Command = "AI6") || (Command = "AI7") || (Command = "AI8") || (Command = "AI9") || (Command = "AI10")
trigger4 = (Command = "AI11") || (Command = "AI12") || (Command = "AI13") || (Command = "AI14")
var(9) = 1
