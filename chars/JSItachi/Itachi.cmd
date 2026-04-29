; The CMD file.
;
; Two parts: 1. Command definition and  2. State entry
; (state entry is after the commands def section)
;
; 1. Command definition
; ---------------------
; Note: The commands are CASE-SENSITIVE, and so are the command names.
; The eight directions are:
;   B, DB, D, DF, F, UF, U, UB     (all CAPS)
;   corresponding to back, down-back, down, downforward, etc.
; The six buttons are:
;   a, b, c, x, y, z               (all lower case)
;   In default key config, abc are are the bottom, and xyz are on the
;   top row. For 2 button characters, we recommend you use a and b.
;   For 6 button characters, use abc for kicks and xyz for punches.
;
; Each [Command] section defines a command that you can use for
; state entry, as well as in the CNS file.
; The command section should look like:
;
;   [Command]
;   name = some_name
;   command = the_command
;   time = time (optional -- defaults to 15 if omitted)
;
; - some_name
;   A name to give that command. You'll use this name to refer to
;   that command in the state entry, as well as the CNS. It is case-
;   sensitive (QCB_a is NOT the same as Qcb_a or QCB_A).
;
; - command
;   list of buttons or directions, separated by commas.
;   Directions and buttons can be preceded by special characters:
;   slash (/) - means the key must be held down
;          egs. command = /D       ;hold the down direction
;               command = /DB, a   ;hold down-back while you press a
;   tilde (~) - to detect key releases
;          egs. command = ~a       ;release the a button
;               command = ~D, F, a ;release down, press fwd, then a
;          If you want to detect "charge moves", you can specify
;          the time the key must be held down for (in game-ticks)
;          egs. command = ~30a     ;hold a for at least 30 ticks, then release
;   dollar ($) - Direction-only: detect as 4-way
;          egs. command = $D       ;will detect if D, DB or DF is held
;               command = $B       ;will detect if B, DB or UB is held
;   plus (+) - Buttons only: simultaneous press
;          egs. command = a+b      ;press a and b at the same time
;               command = x+y+z    ;press x, y and z at the same time
;   You can combine them:
;     eg. command = ~30$D, a+b     ;hold D, DB or DF for 30 ticks, release,
;                                  ;then press a and b together
;   It's recommended that for most "motion" commads, eg. quarter-circle-fwd,
;   you start off with a "release direction". This matches the way most
;   popular fighting games implement their command detection.
;
; - time (optional)
;   Time allowed to do the command, given in game-ticks. Defaults to 15
;   if omitted
;
; If you have two or more commands with the same name, all of them will
; work. You can use it to allow multiple motions for the same move.
;
; Some common commands examples are given below.
;
; [Command] ;Quarter circle forward + x
; name = "QCF_x"
; command = ~D, DF, F, x
;
; [Command] ;Half circle back + a
; name = "HCB_a"
; command = ~F, DF, D, DB, B, a
;
; [Command] ;Two quarter circles forward + y
; name = "2QCF_y"
; command = ~D, DF, F, D, DF, F, y
;
; [Command] ;Tap b rapidly
; name = "5b"
; command = b, b, b, b, b
; time = 30
;
; [Command] ;Charge back, then forward + z
; name = "charge_B_F_z"
; command = ~60$B, F, z
; time = 10
; 
; [Command] ;Charge down, then up + c
; name = "charge_D_U_c"
; command = ~60$D, U, c
; time = 10
; 

;-| Super Motions |--------------------------------------------------------
;The following two have the same name, but different motion.
;Either one will be detected by a "command = TripleKFPalm" trigger.
;Time is set to 20 (instead of default of 15) to make the move
;easier to do.
;
[Command]
name = "TripleKFPalm"
command = ~D, DF, F, D, DF, F, x
time = 20

[Command] 
name = "TripleKFPalm"   ;Same name as above
command = ~D, DF, F, D, DF, F, y
time = 20

;-| Special Motions |------------------------------------------------------
[Command]
name = "QCF_x"
command = ~D, DF, F, x

[Command]
name = "QCF_y"
command = ~D, DF, F, y

