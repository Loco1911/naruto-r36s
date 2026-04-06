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

[command]
name = "HYPER"
command = ~D,DF,F,D,DF,F,a+b
time = 30

[command]
name = "SUPER 1"
command = ~D,DF,F,D,DF,F,a
time = 30

[command]
name = "SUPER 2"
command = ~D,DB,B,D,DB,B,a
time = 30

[command]
name = "SUPER 3"
command = ~D,DF,F,D,DF,F,b
time = 30

[command]
name = "SUPER 4"
command = ~D,DB,B,D,DB,B,b
time = 30

[command]
name = "SUPER 5"
command = ~D,DF,F,D,DF,F,c
time = 30

[command]
name = "SUPER 6"
command = ~D,DB,B,D,DB,B,c
time = 30

;-| Specials |-------------------------------------------------------
[command]
name = "SPECIAL 1"
command = ~D,DF,F,a
time = 15

[command]
name = "SPECIAL 2"
command = ~D,DB,B,a
time = 15

[command]
name = "SPECIAL 3"
command = ~D,DF,F,b
time = 15

[command]
name = "SPECIAL 4"
command = ~D,DB,B,b
time = 15

[command]
name = "SPECIAL 5"
command = ~D,DF,F,c
time = 15

[command]
name = "SPECIAL 6"
command = ~D,DB,B,c
time = 15

[command]
name = "SPECIAL 7"
command = ~B,DB,D,DF,F,a
time = 30

[command]
name = "SPECIAL 8"
command = ~F,DF,D,DB,B,a
time = 30

[command]
name = "SPECIAL 9"
command = ~B,DB,D,DF,F,b
time = 30

[command]
name = "SPECIAL 10"
command = ~F,DF,D,DB,B,b
time = 30

[command]
name = "SPECIAL 11"
command = ~B,DB,D,DF,F,c
time = 30

[command]
name = "SPECIAL 12"
command = ~F,DF,D,DB,B,c
time = 30

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

[Command]
name = "DD"     ;Required (do not remove)
command = D, D
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
trigger1 = ctrl
;===========================================================================
; Specials:
;===========================================================================
; Rasengan(HOLD)
[State -1, Rasengan(HOLD)]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 1500
value = 1000
Triggerall = command = "SPECIAL 1"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Kyubi Rasengan
[State -1, Kyubi Rasengan]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 1000
value = 1100
Triggerall = command = "SPECIAL 2"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Kuchiyose Gamakichi
[State -1, Kuchiyose Gamakichi]
type = ChangeState
triggerall = numhelper(1950) = 0
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 1000
value = 1900
triggerall = command = "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Kuchiyose Gamatatsu
[State -1, Kuchiyose Gamatatsu]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 1500
value = 1300
triggerall = command = "holddown"
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Fuuton Rasen Shuriken
[State -1, Fuuton Rasen Shuriken]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 500
value = 1400
Triggerall = command = "SPECIAL 5"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Kage Bunshin no Jutsu
[State -1, Kage Bunshin no Jutsu]
type = ChangeState
triggerall = numhelper(1602) = 0
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 500
Triggerall = command = "SPECIAL 3"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
value = 1600
;---------------------------------------------------------------------------
; Kuchiyose no Jutsu Combo
[State -1, Kuchiyose no Jutsu Combo]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 500
Triggerall = command = "SPECIAL 6"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
value = 1700
;---------------------------------------------------------------------------
; Rasenrengan
[State -1, Rasenrengan]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 500
Triggerall = command = "SPECIAL 4"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
value = 1800
;---------------------------------------------------------------------------
; Kyubi Rage
[State -1, Kyubi Rage]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
Triggerall = power >= 2000
value = 1500
triggerall = command = "holddown"
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Bijuudama 4 Tails
[State -1, Bijuudama 4 Tails]
type = ChangeState
triggerall = var(2) = 1
Triggerall = power >= 1000
value = 10000
Triggerall = command = "SPECIAL 1"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Kyubi Shock
[State -1, Kyubi Shock]
type = ChangeState
triggerall = numhelper(1603) = 0
triggerall = var(2) = 1
Triggerall = power >= 1000
value = 10300
Triggerall = command = "SPECIAL 3"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Angry Roar
[State -1, Angry Roar]
type = ChangeState
triggerall = var(2) = 1
Triggerall = power >= 2000
value = 10100
Triggerall = command = "SPECIAL 6"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Kyubi Hunt
[State -1, Kyubi Hunt]
type = ChangeState
triggerall = var(2) = 1
Triggerall = power >= 500
value = 10400
Triggerall = command = "SPECIAL 2"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Chakra Canon
[State -1, Chakra Canon]
type = ChangeState
triggerall = numhelper(10201) = 0
triggerall = var(2) = 1
Triggerall = power >= 2000
value = 10200
Triggerall = command = "SPECIAL 5"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
; Chakra Blast
[State -1, Chakra Blast]
type = ChangeState
triggerall = var(2) = 1
Triggerall = power >= 1500
value = 10500
Triggerall = command = "SPECIAL 4"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;===========================================================================
;--------------------------------Ataques Normales---------------------------
;---------------------------------------------------------------------------
; Power Charge
[State -1, Power Charge]
type = ChangeState
triggerall = var(3) = 0
triggerall = var(2) = 0
triggerall = power < powermax
value = 500
triggerall = command = "s"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Power Charge 4 Tails Mode
[State -1, Power Charge]
type = ChangeState
triggerall = var(2) = 1
triggerall = power < powermax
value = 2500
triggerall = command = "s"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; 4 Tails Mode
[State -1, 4 Tails Mode]
type = ChangeState
Triggerall = life < lifemax /2
triggerall = ailevel = 0
Triggerall = power >= 1000
triggerall = var(2) = 0
value = 800
triggerall = command = "holddown"
triggerall = command = "s"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Combo 1
[State -1, Combo 1]
type = ChangeState
triggerall = var(2) = 0
value = 200
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Combo 2
[State -1, Combo 2]
type = ChangeState
triggerall = var(2) = 0
value = 300
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Combo 3
[State -1, Combo 3]
type = ChangeState
triggerall = var(2) = 0
value = 400
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Air Combo
[State -1, Air Combo]
type = ChangeState
triggerall = var(2) = 0
value = 600
triggerall = command = "a" || command = "b"|| command = "c"
Triggerall = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Combo 4 Tails
[State -1, Combo 4 Tails]
type = ChangeState
triggerall = var(2) = 1
value = 2200
triggerall = command = "a" || command = "b" || command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Air Combo 4 Tails
[State -1, Air Combo 4 Tails]
type = ChangeState
triggerall = var(2) = 1
value = 2600
triggerall = command = "a" || command = "b" || command = "c"
Triggerall = statetype = A
trigger1 = ctrl
