;---------------------------------------------------------------------------
[Command]
name = "Rasengan"     ;Required (do not remove)
command = ~D,DF,F,a
time = 15

[Command]
name = "Kage Bunshin no Jutsu"     ;Required (do not remove)
command = ~D,DB,B,a
time = 15

[Command]
name = "Chidori"     ;Required (do not remove)
command = ~D,DF,F,b
time = 15

[Command]
name = "Boruto Dash"     ;Required (do not remove)
command = ~D,DB,B,b
time = 40

[command]
name = "Suiton" ;Required (do not remove)
command = ~D,DF,F,c
time = 15

[Command]
name = "Hakke Kusho"     ;Required (do not remove)
command = ~D,DB,B,c
time = 15

[Command]
name = "leon"     ;Required (do not remove)
command = ~D,DB,B,s
time = 15

[Command]
name = "sa"     ;Required (do not remove)
command = s,a
time = 20


[Command]
name = "Da"     ;Required (do not remove)
command = D,a
time = 20

[Command]
name = "Db"     ;Required (do not remove)
command = D,b
time = 20

[Command]
name = "Dc"     ;Required (do not remove)
command = D,c
time = 20

[Command]
name = "Dx"     ;Required (do not remove)
command = D,x
time = 20

[Command]
name = "Dy"     ;Required (do not remove)
command = D,y
time = 20

[Command]
name = "Dz"     ;Required (do not remove)
command = D,z
time = 20

[command]
name = "Ds"
command = D,s
time = 20

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
name = "Fuuton"
command = ~F,DF,D,DB,B,b
time = 35

[Command]
name = "suiton"
command = ~F,DF,D,DB,B,a
time = 35

[Command]
name = "Fuiton"
command = ~F,DF,D,DB,B,c
time = 35

;---------------------------------------------------------------------------
[Command]
name = "FF"     ;Required (do not remove)
command = F, F
time = 14
;---------------------------------------------------------------------------
[Command]
name = "U"     ;Required (do not remove)
command = U
time = 10

;---------------------------------------------------------------------------
[Command]
name = "aa"     ;Required (do not remove)
command = b, b
time = 10

[Command]
name = "BB"     ;Required (do not remove)
command = B,B
time = 15

[Command]
name = "recovery";Required (do not remove)
command = x+y
time = 1
;---------------------------------------------------------------------------
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
name = "start"
command = D,s
time = 1
;---------------------------------------------------------------------------
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
name = "hold_s";Required (do not remove)
command = /$s
time = 1

[Command]
name = "s"
command = s
time = 1

; Don't remove the following line. It's required by the CMD standard.
[Statedef -1]
;---------------------------------------------------------------------------

[State -1, Futon Blade ]
type = ChangeState
value = 2000
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = power >= 2000
triggerall = command = "Da"
trigger1 = statetype = C
trigger1 = ctrl

[State -1, Odama Rasengan ]
type = ChangeState
value = 2100
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = power >= 2500
triggerall = command = "Db"
trigger1 = statetype = C
trigger1 = ctrl
[State -1,uzumaki  Rendan ]
type = ChangeState
triggerall = numhelper(2350) = 0
value = 2300
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = power >= 3000
triggerall = command = "Dc"
trigger1 = statetype = C
trigger1 = ctrl

;---------------------------------------------------------------------------

[State -1, Ray break wind]
type = ChangeState
value = 7900
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = power >= 2000
triggerall = command = "Da"
trigger1 = statetype = C
trigger1 = ctrl

;---------------------------------------------------------------------------

[State -1,Shiden Portal ]
type = ChangeState
value = 8000
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = power >= 2500
triggerall = command = "Db"
trigger1 = statetype = C
trigger1 = ctrl
;---------------------------------------------------------------------------

[State -1,rasendori shuriken ]
type = ChangeState
value = 8100
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = power >= 3000
triggerall = command = "Dc"
trigger1 = statetype = C
trigger1 = ctrl

;===========================================================================
;--------------------------------Ataques Especiales-------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
[State -1, Rasengan]
type = ChangeState
triggerall = var(7) = 0
triggerall = var(10) = 0
Triggerall = power >= 900
value = 1000
triggerall = command = "Rasengan"
triggerall = statetype != A
trigger1 = ctrl


