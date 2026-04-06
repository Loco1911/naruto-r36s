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

;-| Supers |-------------------------------------------------------

;-| Specials |-------------------------------------------------------

[command]
name = "Recover"
command = ~B,DB,D,DF,F,a
time = 30

[command]
name = "Baryon Combo"
command = ~D,DF,F,a
time = 15

[command]
name = "Baryon Wave"
command = ~D,DB,B,a
time = 15

[command]
name = "Baryon Assault"
command = ~D,DB,B,b
time = 15

[command]
name = "Baryon Counter"
command = ~D,DF,F,b
time = 15

[command]
name = "Baryon Combo Advanced"
command = ~D,DB,B,c
time = 15

[command]
name = "Baryon Explosive Rock"
command = ~D,DF,F,c
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

[Command]
name = "F"     ;Required (do not remove)
command = B
time = 10

[Command]
name = "B"     ;Required (do not remove)
command = B
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
name = "down_s"
command = /$D,s
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
name = "back_z"
command = /$B,z
time = 1

[Command]
name = "down_a"
command = /$D,a
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
name = "Dodge" ;Required (do not remove)
command = D,D
time = 15

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
;--------------------------------Supers-----------------------------
;===========================================================================
;---------------------------------------------------------------------------
; Rasen Baryon
[State -1, Rasen Baryon]
type = ChangeState
triggerall = var(4) = 0
triggerall = var(2) = 0
Triggerall = power >= 3000
value = 3000
triggerall = command = "x"
Triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;===========================================================================
;-------------------------Ataques Speciales---------------------------------
;===========================================================================
; Baryon Combo
[State -1, Baryon Combo]
type = ChangeState
value = 1000
type = PlaySnd
Triggerall = power >= 1500
triggerall = var(4) = 0
triggerall = command = "Baryon Combo"
Triggerall = statetype != A
trigger1 = ctrl
;--------------------------------------------------------------------------
; Baryon Wave
[State -1, Baryon Wave]
type = ChangeState
value = 1100
type = PlaySnd
Triggerall = power >= 1500
triggerall = var(4) = 0
triggerall = command = "Baryon Wave"
Triggerall = statetype != A
trigger1 = ctrl
;--------------------------------------------------------------------------
; Baryon Assault
[State -1, Baryon Assault]
type = ChangeState
value = 1200
type = PlaySnd
Triggerall = power >= 1500
triggerall = var(4) = 0
triggerall = command = "Baryon Assault"
Triggerall = statetype != A
trigger1 = ctrl
;--------------------------------------------------------------------------
; Baryon Counter
[State -1, Baryon Counter]
type = ChangeState
value = 1300
type = PlaySnd
Triggerall = power >= 1500
triggerall = var(4) = 0
triggerall = command = "Baryon Counter"
Triggerall = statetype != A
trigger1 = ctrl
;--------------------------------------------------------------------------
; Baryon Combo Advanced
[State -1, Baryon Combo Advanced]
type = ChangeState
value = 1400
type = PlaySnd
Triggerall = power >= 1500
triggerall = var(4) = 0
triggerall = command = "Baryon Combo Advanced"
Triggerall = statetype != A
trigger1 = ctrl
;--------------------------------------------------------------------------
; Baryon Explosive Rock
[State -1, Baryon Explosive Rock]
type = ChangeState
value = 1500
type = PlaySnd
Triggerall = power >= 1500
triggerall = var(4) = 0
triggerall = command = "Baryon Explosive Rock"
Triggerall = statetype != A
trigger1 = ctrl
;===========================================================================
;---------------------------Basicos-----------------------------------------
;---------------------------------------------------------------------------
; Correr Adelante
[State -1, Correr Adelante]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 70
value = ifelse(pos y >= 0,60,67)
trigger1 = command = "FF"
trigger1 = ctrl
;---------------------------------------------------------------------------
; Correr Atras
[State -1, Correr Atras]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 70
value = ifelse(pos y >= 0,70,75)
trigger1 = command = "BB"
trigger1 = ctrl
;----------------------------------------------------------------------------
; Dodge
[State -1, Dodge]
type = ChangeState
value = 302
triggerall = var(2)=0
triggerall = command = "Dodge"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Super Jump
[State -1, Super Jump]
type = ChangeState
value = 80
trigger1 = command = "Super Jump"
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
; A
[State -1, A]
type = ChangeState
value = 200
type = PlaySnd
triggerall = var(4) = 0
triggerall = command != "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; A - Down
[State -1, A]
type = ChangeState
value = 216
type = PlaySnd
triggerall = p2statetype = A
triggerall = var(4) = 0
triggerall = command = "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;--------------------------------------------------------------------------
; B
[State -1, B]
type = ChangeState
value = 235
type = PlaySnd
triggerall = var(4) = 0
triggerall = command != "holddown"
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; B - Down
[State -1, B]
type = ChangeState
value = 218
type = PlaySnd
triggerall = p2statetype = A
triggerall = var(4) = 0
triggerall = command = "holddown"
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; C
[State -1, C]
type = ChangeState
value = 265
type = PlaySnd
triggerall = var(4) = 0
triggerall = command != "holddown"
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; C - Down
[State -1, C]
type = ChangeState
value = 219
type = PlaySnd
triggerall = var(4) = 0
triggerall = command = "holddown"
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Z
[State -1, Z]
type = ChangeState
value = 305
type = PlaySnd
triggerall = var(4) = 0
triggerall = command != "holddown"
triggerall = command = "z"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Z - Down
[State -1, Z]
type = ChangeState
value = 301
type = PlaySnd
triggerall = var(4) = 0
triggerall = command = "holddown"
triggerall = command = "z"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Y
[State -1, Y]
type = ChangeState
value = 285
type = PlaySnd
triggerall = var(4) = 0
triggerall = command != "holddown"
triggerall = command = "y"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Y - Down
[State -1, A]
type = ChangeState
value = 222
type = PlaySnd
triggerall = var(4) = 0
triggerall = command = "holddown"
triggerall = command = "y"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Aire - A
[State -1, Aire]
type = ChangeState
value = 600
triggerall = var(4) = 0
triggerall = command = "a"
Triggerall = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Aire - B
[State -1, Aire - B]
type = ChangeState
value = 610
triggerall = var(4) = 0
triggerall = command = "b"
Triggerall = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Aire - C
[State -1, Aire - C]
type = ChangeState
value = 1230
triggerall = var(4) = 0
triggerall = command = "c"
Triggerall = statetype = A
trigger1 = ctrl