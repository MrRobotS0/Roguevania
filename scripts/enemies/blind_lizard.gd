class_name BlindLizard
extends Grunt

# Cavernas Fundas: nunca viu a luz. Sente o passo e estica a língua.


func _init() -> void:
	super._init()
	title = "LAGARTO CEGO"
	sheet = "blind_lizard"
	max_hp = 50
	hp = 50
	w = 26
	h = 14


const TONGUE := 104.0

var _heard := 0.0
var _tongue_cd := 0.0


func telegraphing() -> bool:
	return state in ["windup", "lick"]


# Cego: só sabe de você se você se mexer perto dele. Parado, ele perde o rastro.
func think(delta: float) -> void:
	_tongue_cd -= delta
	_heard -= delta
	var d := to_player()
	if absf(d.x) < 40.0 and absf(d.y) < 30.0:
		_heard = 1.0
	elif absf(d.x) < 200.0 and absf(d.y) < 70.0 and (absf(player.velocity.x) > 40.0 or absf(player.velocity.y) > 60.0):
		_heard = 1.0
	match state:
		"lick":
			velocity.x = 0.0
			if state_time >= 0.5:
				_hit_done = strike(front_rect(TONGUE, 8.0, 6.0), 12.0, -240.0)
				Sfx.play("whip", -6.0)
				_tongue_cd = 2.4
				set_state("tongue")
			return
		"tongue":
			velocity.x = 0.0
			queue_redraw()
			if state_time >= 0.2:
				set_state("recover")
			return
		"idle":
			if _heard > 0.0:
				set_state("chase")
				return
			if blocked(facing):
				facing = -facing
			velocity.x = facing * WALK
			return
		"chase":
			if _heard <= 0.0:
				set_state("idle")
				return
			if _tongue_cd <= 0.0 and absf(d.x) > 40.0 and absf(d.x) < TONGUE and absf(d.y) < 20.0:
				face_player()
				velocity.x = 0.0
				set_state("lick")
				return
	super.think(delta)


func overhead_text() -> String:
	return "?" if state == "idle" and _heard <= 0.0 and _hp_visible <= 0.0 else ""


func sprite_anim() -> Array:
	match state:
		"lick":
			return ["windup", 0]
		"tongue":
			return ["attack", 0]
	return super.sprite_anim()


func _draw() -> void:
	super._draw()
	if state == "tongue" and alive():
		var from := -6.0 if facing < 0 else 6.0
		draw_rect(Rect2(minf(from, from + facing * TONGUE), -10, TONGUE, 2), Color("d86a8a"))
