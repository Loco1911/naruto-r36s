[Remap]
x = x
y = y
z = z
a = a
b = b
c = c
s = s


;-| Super Motions |--------------------------------------------------------

;-| Special Motions |------------------------------------------------------

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
name = "Super Jump"
command = ~D,U
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
name = "a+x"
command = a+x
time = 20

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

; Don't remove the following line. It's required by the CMD standard.
[Statedef -1]
;---------------------------------------------------------------------------
; Run Fwd
[State -1, Run Fwd]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 70
value = 60
trigger1 = command = "FF"
trigger1 = statetype != C
trigger1 = ctrl

;---------------------------------------------------------------------------
; Run Back
[State -1, Run Back]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 70
value = 70
trigger1 = command = "BB"
trigger1 = statetype != C
trigger1 = ctrl

;---------------------------------------------------------------------------
; Super Jump
[State -1, Super Jump]
type = ChangeState
triggerall = !NumPartner || NumPartner && (sysvar(4) != [8,9]) && (sysvar(4) != 12) && (StateNo != [1251109,1251114])
value = 80
trigger1 = command = "Super Jump"
trigger1 = statetype = S
trigger1 = ctrl

;---------------------------------------------------------------------------
;Specials
;---------------------------------------------------------------------------
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 1400
triggerall = power >= 1000
triggerall = statetype != A
trigger1 = command = "SPECIAL 1"
trigger1 = ctrl
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 1100
triggerall = power >= 1000
triggerall = statetype != A
trigger1 = command = "SPECIAL 2"
trigger1 = ctrl
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 1200
triggerall = power >= 1000
triggerall = statetype != A
trigger1 = command = "SPECIAL 3"
trigger1 = ctrl
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 1000
triggerall = power >= 1000
triggerall = statetype != A
trigger1 = command = "SPECIAL 4"
trigger1 = ctrl
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 1300
triggerall = power >= 1000
triggerall = statetype != A
trigger1 = command = "SPECIAL 5"
trigger1 = ctrl
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
triggerall = !NumPartner || NumPartner && (sysvar(4) != [8,9]) && (sysvar(4) != 12) && (StateNo != [1251109,1251114])
Triggerall = var(5) = 0
Triggerall = numhelper(1550) = 0
Triggerall = numhelper(1590) = 0
Triggerall = power >= 1000
value = 1500
triggerall = command = "SPECIAL 6"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 3000
triggerall = power >= 2000
trigger1 = command = "holddown"
trigger1 = command = "a"
trigger1 = ctrl
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 3100
triggerall = power >= 2500
trigger1 = command = "holddown"
trigger1 = command = "b"
trigger1 = ctrl
;------------------------------------------------------------------------------------
[State -1, Ultimate]
type = ChangeState
value = 3200
triggerall = power >= 3000
trigger1 = command = "holddown"
trigger1 = command = "c"
trigger1 = ctrl
;---------------------------------------------------------------------------
;Combos
;---------------------------------------------------------------------------
[State -1, Combo 1]
type=changestate
value=200
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "a"
triggerall = ctrl = 1
triggerall = Statetype !=A 
;------------------------------------------------------------------------------------
[State -1, Combo 1 - 1]
type=changestate
value=210
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "a"
triggerall = (stateno=200) && (movecontact>1)
triggerall = Statetype !=A
;------------------------------------------------------------------------------------
[State -1, Combo 1 - 2]
type=changestate
value=220
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "a"
triggerall = (stateno=210) && (movecontact>1)
triggerall = Statetype !=A
;------------------------------------------------------------------------------------
[State -1, Combo 1 - 3]
type=changestate
value=230
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "a"
triggerall = (stateno=220) && (movecontact>1)
triggerall = Statetype !=A
;====================================================================================================
[State -1, Combo 2 - 1]
type=changestate
value=300
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "b"
triggerall = ctrl = 1
triggerall = Statetype !=A 
;------------------------------------------------------------------------------------
[State -1, Combo 2 - 2]
type=changestate
value=310
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "b"
triggerall = (stateno=300) && (movecontact>1)
triggerall = Statetype !=A
;------------------------------------------------------------------------------------
[State -1, Combo 2 - 3]
type=changestate
value=320
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "b"
triggerall = (stateno=310) && (movecontact>1)
triggerall = Statetype !=A

