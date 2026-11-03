class_name Deployable
extends Node2D

# O que as habilidades deixam no mundo: armadilha de lâminas, torreta de
# vidro e espírito de cinza. Somem sozinhos depois de `life` segundos.

var kind := "trap"
var owner_player: Player
var damage := 7.0
var params := {}
var life := 8.0
var _t := 0.0
var _clock := 0.0
var _vel := Vector2.ZERO
var _light: PointLight2D


func _ready() -> void:
	z_index = 3
	life = float(params.get("life", life))
	match kind:
		"turret":
			_light = Glow.attach(self, Palette.GLASS, 30.0, 0.6, Vector2(0, -12))
		"spirit":
			_light = Glow.attach(self, Color("ffb36b"), 44.0, 0.9)
	Fx.burst(global_position + Vector2(0, -6), Palette.DUST, 6, 60.0, 0.3)


func _physics_process(delta: float) -> void:
	_t += delta
	_clock -= delta
	if _t >= life or not is_instance_valid(owner_player):
		Fx.burst(global_position + Vector2(0, -6), Palette.DUST, 8, 70.0, 0.4)
		queue_free()
		return
	match kind:
		"trap":
			if _clock <= 0.0:
				_clock = float(params.get("tick", 0.35))
				var w := float(params.get("width", 30.0))
				var zone := Rect2(global_position.x - w * 0.5, global_position.y - 10.0, w, 10.0)
				for e: Enemy in get_tree().get_nodes_in_group("enemies"):
					if e.alive() and not e.ghost and zone.intersects(e.hurt_rect()):
						var d := Damage.make(damage, 1 if e.global_position.x >= global_position.x else -1, 20.0)
						d.source = owner_player
						d.status = {"stun": 0.15}
						e.hurt(d)
		"turret":
			if _clock <= 0.0:
				var target := _nearest(float(params.get("range", 170.0)), true)
				if target:
					_clock = float(params.get("rate", 0.7))
					var p := Projectile.new()
					p.room = owner_player.room
					p.team = "player"
					p.style = "shard"
					p.source = owner_player
					p.position = global_position + Vector2(0, -12)
					p.velocity = (target.center() - p.position).normalized() * 320.0
					p.damage = Damage.make(damage, 1, 40.0)
					p.damage.source = owner_player
					get_parent().add_child(p)
					Sfx.play("bow", -12.0)
		"spirit":
			var target := _nearest(260.0, false)
			var goal := target.center() if target else owner_player.center() + Vector2(-owner_player.facing * 16, -18)
			var speed := float(params.get("speed", 150.0))
			_vel = _vel.lerp((goal - global_position).normalized() * speed, 1.0 - exp(-4.0 * delta))
			global_position += _vel * delta
			if target and _clock <= 0.0 and target.hurt_rect().grow(4.0).has_point(global_position):
				_clock = 0.6
				var d := Damage.make(damage, 1 if _vel.x >= 0.0 else -1, 60.0)
				d.source = owner_player
				d.status = {"burn": 1.5}
				target.hurt(d)
				Fx.burst(global_position, Color("ffb36b"), 6, 80.0, 0.3)
	queue_redraw()


func _nearest(reach: float, need_sight: bool) -> Enemy:
	var best: Enemy = null
	var best_d := reach
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not e.alive() or e.ghost:
			continue
		var d := e.center().distance_to(global_position)
		if d < best_d and (not need_sight or owner_player.room.clear_line(global_position + Vector2(0, -12), e.center())):
			best = e
			best_d = d
	return best


func _draw() -> void:
	var fade := clampf((life - _t) / 0.6, 0.0, 1.0)
	match kind:
		"trap":
			var w := float(params.get("width", 30.0))
			var metal := Palette.BLADE
			metal.a = fade
			draw_rect(Rect2(-w * 0.5, -1, w, 1), Palette.STONE_TOP)
			for i in 5:
				var x := -w * 0.5 + 3 + i * (w - 6) / 4.0
				var up := 2.0 + 2.0 * absf(sin(_t * 9.0 + i))
				draw_rect(Rect2(x, -1 - up, 1, up), metal)
		"turret":
			var c := Palette.GLASS
			c.a = fade
			draw_rect(Rect2(-5, -2, 10, 2), Palette.WOOD)
			draw_rect(Rect2(-1, -9, 2, 7), Palette.WOOD_TOP)
			draw_rect(Rect2(-4, -15, 8, 6), c)
			draw_rect(Rect2(-1, -13, 2, 2), Palette.FLASH)
		"spirit":
			var core := Color("ffb36b")
			core.a = fade
			var bob := sin(_t * 6.0) * 1.5
			draw_rect(Rect2(-3, -4 + bob, 6, 7), core)
			draw_rect(Rect2(-2, -6 + bob, 4, 2), core.lightened(0.3))
			draw_rect(Rect2(1, -2 + bob, 1, 1), Palette.FLASH)
			for i in 3:
				var k := fposmod(_t * 2.0 + i * 0.33, 1.0)
				var ash := core
				ash.a = (1.0 - k) * 0.7 * fade
				draw_rect(Rect2(-2 + i * 2 - _vel.x * 0.02 * k * 10.0, 3 + k * 6.0 + bob, 1, 1), ash)