;---------------------------------------------------------------------------
[State -1, Kage Bunshin no Jutsu]
type = ChangeState
triggerall = numhelper(15000) = 0
triggerall = var(7) = 0
triggerall = var(5) = 0
triggerall = var(10) = 0
Triggerall = power >= 1200
value =1100
triggerall = command = "Kage Bunshin no Jutsu"
triggerall = statetype != A
trigger1 = ctrl

;;---------------------------------------------------------------------------
[State -1,galaga]
type = ChangeState
triggerall = numhelper(60000) = 0
triggerall = var(5) = 1
triggerall = var(10) = 0
Triggerall = power >= 1200
value =1102
triggerall = command = "Kage Bunshin no Jutsu"
triggerall = statetype != A
trigger1 = ctrl
---------------------------------------------------------------------------
[State -1, Chidori]
type = ChangeState
triggerall = var(7) = 0
triggerall = var(10) = 0
Triggerall = power >= 1200
value = 1200
triggerall = command = "Chidori"
triggerall = statetype != A
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1, Boruto Dash]
type = ChangeState
triggerall = var(7) = 0
triggerall = var(10) = 0
Triggerall = power >= 1100
value = 1300
triggerall = command = "Boruto Dash"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
 ;---------------------------------------------------------------------------
[State -1, Suiton]
type = ChangeState
triggerall = var(7) = 0
triggerall = var(10) = 0
Triggerall = power >= 1100
value = 1400
triggerall = command = "Suiton"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0

 ;---------------------------------------------------------------------------
[State -1, Hakke Kusho ]
type = ChangeState
triggerall = var(7) = 0
triggerall = var(10) = 0
Triggerall = power >= 1000
value = 1500
triggerall = command = "Hakke Kusho"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0

;---------------------------------------------------------------------------
; Awakening
[State -1, Awakening]
type = ChangeState
Triggerall = fvar(23) >=500
Triggerall = var(7) = 0
value = 550
triggerall = command = "s"
triggerall = command = "holddown"
trigger1 = statetype != A
trigger1 = ctrl

;---------------------------------------------------------------------------
; Awakening
[State -1, Awakening sage]
type = ChangeState
Triggerall = fvar(25) >=1000
triggerall = var(5) = 0
Triggerall = var(10) = 0
value = 555
triggerall = command = "s"
trigger1 = statetype != A
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,Air Rasengan]
type = ChangeState
Triggerall = pos y <= -10
value =1007
Triggerall = var(10) = 0
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = power >= 1000
triggerall = command = "Rasengan"
trigger1 = statetype = A
trigger1 = ctrl



;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
 ;---------------------------------------------------------------------------

 ;---------------------------------------------------------------------------
[State -1,Combo 1]
type = ChangeState
triggerall = numhelper(225) = 0
value = 200
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = command = "a"
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1,Combo 2]
type = ChangeState
triggerall = numhelper(225) = 0
value = 400
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = command = "b"
trigger1 = statetype = S
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,Combo 3]
type = ChangeState
triggerall = numhelper(225) = 0
value = 300
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = command = "c"
trigger1 = statetype = S
trigger1 = ctrl





[State -1,a]
type = ChangeState
value = 600
triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = command = "a"
trigger1 = statetype = A
trigger1 = ctrl

[State -1, Futon Blade ]
type = ChangeState
value = 7800
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = power >= 2000
triggerall = command = "Da"
trigger1 = statetype = C
trigger1 = ctrl
;-------------------------------------------------------
;-----------------------------------------------------------
;---------------------------------------------------------------------------
[State -1, Rasengan]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(10) = 0
Triggerall = power >= 900
value =7500
triggerall = command = "Rasengan"
triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Chidori]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(10) = 0
Triggerall = power >= 1200
value = 7740
triggerall = command = "Chidori"
triggerall = statetype != A
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,Air Rasengan]
type = ChangeState
Triggerall = pos y <= -60
triggerall = var(7) = 1
value =7560
triggerall = var(10) = 0
triggerall = power >= 1000
triggerall = command = "Rasengan"
trigger1 = statetype = A
trigger1 = ctrl


;---------------------------------------------------------------------------
[State -1, rafaga de leones]
type = ChangeState
triggerall = numhelper(15000) = 0
triggerall = var(7) = 1
triggerall = var(5) = 0
triggerall = var(10) = 0
Triggerall = power >= 1200
value =7700
triggerall = command = "Kage Bunshin no Jutsu"
triggerall = statetype != A
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1, Cortes de Raiton]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(10) = 0
Triggerall = power >= 1100
value = 7770
triggerall = command = "Boruto Dash"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
 ;---------------------------------------------------------------------------
