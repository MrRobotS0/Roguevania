class_name Dancer
extends Enemy

# Dançarino Amarelo (Carcosa): gira no lugar, avisando, e atravessa a sala
# num rodopio que corta tudo no caminho. Depois fica tonto: é a hora.

const DASH_SPEED := 330.0
const DASH_TIME := 0.45


func _init() -> void:
	title = "DANÇARINO AMARELO"
	sheet = "dancer"
	max_hp = 50
	hp = 50
	w = 10
	h = 24
	essence_drop = Vector2i(2, 4)

var _hit := false


func telegraphing() -> bool:
	return state == "twirl"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			velocity.x = 0.0
			if sees_player(230.0, 60.0):
				set_state("chase")
		"chase":
			face_player()
			velocity.x = 0.0 if blocked(facing) else facing * 50.0
			if absf(d.x) < 150.0 and absf(d.y) < 30.0 and state_time > 0.8:
				velocity.x = 0.0
				set_state("twirl")
				Sfx.play("swing", -10.0)
		"twirl":
			velocity.x = 0.0
			facing = 1 if int(state_time * 14.0) % 2 == 0 else -1
			if state_time >= 0.55:
				face_player()
				_hit = false
				set_state("dash")
				Sfx.play("swing_heavy", -6.0)
		"dash":
			velocity.x = 0.0 if blocked(facing) else facing * DASH_SPEED
			if not _hit:
				_hit = strike(hurt_rect().grow(4.0), 17, 210.0)
			if int(state_time * 30.0) % 2 == 0:
				Fx.burst(center(), EnemyLooks.palette(look)[10], 1, 20.0, 0.3, 0.0, 2.0)
			if state_time >= DASH_TIME or velocity.x == 0.0 and state_time > 0.05:
				set_state("dizzy")
		"dizzy":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_time >= 0.9:
				set_state("chase")


func sprite_anim() -> Array:
	match state:
		"twirl":
			return ["cast", int(state_time * 6.0)]
		"dash":
			return ["attack", 0]
		"dizzy":
			return ["rest", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 8.0)]
	return ["idle", int(_anim * 2.0)]
