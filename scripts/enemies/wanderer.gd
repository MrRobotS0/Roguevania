class_name Wanderer
extends Grunt

# Bosque Errante: saiu de casa para seguir o deus e esqueceu a volta.


func _init() -> void:
	super._init()
	title = "ANDARILHO PERDIDO"
	sheet = "wanderer"
	max_hp = 62
	hp = 62
	w = 12
	h = 30


var _swings := 0


# Três golpes avançando e aí esquece o que fazia: fica perdido, olhando em volta.
func think(delta: float) -> void:
	if state == "lost":
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		facing = 1 if int(state_time * 2.0) % 2 == 0 else -1
		if state_time >= 1.5:
			set_state("chase")
		return
	var before := state
	super.think(delta)
	if before == "attack" and state == "recover":
		_swings += 1
		if _swings < 3 and absf(to_player().x) < 70.0:
			face_player()
			set_state("windup")
			state_time = WINDUP - 0.2
		else:
			_swings = 0
			set_state("lost")


func overhead_text() -> String:
	return "?" if state == "lost" else ""


func sprite_anim() -> Array:
	if state == "lost":
		return ["idle", 0]
	return super.sprite_anim()