[State -1,jogan activado vision ]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(4) = 0
triggerall = var(10) = 0
Triggerall = power >= 1000
value = 7780
triggerall = command = "Hakke Kusho"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0
 ;---------------------------------------------------------------------------
[State -1, Karma]
type = ChangeState
triggerall = var(7) =1
triggerall = var(10) = 0
Triggerall = power >= 1100
value = 7790
triggerall = command = "Suiton"
triggerall = statetype != A
trigger1 = ctrl
trigger2 = numhelper(700) > 0

;---------------------------------------------------------------------------
[State -1,FF]
type = ChangeState
value = 2060
Triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = command = "FF"
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1,BB]
type = ChangeState
value = 2070
Triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = command = "BB"
trigger1 = statetype = S
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,FF]
type = ChangeState
value = 13060
Triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = command = "FF"
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1,BB]
type = ChangeState
value = 13070
Triggerall = var(7) = 0
triggerall = var(10) = 0
triggerall = command = "BB"
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
; Power Charge
[State -1, Power Charge]
type = ChangeState
Triggerall = var(5) = 0
value = 500
triggerall = command = "s"
trigger1 = statetype != A
trigger1 = ctrl
;----------------------------------------
;jogan
;---------------------------------------------------------------------------
[State -1,Combo 1]
type = ChangeState
triggerall = numhelper(225) = 0
value = 7200
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = command = "a"
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1,Combo 2]
type = ChangeState
triggerall = numhelper(225) = 0
value = 7300
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = command = "b"
trigger1 = statetype = S
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,Combo 3]
type = ChangeState
triggerall = numhelper(225) = 0
value = 7400
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = command = "c"
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1,Combo 3]
type = ChangeState
triggerall = numhelper(225) = 0
value = 7600
triggerall = var(7) = 1
triggerall = var(10) = 0
triggerall = command = "a"
trigger1 = statetype = A
trigger1 = ctrl



;---------------------------------------------------------------------------
;AI
;---------------------------------------------------------------------------
[State -1, AI on]
type = VarSet
triggerAll = Var(10) < 1
triggerAll = RoundState = 2
trigger1 = AILevel > 0
v = 10
value = 1
Ignorehitpause = 1

[State -1, AI OFF]
type = VarSet
trigger1 = var(10) > 0
trigger1 = RoundState != 2
trigger2 = AILevel = 0
v = 10
value = 0
Ignorehitpause = 1

;---------------------------------------------------------------------------
[State -1,AI Combo 1]
type = ChangeState
triggerall = var(7) = 0
value = 200
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 70
;---------------------------------------------------------------------------
[State -1,AI Combo 2]
type = ChangeState
triggerall = var(7) = 0
value = 400
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 70
;---------------------------------------------------------------------------
[State -1,AI Combo 3]
type = ChangeState
triggerall = var(7) = 0
value = 300
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 70

[State -1,ia a]
type = ChangeState
value = 600
triggerall = var(7) = 0
triggerall = var(10) = 1
trigger1 = statetype = A
trigger1 = ENEMY,statetype = A
trigger1 = p2dist x< 50
trigger1 = ctrl
[State -1,ia a JOGAN]
type = ChangeState
value = 7600
triggerall = var(7) = 0
triggerall = var(10) = 1
trigger1 = statetype = A
trigger1 = ENEMY,statetype = A
trigger1 = p2dist x< 50
trigger1 = ctrl
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
[State -1,AI Rasengan]
type = ChangeState
value = 1000
triggerall = var(7) = 0
triggerall = var(10) = 1
triggerall = power >= 900
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 100
;---------------------------------------------------------------------------
[State -1, Kage Bunshin no Jutsu]
type = ChangeState
triggerall = numhelper(15000) = 0
triggerall = var(7) = 0
triggerall = var(5) = 0
triggerall = var(10) = 1
Triggerall = power >= 1200
value =1100
trigger1 = random <=500
trigger1 = p2dist x > 30
triggerall = statetype =s
trigger1 = ctrl

