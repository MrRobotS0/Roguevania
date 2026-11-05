class_name BossInsatiable
extends Boss

# O insaciável: O deus que devorava comeu até a própria fome.


func _init() -> void:
	title = "O INSACIÁVEL"
	subtitle = "O DEUS QUE DEVORAVA COMEU ATÉ A PRÓPRIA FOME"
	defeat_text = "A GOELA FECHOU. O VENTRE PAROU DE BATER"
	sheet = "boss_insatiable"
	max_hp = 1800
	hp = 1800
	w = 34
	h = 52
	weight = 5.0
	walk_speed = 90.0
	keep_distance = 0.0
	sounds = {"melee": "hammer_slam", "rain": "pillar"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/larva.gd", "count": 2},
		{"type": "custom", "windup": 0.7, "recover": 0.8, "time": 2.0},
		{"type": "melee", "windup": 0.55, "reach": 80.0, "height": 50.0, "damage": 26.0, "max_range": 110.0},
		{"type": "leap", "windup": 0.6, "radius": 70.0, "damage": 24.0},
		{"type": "rain", "windup": 0.6, "style": "bile", "count": 5, "height": 56.0, "predict": true, "damage": 18.0},
	]
	moves2 = [
		{"type": "volley", "windup": 0.5, "style": "orb", "count": 9, "arc": true, "damage": 15.0, "color": Color("c8d040")},
		{"type": "custom", "windup": 0.5, "recover": 0.6, "time": 2.4},
	]


const PULL := 150.0
const EAT_HEAL := 70


# Inspira: puxa você e as próprias larvas. Larva que chega na boca vira vida para
# ele, e no fim ele morde quem estiver perto. Mate as larvas antes e corra.
func custom_update(m: Dictionary, delta: float) -> bool:
	var t := float(m.get("time", 2.0)) * _tm()
	velocity.x = 0.0
	var dir := 1.0 if global_position.x > player.global_position.x else -1.0
	player.inhale = dir * PULL
	if int(state_time * 20.0) % 2 == 0:
		var from := Vector2(global_position.x - dir * randf_range(70.0, 150.0), global_position.y - randf_range(6.0, 50.0))
		Fx.burst(from, Color("c8d040"), 1, 30.0, 0.3)
	for e in get_tree().get_nodes_in_group("larvas"):
		if e is Larva and e.alive():
			e.velocity.x = signf(global_position.x - e.global_position.x) * 190.0
			if e.global_position.distance_to(global_position) < maxf(float(w) * 0.5, 26.0):
				hp = mini(hp + EAT_HEAL, max_hp)
				_shown_hp = hp
				Fx.number(center() + Vector2(0, -h * 0.5), EAT_HEAL, false)
				Fx.burst(center(), Color("c8d040"), 14, 140.0, 0.4)
				Sfx.play("wolf_bite", -2.0)
				e.remove_from_group("enemies")
				e.remove_from_group("larvas")
				e.queue_free()
	if state_time >= t:
		player.inhale = 0.0
		strike(Rect2(global_position.x - 70.0, global_position.y - h, 140.0, h), 28.0, 300.0)
		Fx.add_shake(5.0)
		Sfx.play("hammer_slam")
		return true
	return false


func custom_abort() -> void:
	player.inhale = 0.0


func _die() -> void:
	player.inhale = 0.0
	super._die()