[Command]
name = "QCF_xy"
command = ~D, DF, F, x+y

[Command]
name = "QCB_a"
command = ~D, DF, F, a

[Command]
name = "QCB_b"
command = ~D, DF, F, b

[Command]
name = "FF_ab"
command = F, F, a+b

[Command]
name = "FF_a"
command = F, F, a

[Command]
name = "FF_b"
command = F, F, b

;-| Double Tap |-----------------------------------------------------------
[Command]
name = "FF"     ;Required (do not remove)
command = /F, z
time = 10

[Command]
name = "BB"     ;Required (do not remove)
command = /B, z
time = 10

[Command]
name = "FF"     ;Required (do not remove)
command = /F, c
time = 10

[Command]
name = "BB"     ;Required (do not remove)
command = /B, c
time = 10

[Command]
name = "updash"     ;Required (do not remove)
command = /U, b
time = 10

;-| 2/3 Button Combination |-----------------------------------------------
[Command]
name = "recovery";Required (do not remove)
command = x+y
time = 1

;-| Dir + Button |---------------------------------------------------------
[Command]
name = "down_a"
command = /$D,a
time = 1

[Command]
name = "down_b"
command = /$D,b
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
name = "yy"
command = y, y
time = 1

[Command]
name = "aa"
command = a, a
time = 10

[Command]
name = "z"
command = z
time = 1

[Command]
name = "rlsd"
command = ~D
time = 1

[Command]
name = "rlsu"
command = ~U
time = 1

[Command]
name = "guard"
command = /c
time = 1

[Command]
name = "guard"
command = /z
time = 1

[Command]
name = "start"
command = s
time = 1

;-| Hold Dir |--------------------------------------------------------------
[Command]
name = "holdfwd";Required (do not remove)
command = /$F
time = 1

[Command]
name = "holdback";Required (do not remove)
command = /$B
time = 1

[Command]
name = "holdup" ;Required (do not remove)
command = /$U
time = 1

[Command]
name = "holddown";Required (do not remove)
command = /$D
time = 1

[Command]
name = "charge";Required (do not remove)
command = /$a
time = 1