;;---------------------------------------------------------------------------
[State -1,ai galaga]
type = ChangeState
triggerall = numhelper(60000) = 0
triggerall = var(5) = 1
triggerall = var(10) = 1
Triggerall = power >= 1200
value =1102
trigger1 = random <=900
trigger1 = p2dist x > 30
triggerall = statetype =s
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1,AI Chidori]
type = ChangeState
value = 1200
triggerall = var(7) = 0
triggerall = var(10) = 1
triggerall = power >= 1200
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 100
;---------------------------------------------------------------------------
[State -1,AI Boruto Dash]
type = ChangeState
triggerall = var(7) = 0
value = 1300
triggerall = var(10) = 1
triggerall = power >= 1300
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 100
;---------------------------------------------------------------------------
[State -1,AI Suiton]
type = ChangeState
triggerall = var(7) = 0
value = 1400
triggerall = var(10) = 1
triggerall = power >= 1400
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 100
;---------------------------------------------------------------------------
[State -1,AI Hakke Kusho]
type = ChangeState
triggerall = var(7) = 0
value = 1500
triggerall = var(10) = 1
triggerall = power >= 1500
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 100

;---------------------------------------------------------------------------
[State -1,AI Air Rasengan]
type = ChangeState
triggerall = power >= 900
Triggerall = pos y <= -10
value =1007
triggerall = var(10) = 1
trigger1 = statetype = a
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) <= 50
;---------------------------------------------------------------------------
[State -1,AI Air Combo ]
type = ChangeState
Triggerall = pos y <= -10
value =600
triggerall = var(10) = 1
trigger1 = statetype = a
trigger1 = ctrl
trigger1 = (random%100) < 5
trigger1 = (p2dist x) >= 50

;---------------------------------------------------------------------------
[State -1,AI Futon Blade]
type = ChangeState
value = 2000
triggerall = var(7) = 0
triggerall = var(10) = 1
triggerall = power >= 2000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 100

;---------------------------------------------------------------------------
[State -1,AI Odama Rasengan]
type = ChangeState
value = 2100
triggerall = var(7) = 0
triggerall = var(10) = 1
triggerall = power >= 2500
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 100


;---------------------------------------------------------------------------
[State -1,AI  Chidori Rendan]
type = ChangeState
value = 2300
triggerall = numhelper(2350) = 0
triggerall = var(7) = 0
triggerall = var(10) = 1
triggerall = power >= 3000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 20
trigger1 = (p2dist x) >= 100


;---------------------------------------------------------------------------

[State -1,AI Ray break wind]
type = ChangeState
value = 7900
triggerall = var(7) = 1
triggerall = var(10) = 1
triggerall = power >= 2000
trigger1 = random <=500
trigger1= enemy,statetype = s
trigger1 = p2dist x > 50
trigger1 = statetype = s
trigger1 = ctrl

;---------------------------------------------------------------------------

[State -1, AI Shiden Portal ]
type = ChangeState
value = 8000
triggerall = var(7) = 1
triggerall = var(10) = 1
triggerall = power >= 2500
trigger1 = random <=500
trigger1= enemy,statetype = s
trigger1 = p2dist x >50
trigger1 = statetype = s
trigger1 = ctrl
;---------------------------------------------------------------------------

[State -1,AI rasendori shuriken ]
type = ChangeState
value = 8100
triggerall = var(7) = 1
triggerall = var(10) =1
triggerall = power >= 3000
trigger1 = random <=999
trigger1= enemy,statetype = s
trigger1 = p2dist x >50
trigger1 = statetype = s
trigger1 = ctrl

;---------------------------------------------------------------------------
; Awakening
[State -1,AI Awakening JOGAN]
type = ChangeState
Triggerall = fvar(23) >=500
Triggerall = var(7) = 0
Triggerall = var(10) = 1
value = 550
trigger1 = random <=999
trigger1 = statetype =S
trigger1 = ctrl

