class_name Smith
extends Enemy

# Ferreiro Cativo: lento e pesado. Ergue o martelo (aviso longo) e desce com
# tudo: acerta na frente e solta faíscas que queimam dos dois lados.
# Firme: golpe comum não interrompe o aviso.

const WALK := 26.0
const REACH := 40.0
const WINDUP := 0.75
const SLAM_DAMAGE := 26.0
const SPLASH := 52.0

var _done := false


func _init() -> void:
	title = "FERREIRO CATIVO"
	sheet = "smith"
	max_hp = 110
	hp = 110
	w = 18
	h = 30
	poise = 0.75
	weight = 2.6
	essence_drop = Vector2i(3, 5)


func body_color() -> Color:
	return Color("8a5a48")


func telegraphing() -> bool:
	return state == "windup"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if sees_player(200.0, 50.0):
				set_state("chase")
		"chase":
			face_player()
			if absf(d.x) < REACH and absf(d.y) < 30.0:
				velocity.x = 0.0
				set_state("windup")
				Sfx.play("swing_heavy", -8.0)
			else:
				velocity.x = 0.0 if blocked(facing) else facing * WALK
		"windup":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time >= WINDUP:
				_done = false
				set_state("slam")
		"slam":
			if not _done:
				_done = true
				strike(front_rect(REACH + 8.0, 26.0), SLAM_DAMAGE, 260.0, {"status": {"burn": 2.0}})
				var splash := Rect2(global_position.x - SPLASH, global_position.y - 10.0, SPLASH * 2.0, 10.0)
				strike(splash, SLAM_DAMAGE * 0.5, 160.0, {"status": {"burn": 2.5}})
				Fx.burst(global_position + Vector2(facing * 24, -2), Palette.BURN, 20, 170.0, 0.5, 300.0, 2.0, 60.0)
				Fx.add_shake(5.0)
				Sfx.play("hammer_slam", -2.0)
			if state_time >= 0.6:
				set_state("chase")


func sprite_anim() -> Array:
	match state:
		"windup":
			return ["windup", 0]
		"slam":
			return ["slam", 0]
		"stun":
			return ["stun", 0]
	if absf(velocity.x) > 5.0:
		return ["walk", int(_anim * 6.0)]
	return ["idle", int(_anim * 2.0)]