;---------------------------------------------------------------------------
; 2. State entry
; --------------
; This is where you define what commands bring you to what states.
;
; Each state entry block looks like:
;   [State -1, Label]           ;Change Label to any name you want to use to
;                               ;identify the state with.
;   type = ChangeState          ;Don't change this
;   value = new_state_number
;   trigger1 = command = command_name
;   . . .  (any additional triggers)
;
; - new_state_number is the number of the state to change to
; - command_name is the name of the command (from the section above)
; - Useful triggers to know:
;   - statetype
;       S, C or A : current state-type of player (stand, crouch, air)
;   - ctrl
;       0 or 1 : 1 if player has control. Unless "interrupting" another
;                move, you'll want ctrl = 1
;   - stateno
;       number of state player is in - useful for "move interrupts"
;   - movecontact
;       0 or 1 : 1 if player's last attack touched the opponent
;                useful for "move interrupts"
;
; Note: The order of state entry is important.
;   State entry with a certain command must come before another state
;   entry with a command that is the subset of the first.  
;   For example, command "fwd_a" must be listed before "a", and
;   "fwd_ab" should come before both of the others.
;
; For reference on triggers, see CNS documentation.
;
; Just for your information (skip if you're not interested):
; This part is an extension of the CNS. "State -1" is a special state
; that is executed once every game-tick, regardless of what other state
; you are in.


; Don't remove the following line. It's required by the CMD standard.
[Statedef -1]

;===========================================================================
;Dash Attack
[State -1, Dash Attack]
type = ChangeState
value = 20000
triggerall = statetype != C
trigger1 = command = "aa"
trigger1 = ctrl
;---------------------------------------------------------------------------
;Crows Up
[State -1, Crows Up]
type = ChangeState
value = 197
triggerall = statetype = S
triggerall = command = "x"&&command!="holdfwd"
triggerall = command != "holddown"&&command="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 199
trigger3 = stateno = 220
;Air Kick Up
[State -1, Air Kick Up]
type = ChangeState
value = 198
triggerall = statetype = A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command != "holddown"&&command="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 197
trigger3 = stateno = 1970
trigger4 = stateno = 1971
;Clones Up
[State -1, Clones Up]
type = ChangeState
value = 327
triggerall = power >499
triggerall = statetype = S
triggerall = command = "b"&&command!="holdfwd"
triggerall = command != "holddown"&&command="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 221
;Kunai Throw DIAG-UP
[State -1, Kunai Throw DIAG-UP]
type = ChangeState
value = 2242
triggerall = command = "y"&&command="holdup"
triggerall=command!="holdfwd"&&command!="holdback"&&command!="holddown"
triggerall = power >50
triggerall = ctrl
trigger1 = statetype != A
;Anti-Jump Override IDLE
[State -1, AntiJump]
type = ChangeState
value = 0
trigger1=command="holdup"&&command!="holdfwd"&&command!="holdback"
trigger1 = statetype = S
trigger1 = ctrl
;Anti-Jump Override WALK
[State -1, AntiJumpW]
type = ChangeState
value = 20
trigger1=command="holdup"
trigger1 = statetype = S
trigger1 = ctrl
;Jump (CROSS)
[State -1, Jump]
type = ChangeState
value = 40
triggerall = command = "a"
trigger1 = statetype !=A
trigger1 = ctrl
trigger2 = stateno = 221 && movecontact
;---------------------------------------------------------------------------
;Chakra Charge
[State -1, Chakra Charge]
type = ChangeState
value = 194
trigger1 = power < 5000
trigger1 = command = "charge"
trigger1 = statetype = C
trigger1 = ctrl
;Dash FWD
[State -1, Dash FWD]
type = ChangeState
value = 100
trigger1 = command = "FF"
trigger1 = statetype!= A
trigger1 = ctrl
;Dash Back
[State -1, Dash BWD]
type = ChangeState
value = 105
trigger1 = command = "BB"
trigger1 = statetype!= A
trigger1 = ctrl
;Guard
[State -1,Guard]
type = ChangeState
value = 120
trigger1 = command = "guard"&&command!="holdfwd"&&command!="holdback"
trigger1 = statetype = S
trigger1 = ctrl
;Dash FWD AIR
[State -1, Dash FWD AIR]
type = ChangeState
value = 101
trigger1 = command = "FF"
trigger1 = statetype = A
trigger1 =  ctrl
;Dash BWD AIR
[State -1, Dash BWD AIR]
type = ChangeState
value = 106
trigger1 = command = "BB"
trigger1 = statetype = A
trigger1 = ctrl
;Guard
[State -1,Guard AIR]
type = ChangeState
value = 132
trigger1 = command = "guard"&&command!="holdfwd"&&command!="holdback"
trigger1 = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Combo X 1]
type = ChangeState
value = 199
triggerall = statetype != A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 238
trigger3 = stateno = 580
[State -1, Combo X 2]
type = ChangeState
value = 211
triggerall = statetype != A
triggerall = command = "x" &&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 199
trigger3 = stateno = 201
[State -1, Combo X 3]
type = ChangeState
value = 210
triggerall = statetype != A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 199
trigger3 = stateno = 211
trigger4 = stateno = 238
;---------------------------------------------------------------------------
[State -1, Combo FX 1]
type = ChangeState
value = 201
triggerall = statetype != A
triggerall = command = "x"&&command="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 100
trigger3 = stateno = 105
trigger4 = stateno = 211
trigger5 = stateno = 199
[State -1, Combo FX 2]
type = ChangeState
value = 205
triggerall = statetype != A
triggerall = command = "x"&&command="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 201
trigger3 = stateno = 220
[State -1, Combo FX 3]
type = ChangeState
value = 204
triggerall = statetype != A
triggerall = command = "x"&&command="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 205 && time > 9
trigger3 = stateno = 210
;---------------------------------------------------------------------------
[State -1, Combo DX 1]
type = ChangeState
value = 220
triggerall = statetype != A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command = "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 199
trigger3 = stateno = 211
trigger4 = stateno = 580
[State -1, Combo DX 2]
type = ChangeState
value = 221
triggerall = statetype != A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command = "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 220
[State -1, Combo DX 3]
type = ChangeState
value = 222
triggerall = statetype != A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command = "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 221
;---------------------------------------------------------------------------
;Kunai Throw FWD
[State -1, Kunai Throw FWD]
type = ChangeState
value = 2240
triggerall = command = "y"&&command!="holdback"
triggerall=command!="holddown"&&command!="holdup"
triggerall = power >24
triggerall = ctrl
trigger1 = statetype = S

