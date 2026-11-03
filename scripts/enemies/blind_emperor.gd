class_name BlindEmperor
extends Enemy

# O Imperador Cego. Arrancou os olhos para enxergar o futuro, e luta assim:
#  · Profecia: marca o chão onde você VAI estar (lê sua velocidade) e uma
#    coluna de luz cai ali. Quem corre previsível apanha.
#  · Cetro: varredura larga de perto. Dá para aparar com escudo.
#  · Passo do Destino (fase 2): some e reaparece do outro lado.
#  · Três Visões (fase 2): três colunas — onde você está, onde vai e onde
#    estaria se voltasse.
#  · Chamado das Casas (fase 2): convoca peregrinos.
# Depois de cada profecia grande ele se ajoelha, exausto: é a sua janela.

signal phase_changed(phase: int)

const SWEEP_REACH := 74.0
const SWEEP_DAMAGE := 24.0
const OMEN_DAMAGE := 22.0
const SEE_AHEAD := 0.75

const ROBE := Color("3b2550")
const ROBE_DARK := Color("24163a")
const GOLD := Color("e0b04a")
const BAND := Color("efe6d2")
const EYE := Color("8ff7e8")

var phase := 1
var arena: Rect2
var _attacks := 0
var _summon_cd := 6.0
var _hit_done := false
var _alpha := 1.0
var _cast_count := 1
var _crown: PointLight2D


func _init() -> void:
	title = "O IMPERADOR CEGO"
	max_hp = 900
	hp = 900
	w = 22
	h = 40
	weight = 4.0
	poise = 1.0
	unstoppable = true
	essence_drop = Vector2i(60, 60)


func _ready() -> void:
	super._ready()
	_crown = Glow.attach(self, EYE, 70.0, 0.4, Vector2(0, -38))
	set_state("intro")
	facing = -1


func body_color() -> Color:
	return ROBE


func telegraphing() -> bool:
	return state in ["sweep_windup", "cast"]


func hurt(d: Damage) -> bool:
	if state in ["intro", "vanish"] or _alpha < 0.5:
		return false
	if state == "kneel" and not d.over_time:
		d.amount *= 1.5
		d.crit = true
	var hit := super.hurt(d)
	if hit and phase == 1 and hp <= max_hp / 2 and alive():
		phase = 2
		phase_changed.emit(2)
		Fx.add_shake(6.0)
		Sfx.play("roar")
		set_state("idle")
	return hit


func think(delta: float) -> void:
	var d := to_player()
	_summon_cd -= delta
	match state:
		"intro":
			velocity.x = 0.0
			if state_time >= 1.8:
				set_state("idle")
		"idle", "chase":
			face_player()
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time >= (0.7 if phase == 1 else 0.45):
				_choose(d)
		"walk":
			face_player()
			velocity.x = facing * 70.0
			if absf(d.x) < SWEEP_REACH - 10.0 or state_time > 1.2:
				set_state("sweep_windup")
		"sweep_windup":
			velocity.x = 0.0
			if state_time >= (0.6 if phase == 1 else 0.45):
				_hit_done = false
				set_state("sweep")
				Sfx.play("swing_heavy")
		"sweep":
			if not _hit_done:
				_hit_done = strike(front_rect(SWEEP_REACH, 30.0, 4.0), SWEEP_DAMAGE, 260.0)
			if state_time >= 0.18:
				set_state("recover")
		"cast":
			velocity.x = 0.0
			if state_time >= 0.5:
				_prophecy(_cast_count)
				set_state("kneel" if _cast_count >= 3 or (_attacks % 3 == 0) else "recover")
		"kneel":
			velocity.x = 0.0
			if state_time >= 1.5:
				set_state("idle")
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time >= (0.7 if phase == 1 else 0.45):
				set_state("idle")
		"vanish":
			_alpha = 1.0 - clampf(state_time / 0.3, 0.0, 1.0)
			if state_time >= 0.3:
				var side := -1 if d.x > 0.0 else 1
				var x := clampf(player.global_position.x - side * 90.0, arena.position.x + 30.0, arena.end.x - 30.0)
				global_position.x = x
				face_player()
				set_state("appear")
		"appear":
			_alpha = clampf(state_time / 0.25, 0.0, 1.0)
			if state_time >= 0.25:
				_alpha = 1.0
				set_state("sweep_windup")
		"summon":
			velocity.x = 0.0
			if state_time >= 0.6:
				_summon()
				set_state("recover")