;---------------------------------------------------------------------------
; Awakening
[State -1, IA Awakening sage]
type = ChangeState
Triggerall = fvar(25) >=1000
triggerall = var(5) = 0
Triggerall = var(10) = 1
value = 555
trigger1 = statetype =S
trigger1 = random <=999
trigger1 = ctrl
;-------------------------------------------------------
;-----------------------------------------------------------
;---------------------------------------------------------------------------
[State -1,AI Rasengan]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(10) = 1
Triggerall = power >= 900
value =7500
trigger1 = random <=500
trigger1 = p2dist x >50
trigger1 = statetype = S
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1,AI Chidori]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(10) = 1
Triggerall = power >= 1200
value = 7740
trigger1 = random <=500
trigger1 = p2dist x >50
trigger1 = statetype = S
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,AI Air Rasengan]
type = ChangeState
Triggerall = pos y <= -60
triggerall = var(7) = 1
triggerall = var(5) = 0
value =7560
triggerall = var(10) = 1
triggerall = power >= 1000
trigger1 = random <=100
trigger1 = p2dist x >50
trigger1 = statetype = A
trigger1 = ctrl


;---------------------------------------------------------------------------
[State -1,AI KAGEBUSHIN SHURIKEN]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(10) = 1
Triggerall = power >= 1200
value =7700
trigger1 = random <=500
trigger1 = p2dist x >50
trigger1 = statetype = S
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,AI Cortes de Raiton]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(10) = 1
Triggerall = power >= 1100
value = 7770
trigger1 = random <=500
trigger1 = p2dist x >50
trigger1 = statetype = S
trigger1 = ctrl

 ;---------------------------------------------------------------------------
[State -1,AI jogan activado vision ]
type = ChangeState
triggerall = var(7) = 1
triggerall = var(4) = 0
triggerall = var(10) = 1
Triggerall = power >= 1000
value = 7780
trigger1 = random <=500
trigger1 = p2dist x >50
trigger1 = statetype = S
trigger1 = ctrl

 ;---------------------------------------------------------------------------
[State -1,AI Karma]
type = ChangeState
triggerall = var(7) =1
triggerall = var(10) = 1
Triggerall = power >= 1100
value = 7790
trigger1 = random <=500
trigger1 = p2dist x <50
trigger1 = statetype = S
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1,ai FF]
type = ChangeState
value = 2060
triggerall = var(7) = 1
triggerall = var(10) = 1
triggerall = power < 3000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 150

;---------------------------------------------------------------------------
[State -1,ai FF]
type = ChangeState
value = 2070
triggerall = var(7) = 1
triggerall = var(10) = 1
triggerall = power < 3000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 150


;---------------------------------------------------------------------------
[State -1,ai FF]
type = ChangeState
value = 13060
triggerall = var(7) = 0
triggerall = var(10) = 1
triggerall = power < 3000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 150

;---------------------------------------------------------------------------
[State -1,ai FF]
type = ChangeState
value = 13070
triggerall = var(7) = 0
triggerall = var(10) = 1
triggerall = power < 3000
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 150
;---------------------------------------------------------------------------
[State -1, Power Charge]
type = changestate
triggerall = power >=3000
triggerall = var(7) = 0
triggerall = RoundState = 2 && var(10)
triggerall = StateType = S
triggerall = (p2statetype = S) || (p2statetype = C)|| (p2statetype = A)
triggerall = Ctrl
triggerall = P2BodyDist X >= 100
trigger1 = power < 1000 && Random = [600,800]
trigger2 = power < 2000 && power > 1000 && Random = [400,600]
trigger3 = power < 3000 && power > 2000 && Random = [200,400]
value = 550
;---------------------------------------------------------------------------
[State -1, Power Charge]
type = changestate
triggerall = power < 3000
triggerall = RoundState = 2 && var(10)
triggerall = StateType = S
triggerall = (p2statetype = S) || (p2statetype = C)|| (p2statetype = A)
triggerall = Ctrl
triggerall = P2BodyDist X >= 100
trigger1 = power < 1000 && Random = [600,800]
trigger2 = power < 2000 && power > 1000 && Random = [400,600]
trigger3 = power < 3000 && power > 2000 && Random = [200,400]
value = 500
;---------------------------------------------------------------------------
[State -1,AI Combo 2]
type = ChangeState
triggerall = var(7) = 1
value = 7200
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 70
;---------------------------------------------------------------------------
[State -1,AI Combo 2]
type = ChangeState
triggerall = var(7) = 1
value = 7300
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 70
;---------------------------------------------------------------------------
[State -1,AI Combo 2]
type = ChangeState
triggerall = var(7) = 1
value = 7400
triggerall = var(10) = 1
trigger1 = statetype = S
trigger1 = ctrl
trigger1 = (random%100) < 10
trigger1 = (p2dist x) >= 0
trigger1 = (p2dist x) < 70