;------------------------------------------------------------------------------------
[State -1, Combo 3 - 1]
type=changestate
value=400
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "c"
triggerall = ctrl = 1
triggerall = Statetype !=A 

;------------------------------------------------------------------------------------
[State -1, Combo 3 - 2]
type=changestate
value=410
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "c"
triggerall = (stateno=400) && (movecontact>1)
triggerall = Statetype !=A

;------------------------------------------------------------------------------------
[State -1, Combo 3 - 3]
type=changestate
value=420
triggerall = var(7) = 0
triggerall = var(10) = 0
trigger1 = command !="holddown"
trigger1 = command = "c"
triggerall = (stateno=410) && (movecontact>1)
triggerall = Statetype !=A
[State -1, Combo Aire]
type = ChangeState
value = 600
triggerall = command = "a"||command = "b"||command = "c"
trigger1 = statetype = A
trigger1 = ctrl
[State -1, Power Charge]
type = ChangeState
triggerall = !NumPartner || NumPartner && (sysvar(4) != [8,9]) && (sysvar(4) != 12) && (StateNo != [1251109,1251114])
Triggerall = power < 3000
value = 500
triggerall = command = "s"
trigger1 = statetype != A
trigger1 = ctrl
;====================================================================================================
;====================================================================================================
;====================================================================================================
;====================================================================================================
;=================================================AI=================================================
;====================================================================================================
;====================================================================================================
;====================================================================================================
;====================================================================================================
[State -1, AI on]
type = VarSet
triggerAll = Var(10) < 1
triggerAll = RoundState = 2
trigger1 = AILevel > 0
v = 10
value = 1
Ignorehitpause = 1
;---------------------------------------------------------------------------
[State -1, AI OFF]
type=VarSet
trigger1 = var(10) > 0
trigger1 = RoundState != 2
trigger2 = AILevel = 0
v = 10
value = 0
Ignorehitpause = 1
;---------------------------------------------------------------------------
;ai j1
[State -1, ai j1]
type = ChangeState
value = 1000
triggerall = var(10) = 1
triggerall = var(11) = 0
triggerall = power >= 1000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 100
;---------------------------------------------------------------------------
;ai j2
[State -1, ai j2]
type = ChangeState
value = 1100
triggerall = var(10) = 1
triggerall = power >= 2000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) >= 75
;---------------------------------------------------------------------------
;ai j3
[State -1, ai j3]
type = ChangeState
value = 1200
triggerall = var(10) = 1
triggerall = power >= 3000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) >= 75
;---------------------------------------------------------------------------
;ai j4
[State -1, ai j4]
type = ChangeState
value = 1300
triggerall = var(10) = 1
triggerall = power >= 4000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) >= 200
;---------------------------------------------------------------------------
;ai j5
[State -1, ai j5]
type = ChangeState
value = 1400
triggerall = var(10) = 1
triggerall = power >= 5000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) >= 150
;---------------------------------------------------------------------------
;ai j6
[State -1, ai j6]
type = ChangeState
value = 1500
triggerall = var(10) = 1
triggerall = power >= 6000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) >= 3000
;---------------------------------------------------------------------------
;ai a
[State -1,ai combo1]
type = ChangeState
value = 200
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 80
;---------------------------------------------------------------------------
;ai a
[State -1,ai combo2]
type = ChangeState
value = 300
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 80
;---------------------------------------------------------------------------
;ai a
[State -1,ai combo2]
type = ChangeState
value = 500
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 80
;---------------------------------------------------------------------------
;ai Power up
[State -1, ai Power up]
type = ChangeState
value = 110
triggerall = var(10) = 1
triggerall = power < 6000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = random < 25
trigger1 = (p2dist x) > 80