func _choose(d: Vector2) -> void:
	_attacks += 1
	if phase == 2 and _summon_cd <= 0.0:
		_summon_cd = 14.0
		set_state("summon")
	elif phase == 2 and _attacks % 4 == 0:
		set_state("vanish")
	elif absf(d.x) < SWEEP_REACH:
		set_state("sweep_windup")
	elif randf() < 0.65:
		_cast_count = 3 if (phase == 2 and randf() < 0.5) else 1
		set_state("cast")
		Sfx.play("omen", -2.0)
	else:
		set_state("walk")


# A profecia: onde o herói vai estar daqui a SEE_AHEAD segundos.
func predict() -> float:
	var x := player.global_position.x + player.velocity.x * SEE_AHEAD
	return clampf(x, arena.position.x + 16.0, arena.end.x - 16.0)


func _prophecy(count: int) -> void:
	var now := player.global_position.x
	var ahead := predict()
	var spots: Array[float] = [ahead]
	if count >= 3:
		spots.append(now)
		spots.append(clampf(now - (ahead - now), arena.position.x + 16.0, arena.end.x - 16.0))
	for x in spots:
		var omen := Hazard.new()
		omen.player = player
		omen.style = "light"
		omen.source = self
		omen.width = 22.0
		omen.height = 170.0
		omen.damage = OMEN_DAMAGE
		omen.delay = 0.8 if phase == 1 else 0.65
		omen.position = Vector2(x, global_position.y)
		get_parent().add_child(omen)


func _summon() -> void:
	for side in [-1, 1]:
		var x := clampf(global_position.x + side * 110.0, arena.position.x + 24.0, arena.end.x - 24.0)
		var p := Pilgrim.new()
		p.room = room
		p.player = player
		p.essence_drop = Vector2i(0, 0)
		p.position = Vector2(x, global_position.y)
		get_parent().add_child(p)
		Fx.burst(p.position + Vector2(0, -10), Palette.DUST, 14, 120.0, 0.5)


func _die() -> void:
	Fx.burst(center(), GOLD, 40, 260.0, 1.0, 300.0, 3.0, 60.0)
	Fx.burst(center(), EYE, 30, 200.0, 1.2, -50.0, 2.0)
	Fx.add_shake(9.0)
	Fx.hitstop(0.4)
	Sfx.play("boss_die")
	super._die()


func draw_body() -> void:
	_crown.energy = (1.1 if state in ["cast", "intro"] else 0.35) * _alpha
	if _alpha <= 0.02:
		return
	var a := _alpha
	var kneel := 10.0 if state == "kneel" else 0.0
	var robe := ROBE
	if state == "sweep_windup":
		robe = ROBE.lerp(Palette.TELEGRAPH, 0.25 + 0.25 * sin(state_time * 30.0))
	robe.a = a
	var dark := ROBE_DARK
	dark.a = a
	var gold := GOLD
	gold.a = a
	var band := BAND
	band.a = a
	px(-11, -30 + kneel, 22, 30 - kneel, robe)
	px(-11, -8, 22, 8, dark)
	px(-2, -28 + kneel, 4, 20, gold)
	px(-7, -40 + kneel, 14, 11, dark)
	px(-7, -36 + kneel, 14, 3, band)
	# coroa de três pontas
	px(-7, -43 + kneel, 2, 3, gold)
	px(-1, -45 + kneel, 2, 5, gold)
	px(5, -43 + kneel, 2, 3, gold)
	px(-7, -41 + kneel, 14, 1, gold)
	# o terceiro olho acende quando ele vê o futuro
	var eye := EYE
	eye.a = a * (1.0 if state in ["cast", "intro"] else 0.45)
	px(-1, -39 + kneel, 2, 2, eye)
	# cetro
	var sx := 12.0
	var sy := -34.0
	match state:
		"sweep_windup":
			sx = -14.0
			sy = -50.0
		"sweep":
			sx = 30.0
			sy = -20.0
	px(sx * 0.5 + 6, sy * 0.5 - 6 + kneel, 2, 26, gold)
	px(sx * 0.5 + 4, sy * 0.5 - 10 + kneel, 6, 5, eye)
	if state == "sweep" and state_time < 0.18:
		var arc := Palette.SLASH
		arc.a = 0.6
		px(10, -36, SWEEP_REACH - 8.0, 2, arc)
		px(10, -6, SWEEP_REACH - 8.0, 2, arc)
	if state == "kneel":
		PixelFont.draw_centered(self, "EXAUSTO", Vector2(0, -h - 12 + kneel), Palette.DANGER)
