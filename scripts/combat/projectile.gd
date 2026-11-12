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
var pull := false             # corrente: puxa quem acertar para perto de quem lançou
var homing := 0.0             # > 0: vira na direção do alvo (radianos por segundo)

var _traveled := 0.0
var _hit: Array = []
var _spin := 0.0

# Tiro inimigo tem que ser visto de longe: desenhado maior, com contorno
# escuro, brilho quente e um rastro. O acerto continua do mesmo tamanho.
const TRAIL := 6
const BIG := ["arrow", "shard", "thorn", "glyph", "star", "orb"]
var _trail: Array[Vector2] = []
var _ink := Color(0, 0, 0, 0)     # > 0: desenha a forma toda nesta cor (contorno)
var _size := 1.0


func _hostile() -> bool:
	return team == "enemy"


func _c(original: Color) -> Color:
	return _ink if _ink.a > 0.0 else original


func _ready() -> void:
	z_index = 6
	# guarda o nome de quem atirou: se ele morrer antes do tiro chegar, a morte ainda tem dono
	if damage and damage.label == "" and is_instance_valid(source) and source.get("title") != null:
		damage.label = String(source.get("title"))
	if _hostile():
		_size = 2.0 if style in BIG else 1.0
		if not style in ["bomb", "orb", "wave", "roots", "chain"]:
			Glow.attach(self, Palette.HURT, 30.0, 0.7)
		# clarão na boca do disparo: dá para ver de onde veio
		Fx.burst(global_position, Palette.HURT, 6, 70.0, 0.22, 0.0, 2.0)
		Fx.burst(global_position, Palette.FLASH, 3, 40.0, 0.12, 0.0, 2.0)
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
	if homing > 0.0:
		var target := _homing_target()
		if target:
			var want := (target.center() - global_position).angle()
			var turn := clampf(angle_difference(velocity.angle(), want), -homing * delta, homing * delta)
			velocity = velocity.rotated(turn)
	var step := velocity * delta
	if _hostile():
		_trail.push_front(global_position)
		if _trail.size() > TRAIL:
			_trail.pop_back()
	position += step
	_traveled += step.length()
	_spin += delta * 14.0

	if fuse > 0.0:
		fuse -= delta
		if fuse <= 0.0:
			explode()
			return
	if style == "wave" or style == "roots":
		# a onda corre rente ao chão e só some na parede
		if room.is_solid_at(global_position + Vector2(signf(velocity.x) * 4.0, -2.0)):
			queue_free()
			return
	elif room.is_solid_at(global_position):
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
		if landed and pull and is_instance_valid(source):
			var toward := source.global_position - t.global_position
			t.velocity = Vector2(signf(toward.x) * minf(absf(toward.x) * 6.0, 340.0), -90.0)
			Sfx.play("chain_pull", -4.0)
			queue_free()
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


func _homing_target() -> Actor:
	var group := "enemies" if team == "player" else "player"
	var best: Actor = null
	var best_d := 400.0
	for t: Actor in get_tree().get_nodes_in_group(group):
		if t.alive() and t.center().distance_to(global_position) < best_d:
			best = t
			best_d = t.center().distance_to(global_position)
	return best


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
	if not _hostile():
		_draw_shape(Vector2.ZERO)
		return
	# rastro: quadradinhos que esfriam e somem atrás do tiro
	var n := _trail.size()
	for k in n:
		var p := (_trail[k] - global_position).round()
		var c := Palette.HURT.lerp(Palette.TELEGRAPH, float(k) / maxf(n, 1))
		c.a = 0.75 * (1.0 - float(k) / n)
		var sz := maxf(3.0 - k * 0.4, 1.0) * (_size if _size > 1.0 else 1.0)
		draw_rect(Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), c)
	# contorno escuro: a forma em preto um pixel para cada lado
	_ink = Palette.UI_SHADOW
	for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_draw_shape(o)
	_ink = Color(0, 0, 0, 0)
	_draw_shape(Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)


