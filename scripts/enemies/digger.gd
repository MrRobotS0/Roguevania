class_name Digger
extends Pilgrim

# Cavernas Fundas: cava atrás do deus escondido. Acende a bomba quando chega perto.


func _init() -> void:
	super._init()
	title = "ESCAVADOR"
	sheet = "digger"
	max_hp = 34
	hp = 34
	w = 12
	h = 22


var _bomb_cd := 1.2


func telegraphing() -> bool:
	return state in ["ignite", "light"]


# De longe joga banana de dinamite; só se acende se você chegar perto.
func think(delta: float) -> void:
	_bomb_cd -= delta
	var d := to_player()
	if state == "light":
		velocity.x = 0.0
		if state_time >= 0.45:
			var p := lob("bomb", center() + Vector2(facing * 6.0, -8.0), player.center(), 0.8, 16.0, null, 520.0)
			p.radius = 30.0
			p.fuse = 1.05
			p.damage.status = {"burn": 2.0}
			Sfx.play("throw", -6.0)
			_bomb_cd = 2.6
			set_state("chase")
		return
	if state == "chase" and _bomb_cd <= 0.0 and absf(d.x) > 60.0 and absf(d.x) < 180.0 and absf(d.y) < 60.0:
		face_player()
		velocity.x = 0.0
		set_state("light")
		Sfx.play("fuse", -10.0)
		return
	super.think(delta)


func sprite_anim() -> Array:
	if state == "light":
		return ["ignite", 0]
	return super.sprite_anim()
