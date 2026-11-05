class_name Frogman
extends Mason

# Bosque Errante: de longe cospe pedra em arco; de perto, bate.


func _init() -> void:
	super._init()
	title = "SAPO-HOMEM"
	sheet = "frogman"
	max_hp = 50
	hp = 50
	w = 20
	h = 20


var _hop := 0.6


# Anda aos saltos, e a queda bate no chão em volta dele.
func think(delta: float) -> void:
	if state == "hop":
		if state_time > 0.12 and is_on_floor():
			velocity.x = 0.0
			strike(Rect2(global_position.x - 32.0, global_position.y - 14.0, 64.0, 14.0), 12.0, 190.0)
			Fx.burst(global_position, Palette.DUST, 12, 130.0, 0.4, 200.0, 2.0, 30.0)
			Fx.add_shake(1.5)
			Sfx.play("slam", -10.0)
			_hop = 0.7
			set_state("chase")
		return
	super.think(delta)
	if state == "chase":
		_hop -= delta
		var d := to_player()
		if _hop <= 0.0 and is_on_floor() and absf(d.x) > REACH and absf(d.y) < 90.0:
			face_player()
			velocity = Vector2(facing * minf(absf(d.x) * 1.5, 190.0), -300.0)
			set_state("hop")
			Sfx.play("slag_hop", -8.0)


func sprite_anim() -> Array:
	if state == "hop":
		return ["attack", 0]
	return super.sprite_anim()