;Kunai Throw FWD AIR
[State -1, Kunai Throw FWD AIR]
type = ChangeState
value = 2230
triggerall = command = "y"
triggerall=command!="holddown"&&command!="holdup"
triggerall = power >24
triggerall = ctrl
trigger1 = statetype = A

;Kunai Throw DIAG-DOWN AIR
[State -1, Kunai Throw FWD AIR]
type = ChangeState
value = 2232
triggerall = command = "y"
triggerall=command="holddown"&&command!="holdup"
triggerall = power >24
triggerall = ctrl
trigger1 = statetype = A

;Tag Throw FWD
[State -1, Tag Throw FWD]
type = ChangeState
value = 2220
triggerall = command = "y"&&command="holdback"
triggerall=command!="holddown"&&command!="holdup"&&command!="holdfwd"
triggerall = power >49
triggerall = ctrl
trigger1 = statetype = S

;Tag Throw DOWN
[State -1, Tag Throw DOWN]
type = ChangeState
value = 2225
triggerall = command = "y"&&command="holddown"
triggerall=command!="holdback"&&command!="holdup"&&command!="holdfwd"
triggerall = power >49
triggerall = ctrl
trigger1 = statetype = C
;---------------------------------------------------------------------------
;Genjutsu 1
[State -1, Genjutsu 1]
type = ChangeState
value = 206
triggerall = command = "x" && command = "holdback"
triggerall = command != "holddown"&&command!="holdup"&command!="holdfwd"
trigger1 = statetype !=A
trigger1 = ctrl
trigger2 = stateno = 199
trigger3 = stateno = 211
trigger4 = stateno = 201
trigger5 = stateno = 220
;---------------------------------------------------------------------------
[State -1, Air Combo 1]
type = ChangeState
value = 1970
triggerall = statetype = A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 197
[State -1, Air Combo 2]
type = ChangeState
value = 1971
triggerall = statetype = A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 1970
[State -1, Air Combo 3]
type = ChangeState
value = 1972
triggerall = statetype = A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 1971
;-----------------------------------------------------------------------------
[State -1, Air Smash]
type = ChangeState
value = 231
triggerall = statetype = A
triggerall = command = "x"&&command!="holdfwd"
triggerall = command = "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 1970
trigger3 = stateno = 1971
trigger4 = stateno = 198
;-----------------------------------------------------------------------------
[State -1, Genjutsu 2]
type = ChangeState
value = 580
triggerall = power >249
triggerall = statetype != A
triggerall = command = "b"&&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 199
trigger3 = stateno = 211
trigger4 = stateno = 201
trigger5 = stateno = 220
;-----------------------------------------------------------------------------
[State -1, Clone bomb]
type = ChangeState
value = 224
triggerall = power >499
triggerall = statetype != A
triggerall = command = "b"&&command="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 238
;-----------------------------------------------------------------------------
[State -1, Gokakyuu]
type = ChangeState
value = 225
triggerall = power >249
triggerall = statetype != A
triggerall = command = "b"&&command!="holdfwd"
triggerall = command = "holddown"&&command!="holdup"&command!="holdback"
trigger1 = ctrl
trigger2 = stateno = 238
;-----------------------------------------------------------------------------
[State -1, Hosenka]
type = ChangeState
value = 2250
triggerall = power > 499
triggerall = statetype != A
triggerall = command = "b"&&command!="holdfwd"
triggerall = command != "holddown"&&command!="holdup"&command="holdback"
trigger1 = ctrl
;-----------------------------------------------------------------------------
[State -1, Clone AIR]
type = ChangeState
value = 3010
triggerall = statetype = A
triggerall = command = "b"
trigger1 = ctrl
