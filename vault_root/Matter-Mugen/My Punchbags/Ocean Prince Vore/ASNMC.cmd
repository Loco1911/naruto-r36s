-| Super Motions |-------------------------------------------------------

;-| Special Motions |------------------------------------------------------
;-----------------

[Command]
name = "heart"
command = D,x

; QCF
[Command]
name = "QCF_a"
command = ~D,DF,F,a

[Command]
name = "QCF_b"
command = ~D,DF,F,b

[Command]
name = "QCF_c"
command = ~D,DF,F,c

[Command]
name = "QCF_x"
command = ~D,DF,F,x

[Command]
name = "QCF_y"
command = ~D,DF,F,y

[Command]
name = "QCF_z"
command = ~D,DF,F,z

;-----------------
; QCB
[Command]
name = "QCB_a"
command = ~D,DB,B,a

[Command]
name = "QCB_b"
command = ~D,DB,B,b

[Command]
name = "QCB_c"
command = ~D,DB,B,c

[Command]
name = "QCB_x"
command = ~D,DB,B,x

[Command]
name = "QCB_y"
command = ~D,DB,B,y

[Command]
name = "QCB_z"
command = ~D,DB,B,z

;-----------------
; Uppercut
[Command]
name = "uppercut_a"
command = ~F,D,DF,a

[Command]
name = "uppercut_b"
command = ~F,D,DF,b

[Command]
name = "uppercut_c"
command = ~F,D,DF,c

[Command]
name = "uppercut_x"
command = ~F,D,DF,x

[Command]
name = "uppercut_y"
command = ~F,D,DF,y

[Command]
name = "uppercut_z"
command = ~F,D,DF,z

;--------------------
;Charge_Down_up
[Command]
name = "chargedownup_a"
command = ~60$D,U,a
time= 10

[Command]
name = "chargedownup_b"
command = ~60$D,U,b
time= 10

[Command]
name = "chargedownup_c"
command = ~60$D,U,c
time= 10

[Command]
name = "chargedownup_x"
command = ~60$D,U,x
time= 10

[Command]
name = "chargedownup_y"
command = ~60$D,U,y
time= 10

[Command]
name = "chargedownup_z"
command = ~60$D,U,z
time= 10

;--------------------
;Charge_Back_fwd
[Command]
name = "chargebackfwd_a"
command = ~60$B,F,a
time= 10

[Command]
name = "chargebackfwd_b"
command = ~60$B,F,b
time= 10

[Command]
name = "chargedownup_c"
command = ~60$D,U,c
time= 10

[Command]
name = "chargedownup_x"
command = ~60$D,U,x
time= 10

[Command]
name = "chargedownup_y"
command = ~60$D,U,y
time= 10

[Command]
name = "chargedownup_z"
command = ~60$D,U,z
time= 10


;-| Double Tap |-----------------------------------------------------------
[Command]
name = "FF";Required (do not remove)
command = F,F
time= 10

[Command]
name = "BB";Required (do not remove)
command = B,B
time= 10

;-| 2/3 Button Combination |-----------------------------------------------
[Command]
name = "recovery";Required (do not remove)
command = a+b
time= 1

[Command]
name = "ab"
command = a+b
time= 1

;-| Dir + Button |---------------------------------------------------------
[Command]
name = "fwd_a"
command = /F,a
time= 1

[Command]
name = "fwd_b"
command = /F,b
time= 1

[Command]
name = "fwd_c"
command = /F,c
time= 1

[Command]
name = "fwd_x"
command = /F,x
time= 1

[Command]
name = "fwd_y"
command = /F,y
time= 1

[Command]
name = "fwd_z"
command = /F,z
time= 1

[Command]
name = "back_a"
command = /B,a
time= 1

[Command]
name = "back_b"
command = /B,b
time= 1

[Command]
name = "back_c"
command = /B,c
time= 1

[Command]
name = "down_a"
command = /$D,a
time= 1

[Command]
name = "down_b"
command = /$D,b
time= 1

[Command]
name = "down_c"
command = /$D,c
time= 1

[Command]
name = "fwd_ab"
command = /F,a+b
time= 1

[Command]
name = "back_ab"
command = /B,a+b
time= 1

;-| Single Button |---------------------------------------------------------
[Command]
name = "a"
command = a
time= 1

[Command]
name = "b"
command = b
time= 1

[Command]
name = "c"
command = c
time= 1

[Command]
name = "x"
command = x
time= 1

[Command]
name = "y"
command = y
time= 1

[Command]
name = "z"
command = z
time= 1

[Command]
name = "s"
command = s
time = 1

;-| Hold Dir |--------------------------------------------------------------
[Command]
name = "holdfwd";Required (do not remove)
command = /$F
time= 1

[Command]
name = "holdback";Required (do not remove)
command = /$B
time= 1

[Command]
name = "holdup";Required (do not remove)
command = /$U
time= 1

[Command]
name = "holddown";Required (do not remove)
command = /$D
time= 1

;---------------------------------------------------------------------------
; 2. State entry
; --------------
; This is where you define what commands bring you to what states.
;
; Each state entry block looks like:
;   [State -1]                  ;Don't change this
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
;---------------------------------------------------------------------------
;RunFwd

;---------------------------------------------------------------------------
;Stand_Throw (close dir+b)
; Complicated? Skip the throws and look at stand_a, etc, first.
; This is disabled right now. Remove the "null;" below when you
; want to use it.
[State -1]
type = null; ChangeState
value = 900
triggerall = statetype = S
triggerall = ctrl = 1
triggerall = p2bodydist X < 5;Near P2
trigger1 = command = "fwd_b";p2 stand
trigger1 = stateno != 100;Not running
trigger1 = p2statetype = S
trigger1 = p2movetype != H
trigger2 = command = "fwd_b";p2 crouch
trigger2 = stateno != 100;Not running
trigger2 = p2statetype = C
trigger2 = p2movetype != H
trigger3 = command = "back_b";p2 stand
trigger3 = p2statetype = S
trigger3 = p2movetype != H
trigger4 = command = "back_b";p2 crouch
trigger4 = p2statetype = C
trigger4 = p2movetype != H

;---------------------------------------------------------------------------
;Air_Throw1 (close dir+b)
; This is disabled right now. Remove the "null;" below when you
; want to use it.
[State -1]
type = null; ChangeState
value = 950
triggerall = statetype = A
triggerall = ctrl = 1
triggerall = p2bodydist X < 9
triggerall = p2bodydist Y > -22
triggerall = p2bodydist Y < 22
triggerall = p2statetype = A
triggerall = p2movetype != H
trigger1 = command = "fwd_b"
trigger2 = command = "back_b"

;===========================================================================
;---------------------------------------------------------------------------
