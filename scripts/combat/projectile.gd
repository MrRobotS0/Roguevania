class_name Projectile
extends Node2D

# Flechas, estilhaços de vidro, lanças arremessadas e bombas.
# team diz em quem acerta: "player" acerta inimigos, "enemy" acerta o herói.
# Um aparo com escudo devolve o projétil (troca de time).

var room: Room
var team := "enemy"
var style := "arrow"          # arrow | shard | javelin | bomb | orb
var velocity := Vector2.ZERO
var gravity := 0.0
var damage: Damage
var pierce := 0
var life := 3.0
var radius := 0.0             # > 0: explode ao tocar ou quando o pavio acaba
var fuse := -1.0
var crit_rule := ""
var crit_mult := 1.75
var source: Actor
var color := Palette.ARROW

var _traveled := 0.0
var _hit: Array = []
var _spin := 0.0


func _ready() -> void:
	z_index = 6
	match style:
		"bomb":
			Glow.attach(self, Palette.BURN, 40.0, 0.8)
		"orb":
			Glow.attach(self, color, 36.0, 0.9)
		"shard", "javelin":
			Glow.attach(self, Palette.GLASS, 26.0, 0.5)
		_:
			if color == Palette.BURN or color.r > 0.9 and color.g < 0.7:
				Glow.attach(self, Palette.BURN, 26.0, 0.6)


func _physics_process(delta: float) -> void:
	life -= delta
	velocity.y += gravity * delta
	var step := velocity * delta
	position += step
	_traveled += step.length()
	_spin += delta * 14.0

	if fuse > 0.0:
		fuse -= delta
		if fuse <= 0.0:
			explode()
			return
	if room.is_solid_at(global_position):
		if radius > 0.0:
			explode()
			return
		else:
			Fx.burst(global_position, color, 4, 60.0, 0.25)
			queue_free()
			return
	if life <= 0.0:
		queue_free()
		return

	var group := "enemies" if team == "player" else "player"
	for t: Actor in get_tree().get_nodes_in_group(group):
		if not t.alive() or _hit.has(t):
			continue
		if not t.hurt_rect().grow(2.0).has_point(global_position):
			continue
		if radius > 0.0:
			explode()
			return
		var d := damage.copy()
		d.dir = 1 if velocity.x >= 0.0 else -1
		if crit_rule != "" and source and Combat.situational_crit(crit_rule, source, t, _traveled):
			d.crit = true
		if d.crit:
			d.amount *= crit_mult
		var landed := t.hurt(d)
		if d.parried:
			_reflect()
			return
		if landed:
			_hit.append(t)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1
		elif d.blocked:
			Fx.burst(global_position, Palette.BLADE, 5, 80.0, 0.2)
			queue_free()
			return
	queue_redraw()


func _reflect() -> void:
	team = "player" if team == "enemy" else "enemy"
	velocity = -velocity * 1.3
	_hit.clear()
	damage.amount *= 2.0
	Fx.burst(global_position, Palette.DANGER, 8, 120.0, 0.25)


func explode() -> void:
	var group := "enemies" if team == "player" else "player"
	for t: Actor in get_tree().get_nodes_in_group(group):
		if t.alive() and t.center().distance_to(global_position) <= radius + t.w * 0.5:
			var d := damage.copy()
			d.dir = 1 if t.global_position.x >= global_position.x else -1
			d.unblockable = true
			t.hurt(d)
	Fx.burst(global_position, Palette.BURN, 22, 160.0, 0.45, 200.0, 3.0, 40.0)
	Fx.burst(global_position, Palette.DUST, 10, 90.0, 0.6, 50.0, 3.0)
	Fx.add_shake(3.5)
	Sfx.play("boom")
	queue_free()


func _draw() -> void:
	var dir := velocity.normalized() if velocity.length() > 1.0 else Vector2.RIGHT
	match style:
		"arrow":
			draw_line(-dir * 9.0, Vector2.ZERO, color, 1.0)
			draw_line(-dir * 9.0, -dir * 7.0 + dir.orthogonal() * 2.0, Palette.UI_DIM, 1.0)
			draw_rect(Rect2(dir - Vector2(1, 1), Vector2(2, 2)), Palette.BLADE)
		"shard":
			var side := dir.orthogonal() * 2.0
			draw_colored_polygon(PackedVector2Array([dir * 5.0, side, -dir * 4.0, -side]), Palette.GLASS)
		"javelin":
			draw_line(-dir * 16.0, Vector2.ZERO, Palette.GLASS, 2.0)
			draw_rect(Rect2(dir * 2.0 - Vector2(2, 2), Vector2(3, 3)), Palette.FLASH)
		"bomb":
			draw_rect(Rect2(-3, -3, 6, 6), Palette.STONE_TOP)
			draw_rect(Rect2(-2, -2, 4, 4), Palette.BURN if int(_spin) % 2 == 0 else Palette.HIT)
			draw_rect(Rect2(-1, -5, 2, 2), Palette.DANGER)
		"orb":
			draw_rect(Rect2(-3, -3, 6, 6), color)
			draw_rect(Rect2(-1, -1, 2, 2), Palette.FLASH)
