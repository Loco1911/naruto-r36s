;-| Button Remapping |-----------------------------------------------------
; This section lets you remap the player's buttons (to easily change the
; button configuration). The format is:
;   old_button = new_button
; If new_button is left blank, the button cannot be pressed.
[Remap]
x = x
y = y
z = z
a = a
b = b
c = c
s = s

;-| Default Values |-------------------------------------------------------
[command]
name = "KB"
command = D,DF,F,a
time = 15
COMMAND.TIME = 30

[Defaults]

[Command]
name = "AI1"
command = D,D,D,F,F,F,a+b+c+x+y+z
time = 1

[Command]
name = "AI2"
command = D,D,D,F,F,U,a+b+c+x+y+z
time = 1

[Command]
name = "AI3"
command = D,D,D,F,F,UF,a+b+c+x+y+z
time = 1

[Command]
name = "AI4"
command = D,D,D,F,F,D,a+b+c+x+y+z
time = 1

[Command]
name = "AI5"
command = D,D,D,F,F,DF,a+b+c+x+y+z
time = 1

[Command]
name = "AI6"
command = D,D,D,F,F,B,a+b+c+x+y+z
time = 1

[Command]
name = "AI7"
command = D,D,D,F,F,DB,a+b+c+x+y+z
time = 1

[Command]
name = "AI8"
command = D,D,D,F,F,UB,a+b+c+x+y+z
time = 1

[Command]
name = "AI9"
command = D,D,D,F,U,F,a+b+c+x+y+z
time = 1

[Command]
name = "AI10"
command = D,D,D,F,UF,F,a+b+c+x+y+z
time = 1

[command]
name = "SSNJ"
command = a
time = 15

[command]
name = "SeneiTaJashu"
command = DF, F, b
time = 15
command.time = 30

[command]
name = "Kyodaija"
command = a+x
time = 15
command.time = 30
; Default value for the "buffer.time" parameter of a Command. Minimum 1,
; maximum 30.
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

[Command]
name = "SojaSosai"
command = c+z
time = 15

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
;-------------------------------------------------------------------------------
[Statedef -1]

[State -1]
type = VarSet
triggerall = Roundstate = 2
triggerall = Fvar(0) = 0
triggerall = FVar(1) = 0
triggerall = authorname = "Tendou_no_Mazo"
trigger1 = AILevel
trigger1 = NumHelper(2000) = 0
Fv = 0
value = 1

[State -1]
type = VarSet
triggerall = Roundstate = 2
trigger1 = !AILevel
trigger2 = NumHelper(2000) > 0
trigger2 = Fvar(0) > 0
Fv = 0
value = 0

[State -1]
type = ChangeState
value = 193
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = Roundstate = 2
triggerall = Fvar(0) = 1
triggerall = statetype != A
Triggerall = p2bodydist X > 150
triggerall = random < 100
trigger1 = numexplod(3006) < 1
trigger1 = ctrl

[State -1]
type = ChangeState
triggerall = Roundstate = 2
triggerall = Fvar(0) = 1
triggerall = statetype != A
Triggerall = p2life > 0
Triggerall = p2bodydist X < 50
triggerall = enemy, movetype = A
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
trigger1 = ctrl
value = 184

[State -1]
type = ChangeState
triggerall = Roundstate = 2
triggerall = Fvar(0) = 1
triggerall = statetype != A
triggerall = Pos y = 0
Triggerall = p2bodydist X > 50
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
Triggerall = random < 300
trigger1 = power < 4000
trigger1 = Var(1) = 0
trigger1 = ctrl
trigger1 = !NumPartner
trigger2 = power < 4000
trigger2 = Var(1) = 0
trigger2 = ctrl
trigger2 = NumPartner
trigger2 = (ID) < (Partner,ID)
trigger3 = power < powermax
trigger3 = Var(1) = 0
trigger3 = ctrl
trigger3 = NumPartner
trigger3 = (ID) > (Partner,ID)
trigger4 = power < powermax
trigger4 = Var(1) > 0
trigger4 = ctrl
value =  Cond(random < 300,218,200)

