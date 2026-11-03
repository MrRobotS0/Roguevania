class_name Grunt
extends Enemy

# Brutamontes: patrulha, persegue e dá uma pancada lenta e bem avisada.
# É o inimigo para treinar "esperar o aviso, rolar ou interromper".

const WALK := 34.0
const CHASE := 72.0
const REACH := 30.0
const WINDUP := 0.5
const ACTIVE := 0.14
const RECOVER := 0.6
const DAMAGE := 15

var _hit_done := false


func _init() -> void:
	title = "PENITENTE"
	max_hp = 60
	hp = 60
	w = 14
	h = 22


func body_color() -> Color:
	return Palette.GRUNT


func telegraphing() -> bool:
	return state == "windup"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			if blocked(facing):
				facing = -facing
			velocity.x = facing * WALK
			if sees_player(150.0, 40.0):
				set_state("chase")
		"chase":
			facing = 1 if d.x > 0.0 else -1
			if not player.alive() or absf(d.x) > 260.0 or absf(d.y) > 120.0:
				set_state("idle")
			elif absf(d.x) < REACH and absf(d.y) < 26.0:
				velocity.x = 0.0
				set_state("windup")
			elif blocked(facing):
				velocity.x = 0.0
			else:
				velocity.x = facing * CHASE
		"windup":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if state_time >= WINDUP:
				_hit_done = false
				velocity.x = 0.0 if blocked(facing) else facing * 170.0
				set_state("attack")
		"attack":
			velocity.x = 0.0 if blocked(facing) else move_toward(velocity.x, 0.0, 900.0 * delta)
			if not _hit_done:
				_hit_done = strike(front_rect(30.0, 18.0), DAMAGE)
			if state_time >= ACTIVE:
				set_state("recover")
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_time >= RECOVER:
				set_state("chase")


func draw_body() -> void:
	var lean := 0.0
	var body := Palette.GRUNT
	if state == "windup":
		lean = -2.0
		body = Palette.GRUNT.lerp(Palette.TELEGRAPH, 0.35 + 0.35 * sin(state_time * 30.0))
	elif state == "attack":
		lean = 2.0
	var step := sin(_anim * 10.0) * 1.5 if absf(velocity.x) > 5.0 else 0.0

	px(-6 + step, -6, 4, 6, Palette.GRUNT_DARK)
	px(2 - step, -6, 4, 6, Palette.GRUNT_DARK)
	px(-7 + lean, -18, 14, 13, body)
	px(-7 + lean, -9, 14, 2, Palette.GRUNT_DARK)
	px(-5 + lean, -22, 9, 5, body.darkened(0.15))
	px(1 + lean, -20, 2, 1, Palette.ENEMY_EYE)

	# clava: erguida atrás no aviso, à frente no golpe
	match state:
		"windup":
			px(-9 + lean, -30, 3, 14, Palette.WOOD)
			px(-10 + lean, -32, 5, 5, Palette.WOOD_TOP)
		"attack":
			px(6, -14, 18, 3, Palette.WOOD)
			px(22, -16, 5, 6, Palette.WOOD_TOP)
			if state_time < ACTIVE:
				var swoosh := Palette.SLASH
				swoosh.a = 0.6
				px(6, -20, 22, 1, swoosh)
				px(10, -6, 18, 1, swoosh)
		_:
			px(5 + lean, -16, 3, 12, Palette.WOOD)
			px(4 + lean, -6, 5, 4, Palette.WOOD_TOP)
