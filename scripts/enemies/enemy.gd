class_name Enemy
extends Actor

# Base dos inimigos. Regra do gênero: todo ataque é AVISADO antes (o corpo
# muda de cor e aparece um "!"), e acertar um inimigo durante o aviso
# interrompe o golpe dele, a não ser que ele tenha firmeza (poise).

signal killed(enemy: Enemy)

const GRAVITY := 1300.0
const MAX_FALL := 450.0

var player: Player
var title := "INIMIGO"
var state := "idle"
var state_time := 0.0
var essence_drop := Vector2i(1, 3)
var poise := 0.0          # 0 = todo golpe interrompe; 1 = nunca
var weight := 1.0         # divide o empurrão
var elite := false
var ghost := false        # true = o herói atravessa (ex.: assassino enterrado)
var uses_gravity := true
var unstoppable := false   # chefes: golpe comum não interrompe

var _stun := 0.0
var _shown_hp := 0.0
var _hp_visible := 0.0
var _anim := 0.0

# Corpo em sprite (folhas de tools/gen_enemies.py). Sem `sheet`, o inimigo é
# desenhado à mão em draw_body(), como antes.
var sheet := ""
var body: Sprite2D
var sink_px := 0.0           # afundado no chão (o assassino emerge da cinza)
var _tex: ImageTexture
var _white: ImageTexture
var _warn: ImageTexture
var _frame_size := Vector2i(32, 32)


func _ready() -> void:
	setup_body(4)
	_shown_hp = hp
	z_index = 4
	add_to_group("enemies")
	if elite:
		max_hp = roundi(max_hp * 2.5)
		hp = max_hp
		_shown_hp = hp
		poise = maxf(poise, 0.6)
		essence_drop *= 4
		outline_color = Color("5a1a10")
		Glow.attach(self, Palette.DANGER, 46.0, 0.45, Vector2(0, -h * 0.5))
	if sheet != "":
		_setup_sprite()


func _setup_sprite() -> void:
	var pal := EnemyLooks.palette(sheet)
	var warn := EnemyLooks.palette(sheet, true)
	if elite:
		# elite: contorno em brasa
		pal[1] = Color("8a2a10")
		warn[1] = Color("8a2a10")
	_tex = SpriteSheet.texture(sheet, pal)
	_warn = SpriteSheet.texture(sheet, warn)
	_white = SpriteSheet.texture(sheet, pal, true)
	var m := SpriteSheet.meta(sheet)
	_frame_size = Vector2i(int(m.get("w", 32)), int(m.get("h", 32)))
	body = Sprite2D.new()
	body.centered = false
	body.region_enabled = true
	body.texture = _tex
	add_child(body)
	_update_sprite()


# Qual animação e quadro mostrar agora: [nome, índice]. Cada inimigo responde.
func sprite_anim() -> Array:
	return ["idle", int(_anim * 3.0)]


func _update_sprite() -> void:
	var pick := sprite_anim()
	var anims: Dictionary = SpriteSheet.meta(sheet)["anims"]
	var a: Dictionary = anims.get(pick[0], anims.values()[0])
	var i := posmod(int(pick[1]), int(a["frames"]))
	var fw := _frame_size.x
	var fh := _frame_size.y
	var cut := clampf(sink_px, 0.0, fh - 1.0)
	body.region_rect = Rect2(i * fw, int(a["row"]) * fh, fw, fh - cut)
	body.offset = Vector2(-fw * 0.5, -fh + 2 + cut)
	body.flip_h = facing < 0
	body.scale = _pose()
	if flash > 0.0:
		body.texture = _white
	elif telegraphing() and int(state_time * 16.0) % 2 == 0:
		body.texture = _warn
	else:
		body.texture = _tex


# Pixels do quadro atual, em coordenadas do mundo (a morte vira cinza com eles).
func sprite_parts() -> Array:
	var out: Array = []
	if body == null or not body.visible:
		return out
	var img := SpriteSheet.image(sheet, EnemyLooks.palette(sheet))
	var r := body.region_rect
	for y in range(0, int(r.size.y), 2):
		for x in range(0, int(r.size.x), 2):
			var c := img.get_pixel(int(r.position.x) + x, int(r.position.y) + y)
			if c.a < 0.5:
				continue
			var lx := body.offset.x + x
			if body.flip_h:
				lx = -lx - 2.0
			out.append([Rect2(global_position + Vector2(lx, body.offset.y + y), Vector2(2, 2)), c])
	return out


func set_state(next: String) -> void:
	state = next
	state_time = 0.0


func telegraphing() -> bool:
	return false


func hurt(d: Damage) -> bool:
	if not alive():
		return false
	if not d.over_time and guard(d):
		d.blocked = true
		return false
	hp -= d.value()
	flash = 0.1
	_hp_visible = 2.5
	apply_statuses(d)
	Fx.number(center() + Vector2(0, -h * 0.5 - 4), d.value(), d.crit)
	if not d.over_time:
		velocity.x = d.dir * d.knock / weight
		if d.lift > 0.0:
			velocity.y = -d.lift / weight
		Fx.burst(center(), Palette.HIT, 12 if d.crit else 6, 180.0 if d.crit else 120.0)
		Fx.streak(center(), d.dir, Palette.UI_CRIT if d.crit else Palette.SLASH)
		Fx.impact(center() + Vector2(-d.dir * 3.0, 0), Palette.UI_CRIT if d.crit else Palette.FLASH, d.crit)
	if hp <= 0:
		_die()
		return true
	if not d.over_time and not unstoppable and (has_status("stun") or randf() >= poise or d.crit):
		stagger(0.45 if d.crit else 0.28)
	return true