[State -1]
type = ChangeState
value = 116
triggerall = fvar(0) = 1
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = NumExplod(3021) = 0
triggerall = var(27) = 3
triggerall = power >= (500)*(Var(42))
Triggerall = Stateno != [116,190]
Triggerall = Stateno != [5030,5899]
trigger1 = movetype = H

[State -1]
type = Changestate
value = 201
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = NumExplod(3021) = 0
triggerall = Roundstate = 2
triggerall = Fvar(0) = 1
triggerall = var(27) = 5
triggerall = power >= (100)*(Var(42))
triggerall = time >= ((15)-(AILevel))
triggerall = alive
trigger1 = movetype = H

[State -1]
type = ChangeState
value = 186
triggerall = Fvar(0) = 1
Triggerall = NumExplod(3009) > 0
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = statetype = S
trigger1 = ctrl

[State -1]
type = ChangeState
triggerall = Roundstate = 2
triggerall = FVar(0) = 1
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = StateType != A
triggerall = Pos Y = 0
triggerall = MoveType != H
triggerall = P2bodydist X <= 40
trigger1 = NumExplod(3017) = 0
trigger1 = ctrl
trigger2 = NumExplod(3017) > 0
trigger2 = time > 10
trigger2 = ctrl
trigger3 = NumExplod(3017) = 0
trigger3 = Stateno = 20
trigger3 = ctrl
value = Cond(Random > 90,185,105)

[State -1]
type = ChangeState
triggerall = Roundstate = 2
triggerall = fvar(0) = 1
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = Pos y = 0
triggerall = StateType != A
triggerall = ctrl = 1
trigger1 = random <= 500
trigger1 = P2bodydist X >= 50
trigger1 = time > ((10)-(AILevel))
trigger2 = enemy, numhelper(11) > 0
trigger2 = time > 3
value = 210

[State -1]
type = ChangeState
Triggerall = NumExplod(3009) = 0
triggerall = Roundstate = 2
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = Fvar(0) = 1
triggerall = StateType != A
triggerall = Pos y = 0
triggerall = Movetype != H
triggerall = power > ((1000)*(Var(42)))
triggerall = P2bodydist X > 100
triggerall = random <=300
trigger1 = ctrl
value = 187

[State -1]
type = ChangeState
value = 270
Triggerall = NumExplod(3009) = 0
triggerall = Roundstate = 2
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = NumExplod(3010) = 0
triggerall = Fvar(0) = 1
triggerall = StateType != A
triggerall = Pos Y = 0
triggerall = power > ((500)*(Var(42)))
triggerall = Time > (10-AILEVEL)
triggerall = numhelper(271) = 0
triggerall = numexplod(271) = 0
triggerall = Stateno != 270
triggerall = Stateno != 264
triggerall = Stateno != 228
triggerall = Stateno != 231
triggerall = Stateno != 232
trigger1 = random < 50

[State -1]
type = ChangeState
value = 231
Triggerall = NumExplod(3009) = 0
triggerall = Roundstate = 2
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = NumExplod(3010) = 0
triggerall = NumExplod(232) = 0
triggerall = Fvar(0) = 1
triggerall = StateType != A
triggerall = Pos Y = 0
triggerall = Stateno != 231
triggerall = Stateno != 232
triggerall = Life < Lifemax/3
trigger1 = gametime%10 = 0
trigger1 = random < 8

