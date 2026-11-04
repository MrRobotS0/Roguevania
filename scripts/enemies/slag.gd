class_name Slag
extends Enemy

# Escória Viva: bolha de metal derretido que pula atrás de você. Encostar
# queima. Morta, vira uma poça que ainda queima por um tempo.

const HOP_EVERY := 0.9
const HOP := Vector2(110.0, -230.0)
const TOUCH := 10.0

var hop_every := HOP_EVERY     # a Larva do Ventre pula mais vezes
var hop_reach := 1.0

var _hop_clock := 0.5
var _touch_cd := 0.0


func _init() -> void:
	title = "ESCÓRIA VIVA"
	sheet = "slag"
	max_hp = 30
	hp = 30
	w = 12
	h = 11
	weight = 0.8
	essence_drop = Vector2i(1, 2)


func body_color() -> Color:
	return Palette.BURN


func telegraphing() -> bool:
	return state == "chase" and is_on_floor() and _hop_clock < 0.25


func think(delta: float) -> void:
	_touch_cd -= delta
	var d := to_player()
	if _touch_cd <= 0.0 and player.alive() and hurt_rect().grow(2.0).intersects(player.hurt_rect()):
		_touch_cd = 0.8
		strike(hurt_rect().grow(4.0), TOUCH, 120.0, {"status": {"burn": 2.0}})
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if sees_player(170.0, 60.0):
				set_state("chase")
		"chase":
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
				_hop_clock -= delta
				if _hop_clock <= 0.0:
					_hop_clock = hop_every
					face_player()
					velocity = Vector2(facing * HOP.x * hop_reach * clampf(absf(d.x) / 80.0, 0.4, 1.0), HOP.y)
					Sfx.play("slag_hop", -12.0)


func _die() -> void:
	var puddle := Hazard.new()
	puddle.player = player
	puddle.style = "molten"
	puddle.delay = 0.0
	puddle.linger = 0.6
	puddle.damage = 8.0
	puddle.width = 26.0
	puddle.height = 8.0
	puddle.position = global_position
	get_parent().add_child.call_deferred(puddle)
	super._die()


func sprite_anim() -> Array:
	if not is_on_floor():
		return ["hop", 0]
	if telegraphing():
		return ["land", 0]
	return ["idle", int(_anim * 4.0)]