# Defesa própria do inimigo (escudo etc.). true = bloqueou.
func guard(_d: Damage) -> bool:
	return false


func stagger(seconds: float) -> void:
	_stun = maxf(seconds, _stun if state == "stun" else 0.0)
	add_status("stun", seconds)
	set_state("stun")
	on_interrupted()


func on_interrupted() -> void:
	pass


func _die() -> void:
	# o corpo se desfaz em cinza, parte por parte, com as cores que tinha
	var parts: Array = sprite_parts()
	for p in last_parts:
		var r: Rect2 = p[0]
		parts.append([Rect2(r.position + global_position, r.size), p[1]])
	if parts.is_empty():
		Fx.burst(center(), body_color(), 18, 170.0, 0.6, 500.0, 3.0, 40.0)
	Fx.ash(parts)
	Fx.burst(center(), Palette.HIT, 10, 220.0, 0.45)
	Fx.add_shake(3.0)
	Sfx.play("enemy_die", -4.0)
	if player:
		player.kills += 1
	killed.emit(self)
	remove_from_group("enemies")
	queue_free()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	state_time += delta
	flash -= delta
	_hp_visible -= delta
	_anim += delta
	_shown_hp = move_toward(_shown_hp, hp, 60.0 * delta)
	tick_statuses(delta)
	if not alive():
		return
	if uses_gravity:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if state == "stun":
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if state_time >= _stun:
			set_state("chase")
	else:
		think(delta)
	move_and_slide()
	if body:
		_update_sprite()
	queue_redraw()


func think(_delta: float) -> void:
	pass


func body_color() -> Color:
	return Palette.GRUNT


func strike(rect: Rect2, amount: float, push := 160.0, extra := {}) -> bool:
	if not player.alive() or not rect.intersects(player.hurt_rect()):
		return false
	var d := Damage.make(amount, facing, push)
	d.source = self
	d.status = extra.get("status", {})
	d.unblockable = extra.get("unblockable", false)
	return player.hurt(d) or d.blocked


# --- sentidos ------------------------------------------------------------------

func eye() -> Vector2:
	return global_position + Vector2(facing * 3, -h + 6)


func to_player() -> Vector2:
	return player.global_position - global_position


func face_player() -> void:
	facing = 1 if to_player().x > 0.0 else -1


func sees_player(range_x: float, range_y: float) -> bool:
	if not player.alive():
		return false
	var d := to_player()
	if absf(d.x) > range_x * Fx.visibility or absf(d.y) > range_y:
		return false
	return room.clear_line(eye(), player.center())


# Parede ou buraco à frente: não anda para lá.
func blocked(dir: int) -> bool:
	var front := global_position.x + dir * (w * 0.5 + 2.0)
	var wall := room.is_solid_at(Vector2(front, global_position.y - 4.0))
	var floor_ahead := room.is_ground_at(Vector2(front, global_position.y + 4.0))
	return wall or not floor_ahead


func front_rect(width: float, height: float, lift := 2.0) -> Rect2:
	var x := global_position.x if facing > 0 else global_position.x - width
	return Rect2(x, global_position.y - height - lift, width, height)


# --- desenho ---------------------------------------------------------------------

# Animação comum a todos: respira parado, balança andando, se encolhe ao
# apanhar e cresce no aviso. Passos inteiros de pixel, sem tremido.
func _pose() -> Vector2:
	var grow := 0.0
	var squeeze := 0.0
	if flash > 0.0:
		grow = -2.0
		squeeze = 2.0
	elif telegraphing():
		grow = 1.0 + float(int(state_time * 10.0) % 2)
	elif absf(velocity.x) > 8.0 and is_on_floor():
		grow = float(int(_anim * 8.0) % 2)
	else:
		grow = float(int(_anim * 2.0) % 2)
	return Vector2((w + squeeze) / w, (h + grow) / h)


func _draw() -> void:
	if body == null:
		draw_set_transform(Vector2.ZERO, 0.0, _pose())
	begin_tint()
	draw_body()
	end_tint()
	draw_set_transform(Vector2.ZERO)
	draw_statuses(_anim)
	if telegraphing() and int(state_time * 12.0) % 2 == 0:
		PixelFont.draw_centered(self, "!", Vector2(0, -h - 9), Palette.DANGER, 2)
	if elite and int(_anim * 12.0) % 3 == 0:
		var spark := Palette.DANGER
		spark.a = 0.8
		Fx.burst(global_position + Vector2(randf_range(-w * 0.5, w * 0.5), -randf_range(0, h)), spark, 1, 10.0, 0.6, -40.0, 1.0)
	if _hp_visible > 0.0 and alive():
		var bw := 16.0 if not elite else 26.0
		var y := -h - 5.0
		draw_rect(Rect2(-bw * 0.5 - 1, y - 1, bw + 2, 4), Palette.UI_SHADOW)
		draw_rect(Rect2(-bw * 0.5, y, bw * _shown_hp / max_hp, 2), Palette.UI_HP_GHOST)
		draw_rect(Rect2(-bw * 0.5, y, bw * float(hp) / max_hp, 2), Palette.UI_HP)
	if Fx.debug:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 0.8, 0.2, 0.8), false)
		PixelFont.draw(self, state, Vector2(-10, -h - 18), Palette.UI_TEXT)


func draw_body() -> void:
	pass
