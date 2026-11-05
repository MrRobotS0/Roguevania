class_name BossWyrm
extends Boss

# A serpe do fundo: O deus que se escondia deixou alguém na porta.


func _init() -> void:
	title = "A SERPE DO FUNDO"
	subtitle = "O DEUS QUE SE ESCONDIA DEIXOU ALGUÉM NA PORTA"
	defeat_text = "A PORTA DO FUNDO ESTÁ ABERTA. LÁ DENTRO, NINGUÉM"
	sheet = "boss_wyrm"
	max_hp = 2100
	hp = 2100
	w = 48
	h = 40
	weight = 5.0
	walk_speed = 70.0
	keep_distance = 0.0
	sounds = {"volley": "roar", "leap": "roar"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "custom", "windup": 0.45, "recover": 0.4},
		{"type": "volley", "windup": 0.55, "style": "orb", "count": 4, "spread": 0.25, "speed": 260.0, "damage": 18.0, "color": Color("ff8a3a")},
		{"type": "leap", "windup": 0.6, "radius": 76.0, "damage": 24.0},
		{"type": "wave", "windup": 0.5, "speed": 220.0, "damage": 18.0},
	]
	moves2 = [
		{"type": "rain", "windup": 0.6, "style": "glass", "count": 6, "height": 50.0, "damage": 16.0},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/crevice_snake.gd", "count": 2},
	]


const DIG := 0.4
const SWIM_END := 2.1
const ERUPT := 2.55

var _erupted := false
var _warned := false


# Cava: anda debaixo do chão atrás de você, só a terra denuncia. Sai numa coluna
# de pedra, e depois fica exausta: a maior janela da luta.
func custom_start(_m: Dictionary) -> void:
	_erupted = false
	_warned = false
	ghost = true
	Sfx.play("burrow", -2.0)


func custom_update(_m: Dictionary, _delta: float) -> bool:
	if state_time < DIG:
		velocity.x = 0.0
		_alpha = 1.0 - state_time / DIG
		Fx.burst(global_position, Palette.DUST, 2, 90.0, 0.4, 200.0, 2.0, 40.0)
	elif state_time < SWIM_END:
		_alpha = 0.0
		face_player()
		velocity.x = 0.0 if blocked(facing) else facing * 175.0 / _tm()
		if int(state_time * 20.0) % 2 == 0:
			Fx.burst(global_position + Vector2(randf_range(-14.0, 14.0), -1.0), Palette.DUST, 2, 60.0, 0.4, 200.0, 2.0, 30.0)
	elif state_time < ERUPT:
		velocity.x = 0.0
		if not _warned:
			_warned = true
			make_hazard("glass", global_position.x, ERUPT - SWIM_END, 26.0, 64.0, 92.0)
			Sfx.play("crack", -2.0)
	elif not _erupted:
		_erupted = true
		ghost = false
		_alpha = 1.0
		velocity = Vector2(0, -260.0)
		for i in 3:
			lob("brick", center() + Vector2(0, -20), Vector2(global_position.x + (i - 1) * 70.0, global_position.y - 10.0), 0.8, 12.0, Color("8a7a68"))
		Fx.add_shake(7.0)
		Sfx.play("slam")
	elif state_time > ERUPT + 0.2 and is_on_floor():
		_done_moves = rest_every - 1
		return true
	return false


func custom_abort() -> void:
	ghost = false
	_alpha = 1.0