[State -1]
type = ChangeState
value = 213
triggerall = Fvar(0) = 1
triggerall = Var(1) = 0
triggerall = Roundstate = 2
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = command = "hold_z"
triggerall = command = "holddown"
triggerall = power >= ((1000)*(Var(42)))
triggerall = Life > Lifemax/2
triggerall = StateType != A
triggerall = Pos Y = 0
triggerall = Stateno != 213
trigger1 = gametime%10 = 0
trigger1 = random > 900
;-------------------------------------------------------------------------------
[state -1
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 194
triggerall = fvar(0) = 0
triggerall = NumExplod(3013) = 0
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = command = "s"
triggerall = command != "holddown"
trigger1 = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 195
triggerall = fvar(0) = 0
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = numexplod(3006) = 0
triggerall = command = "s"
triggerall = command = "holddown"
trigger1 = statetype = C
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 100
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
trigger1 = command = "FF"
trigger1 = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 105
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
trigger1 = command = "BB"
trigger1 = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 53
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = Stateno != 53
triggerall = Stateno != 54
triggerall = FrontEdgeBodydist > 10
trigger1 = (command = "FF") && (Statetype = A)
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 55
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = Stateno != 55
triggerall = BackEdgeBodydist > 10
trigger1 = (command = "BB") && (Statetype = A)
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 116
triggerall = NumExplod(3016) = 0
triggerall = power >= (500)*(Var(42))
triggerall = Var(42) = 1
triggerall = command = "c"||command = "z"
triggerall = var(27) = [2,4]
Triggerall = Stateno != [116,190]
Triggerall = Stateno != [5030,5899]
triggerall = NumExplod(3020) = 0
triggerall = NumExplod(3021) = 0
trigger1 = movetype = H
;----------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 186
triggerall = fvar(0) = 0
triggerall = NumExplod(3009) > 0
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = command = "y"
triggerall = command != "holddown"
triggerall = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 200
triggerall = Fvar(0) = 0
triggerall = NumExplod(3007) = 0
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = command = "z"
triggerall = command != "holddown"
triggerall = command != "SojaSosai"
triggerall = statetype = S
triggerall = Stateno != [20,100]
trigger1 = power < 4000
trigger1 = Var(1) = 0
trigger1 = ctrl
trigger1 = !NumPartner
trigger2 = power < 4000
trigger2 = Var(1) = 0
trigger2 = ctrl
trigger2 = NumPartner
trigger2 = (ID) < (Partner,ID)
trigger3 = power < powermax
trigger3 = Var(1) = 0
trigger3 = ctrl
trigger3 = NumPartner
trigger3 = (ID) > (Partner,ID)
trigger4 = power < powermax
trigger4 = Var(1) > 0
trigger4 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 201
triggerall = fvar(0) = 0
triggerall = NumExplod(3016) = 0
triggerall = power >= ((500)*(Var(42)))
triggerall = command = "a" ||command = "b" ||command = "x" || command = "y"
triggerall = NumExplod(3021) = 0
triggerall = var(27) = 5
triggerall = NumExplod(3020) = 0
trigger1 = movetype = H
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 202
triggerall = Fvar(0) = 0
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = Stateno != 100
triggerall = Stateno != 20
triggerall = command = "a"
triggerall = command != "holddown"
triggerall = command != "Kyodaija"
triggerall = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 245
triggerall = Fvar(0) = 0
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = Stateno != 100
triggerall = Stateno != 20
triggerall = command = "x"
triggerall = command != "holddown"
triggerall = command != "Kyodaija"
trigger1 = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 261
triggerall = NumExplod(3016) = 0
triggerall = NumExplod(3020) = 0
triggerall = command = "a" || command = "x"
triggerall = statetype = A
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 223
triggerall = command = "b"
triggerall = Power > Cond(Var(1)=0,300,500)
triggerall = statetype = A
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 234
triggerall = command = "z"||command = "c"
triggerall = command != "holddown"
triggerall = statetype = A
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 210
triggerall = command = "c"
triggerall = command != "SojaSosai"
triggerall = command != "holddown"
triggerall = command != "holdfwd"
triggerall = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = Cond(Var(1)=0,213,214)
triggerall = Fvar(0) = 0
triggerall = command = "hold_z"
triggerall = command = "holddown"
triggerall = power >= Cond(Var(1)=0,((1000)*(Var(42))),0)
trigger1 = statetype = C
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
triggerall = var(1) = 1
Triggerall = stateno != 214
triggerall = statetype != A
triggerall = Pos Y = 0
trigger1 = power < 100
value = 214
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 218
triggerall = Fvar(0) = 0
Triggerall = NumExplod(3209) = 0
triggerall = power > 300
triggerall = command = "y"
triggerall = command != "holddown"
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 216
triggerall = Fvar(0) = 0
triggerall = power > 300
Triggerall = NumExplod(3009) = 0
triggerall = command = "y"
triggerall = command = "holddown"
trigger1 = statetype = C
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 220
triggerall = NumHelper(10000) < 1
triggerall = NumExplod(3010) = 0
triggerall = Fvar(0) = 0
triggerall = var(42) > 0
triggerall = command = "b"
triggerall = command = "holddown"
triggerall = power >= (1500)*(Var(42))
triggerall = enemy, var(34) != 1
triggerall = statetype = C
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 219
triggerall = Fvar(0) = 0
triggerall = command = "a"
triggerall = command = "holddown"
triggerall = statetype = C
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 215
triggerall = Fvar(0) = 0
triggerall = command = "x"
triggerall = command = "holddown"
triggerall = statetype = C
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = 225
triggerall = Fvar(0) = 0
triggerall = command = "z"
triggerall = power >= 1000
triggerall = numhelper(20000) < 2
triggerall = numexplod(3010) = 0
triggerall = statetype = S
trigger1 = stateno = 20
trigger1 = ctrl
trigger2 = stateno = 100
trigger2 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = Cond((numexplod(3010) = 0),270,241)
triggerall = Fvar(0) = 0
triggerall = command = "c"
triggerall = command = "holddown"
triggerall = power >= ((700)*(Var(42)))
triggerall = numhelper(271) = 0
trigger1 = statetype = C
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = Cond((numexplod(3010)=0),273,241)
triggerall = Fvar(0) = 0
triggerall = command = "Kyodaija"
triggerall = command != "holddown"
triggerall = power >= 2000
triggerall = numexplod(3250) = 0
trigger1 = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = Cond((Var(1)=0),228,264)
triggerall = Fvar(0) = 0
triggerall = command = "b"
triggerall = command != "holddown"
triggerall = power >= Cond(Var(1)=0,1000,3000)
trigger1 = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[State -1]
type = ChangeState
value = Cond((numexplod(3010) = 0),231,208)
triggerall = Fvar(0) = 0
triggerall = Power > Powermax/2
triggerall = command = "SojaSosai"
triggerall = command != "holddown"
triggerall = statetype = S
trigger1 = ctrl
;-------------------------------------------------------------------------------
[state -1

[State -1]
type = changestate
value = 45
triggerall = alive
triggerall = Pos Y > 0
triggerall= stateno = 0
trigger1 = ctrl = 1

[State -1]
type = NotHitBy
triggerall = stateno = 0
trigger1 = time = 1
value = SCA,NA,SA,HA,NP,SP,HP,NT,ST,HT
time = 1

[State -1]
type = NotHitBy
triggerall = stateno = 45
Triggerall = prevstateno = 45
trigger1 = time = 1
value = SCA,NA,SA,HA,NP,SP,HP,NT,ST,HT
time = 1

[State -1]
type = VarRandom
triggerall = Fvar(0) = 0
trigger1 = time%5 = 0
v = 27
range = 0,10
ignorehitpause = 1

[State -1]
type = VarRandom
triggerall = Fvar(0) = 1
trigger1 = time%5 = 0
v = 27
range = 0,15
ignorehitpause = 1

[State -1]
type = Helper
triggerall= !IsHelper
triggerall = numhelper(5658) = 0
triggerall = Var(11) = 100
trigger1 = gametime%5 = 0
helpertype = normal
name = "Chakra no Tate"
ID = 5658
stateno = 5658
pos = 0,0
postype = p1
facing = 1
keyctrl = 0
ownpal = 1
supermovetime = 90000
pausemovetime = 90000

[State -1]
type = Helper
triggerall= !IsHelper
triggerall = roundstate = 2
triggerall = numhelper(5660) = 0
triggerall = Var(1) > 0
trigger1 = gametime%5 = 0
helpertype = normal
name = "CS1"
ID = 5660
stateno = 5660
pos = 0,0
postype = p1
facing = 1
keyctrl = 0
ownpal = 1
supermovetime = 90000
pausemovetime = 90000