func _draw_shape(off: Vector2) -> void:
	draw_set_transform(off, 0.0, Vector2(_size, _size))
	var dir := velocity.normalized() if velocity.length() > 1.0 else Vector2.RIGHT
	match style:
		"arrow":
			draw_line(-dir * 9.0, Vector2.ZERO, _c(color), 1.0)
			draw_line(-dir * 9.0, -dir * 7.0 + dir.orthogonal() * 2.0, _c(Palette.UI_DIM), 1.0)
			draw_rect(Rect2(dir - Vector2(1, 1), Vector2(2, 2)), _c(Palette.BLADE))
		"shard":
			var side := dir.orthogonal() * 2.0
			draw_colored_polygon(PackedVector2Array([dir * 5.0, side, -dir * 4.0, -side]), _c(Palette.GLASS))
		"glyph":
			var c := _c(color)
			var turn := _spin * 0.5
			for i in 4:
				var a := turn + i * TAU / 4.0
				draw_rect(Rect2(Vector2(cos(a), sin(a)) * 4.0 - Vector2(1, 1), Vector2(2, 2)), c)
			draw_rect(Rect2(-1, -1, 3, 3), _c(Palette.FLASH))
		"thorn":
			var side := dir.orthogonal() * 1.5
			draw_colored_polygon(PackedVector2Array([dir * 5.0, side, -dir * 3.0, -side]), _c(Color("c8e07a")))
			draw_line(-dir * 3.0, -dir * 6.0, _c(Color("4a7a3a")), 1.0)
		"star":
			var c := _c(color)
			draw_rect(Rect2(-1, -3, 3, 7), c)
			draw_rect(Rect2(-3, -1, 7, 3), c)
			draw_rect(Rect2(0, 0, 1, 1), _c(Palette.FLASH))
		"wave":
			var k := absf(sin(_spin * 0.6))
			for i in 4:
				draw_rect(Rect2(-6 + i * 3, -4 - k * 4.0 + i % 2 * 2, 3, 4 + k * 4.0), _c(Palette.DUST.lightened(0.2)))
			draw_rect(Rect2(-7, 2, 14, 2), _c(Palette.BURN))
		"brick":
			var turn := _spin * 0.25
			draw_set_transform(off, turn, Vector2(_size, _size))
			draw_rect(Rect2(-3, -2, 6, 4), _c(color))
			draw_rect(Rect2(-3, -2, 6, 1), _c(color.lightened(0.3)))
			draw_rect(Rect2(-3, 1, 6, 1), _c(color.darkened(0.4)))
			draw_set_transform(off, 0.0, Vector2(_size, _size))
		"roots":
			var grow := clampf(_traveled / 30.0, 0.3, 1.0)
			for i in 4:
				var tall := (5.0 + float((i * 7) % 5)) * grow
				draw_rect(Rect2(-7 + i * 4, 3 - tall, 2, tall), _c(color if i % 2 else color.darkened(0.35)))
			draw_rect(Rect2(-8, 2, 16, 2), _c(Color("4a3a24")))
		"chain":
			if is_instance_valid(source):
				var back := source.center() - global_position
				var links := int(back.length() / 4.0)
				for i in links:
					var p := back * (float(i) / maxi(links, 1))
					draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 2)), _c(Color("8a8a96") if i % 2 else Color("5a5a62")))
			draw_rect(Rect2(-3, -2, 5, 4), _c(Color("c9c2b0")))
		"javelin":
			draw_line(-dir * 16.0, Vector2.ZERO, _c(Palette.GLASS), 2.0)
			draw_rect(Rect2(dir * 2.0 - Vector2(2, 2), Vector2(3, 3)), _c(Palette.FLASH))
		"bomb":
			draw_rect(Rect2(-3, -3, 6, 6), _c(Palette.STONE_TOP))
			draw_rect(Rect2(-2, -2, 4, 4), _c(Palette.BURN if int(_spin) % 2 == 0 else Palette.HIT))
			draw_rect(Rect2(-1, -5, 2, 2), _c(Palette.DANGER))
		"orb":
			draw_rect(Rect2(-3, -3, 6, 6), _c(color))
			draw_rect(Rect2(-1, -1, 2, 2), _c(Palette.FLASH))
