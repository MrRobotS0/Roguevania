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
var tier_scaling := true   # vida cresce com a profundidade do andar (chefes já vêm prontos)
var agile := true          # anda no chão: pula degrau e desce de plataforma atrás do herói
var accel := 1800.0        # quanto demora para mudar de velocidade (dá peso ao corpo)

var _stun := 0.0
var _shown_hp := 0.0
var _hp_visible := 0.0
var _anim := 0.0

# Corpo em sprite (folhas de tools/gen_enemies.py). Sem `sheet`, o inimigo é
# desenhado à mão em draw_body(), como antes.
var sheet := ""
var look := ""               # paleta (vazio = a da própria folha)
var body: Sprite2D
const KICK_TIME := 0.14      # o corpo recua alguns pixels com o golpe e volta
var _kick := 0.0
var _kick_dir := 0.0
var _last_push := Vector2.ZERO
var sink_px := 0.0           # afundado no chão (o assassino emerge da cinza)
var _tex: ImageTexture
var _white: ImageTexture
var _warn: ImageTexture
var _frame_size := Vector2i(32, 32)
var _pal := PackedColorArray()
var _draw_scale := 1.0        # arte pequena desenhada maior (chefes): vem do .json da folha


func _ready() -> void:
	setup_body(4)
	max_hp = roundi(max_hp * (Run.enemy_hp_mult() if tier_scaling else (1.0 + 0.4 * Run.heat) * Run.plus_hp_mult() * Run.guardian_mult()))
	hp = max_hp
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
	var bar := EnemyBar.new()
	bar.enemy = self
	add_child(bar)


func _setup_sprite() -> void:
	if look == "":
		look = sheet
	var pal := PackedColorArray()
	var warn := PackedColorArray()
	if SpriteSheet.meta(sheet).get("color", false):
		# arte pronta em cor cheia: o aviso de golpe esquenta o corpo inteiro
		var hot := Palette.TELEGRAPH
		hot.a = 0.5
		warn = PackedColorArray([hot])
	else:
		pal = EnemyLooks.palette(look)
		warn = EnemyLooks.palette(look, true)
		if elite:
			# elite: contorno em brasa
			pal[1] = Color("8a2a10")
			warn[1] = Color("8a2a10")
	_pal = pal
	_tex = SpriteSheet.texture(sheet, pal)
	_warn = SpriteSheet.texture(sheet, warn)
	_white = SpriteSheet.texture(sheet, pal, true)
	var m := SpriteSheet.meta(sheet)
	_frame_size = Vector2i(int(m.get("w", 32)), int(m.get("h", 32)))
	_draw_scale = float(m.get("draw_scale", 1))
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
	body.scale = _pose() * _draw_scale
	body.position = Vector2(_kick_offset(), 0)
	if flash > 0.0 and Options.flashes():
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
	var img := SpriteSheet.image(sheet, _pal)
	var r := body.region_rect
	for y in range(0, int(r.size.y), 2):
		for x in range(0, int(r.size.x), 2):
			var c := img.get_pixel(int(r.position.x) + x, int(r.position.y) + y)
			if c.a < 0.5:
				continue
			var lx := body.offset.x + x
			if body.flip_h:
				lx = -lx - 2.0
			var k := _draw_scale
			out.append([Rect2(global_position + Vector2(lx, body.offset.y + y) * k, Vector2(2, 2) * k), c])
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
	# conta à parte: o mesmo golpe pode passar por vários inimigos
	var dealt := maxi(1, roundi(d.value() * Run.hero_damage_mult()))
	hp -= dealt
	flash = 0.12 if d.crit else 0.1
	if not d.over_time:
		_kick = KICK_TIME
		_kick_dir = signf(d.dir) if d.dir != 0.0 else 0.0
		_last_push = Vector2(d.dir * (90.0 + d.knock * 0.5), -30.0)
	_hp_visible = 2.5
	apply_statuses(d)
	Fx.number(center() + Vector2(0, -h * 0.5 - 4), dealt, d.crit)
	if not d.over_time:
		velocity.x = d.dir * d.knock / weight
		if d.lift > 0.0:
			velocity.y = -d.lift / weight
		elif uses_gravity and is_on_floor() and d.knock > 60.0:
			velocity.y = -minf(d.knock * 0.4, 110.0) / weight
		Fx.burst(center(), Palette.HIT, 12 if d.crit else 6, 180.0 if d.crit else 120.0)
		Fx.streak(center(), d.dir, Palette.UI_CRIT if d.crit else Palette.SLASH)
		Fx.spray(center() + Vector2(d.dir * w * 0.3, 0), d.dir, Palette.UI_CRIT if d.crit else Palette.HIT, 12 if d.crit else 7, 260.0 if d.crit else 190.0)
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
	# golpe final: a cinza voa para o lado do golpe e o impacto é maior
	Fx.ash(parts, _last_push)
	Fx.burst(center(), Palette.HIT, 14, 240.0, 0.45)
	Fx.spray(center(), signf(_last_push.x), Palette.FLASH, 16, 320.0)
	Fx.impact(center(), Palette.FLASH, true)
	Fx.add_shake(3.5)
	Sfx.play("enemy_die", -4.0)
	if player:
		player.on_kill(self)
	killed.emit(self)
	remove_from_group("enemies")
	queue_free()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	state_time += delta
	flash -= delta
	_kick -= delta
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
		var before := velocity.x
		think(delta)
		# andar ganha aceleração; bote e investida (salto grande) continuam secos
		if uses_gravity and accel > 0.0 and absf(velocity.x - before) < 200.0:
			velocity.x = move_toward(before, velocity.x, accel * delta)
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


# Parede ou buraco à frente: não anda para lá. Quem é ágil, indo atrás do
# herói, pula um degrau de até 2 blocos e se joga da beirada se ele está embaixo.
func blocked(dir: int) -> bool:
	var front := global_position.x + dir * (w * 0.5 + 2.0)
	var wall := room.is_solid_at(Vector2(front, global_position.y - 4.0))
	var floor_ahead := room.is_ground_at(Vector2(front, global_position.y + 4.0))
	var chasing := agile and uses_gravity and player != null and player.alive() and signf(to_player().x) == dir
	if wall:
		if chasing and is_on_floor() and to_player().y < 8.0 				and not room.is_solid_at(Vector2(front, global_position.y - 36.0)) 				and not room.is_solid_at(Vector2(global_position.x, global_position.y - h - 30.0)):
			var step := 2 if room.is_solid_at(Vector2(front, global_position.y - 20.0)) else 1
			velocity.y = -330.0 if step == 1 else -430.0
			return false
		return true
	if not floor_ahead:
		return not (chasing and to_player().y > 20.0 and absf(to_player().x) < 160.0)
	return false


func front_rect(width: float, height: float, lift := 2.0) -> Rect2:
	var x := global_position.x if facing > 0 else global_position.x - width
	return Rect2(x, global_position.y - height - lift, width, height)


# --- desenho ---------------------------------------------------------------------

# Animação comum a todos: respira parado, balança andando, se encolhe ao
# apanhar e cresce no aviso. Passos inteiros de pixel, sem tremido.
func _kick_offset() -> float:
	if _kick <= 0.0:
		return 0.0
	return _kick_dir * ceilf(3.0 * _kick / KICK_TIME)


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
		draw_set_transform(Vector2(_kick_offset(), 0), 0.0, _pose())
	begin_tint()
	draw_body()
	end_tint()
	draw_set_transform(Vector2.ZERO)
	draw_statuses(_anim)
	if elite and int(_anim * 12.0) % 3 == 0:
		var spark := Palette.DANGER
		spark.a = 0.8
		Fx.burst(global_position + Vector2(randf_range(-w * 0.5, w * 0.5), -randf_range(0, h)), spark, 1, 10.0, 0.6, -40.0, 1.0)
	if Fx.debug:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 0.8, 0.2, 0.8), false)
		PixelFont.draw(self, state, Vector2(-10, -h - 18), Palette.UI_TEXT)


func draw_body() -> void:
	pass


# Texto curto sobre a cabeça ("" = nada): desenhado pela EnemyBar, por cima de tudo.
func overhead_text() -> String:
	return ""


func hp_bar_visible() -> bool:
	return _hp_visible > 0.0


func shown_hp() -> float:
	return _shown_hp


func sprite_top() -> float:
	return EnemyBar.sprite_height(_tex, sheet, _frame_size, _draw_scale) if _tex != null else 0.0


# --- golpes prontos para os inimigos ------------------------------------------

func make_hazard(style: String, x: float, delay: float, damage: float, width := 18.0, height := 40.0, quiet := false) -> Hazard:
	var hz := Hazard.new()
	hz.player = player
	hz.style = style
	hz.source = self
	hz.delay = delay
	hz.damage = damage
	hz.width = width
	hz.height = height
	hz.quiet = quiet
	hz.position = Vector2(x, global_position.y)
	get_parent().add_child(hz)
	return hz


func shoot(style: String, from: Vector2, vel: Vector2, damage: float, color: Variant = null, gravity := 0.0, homing := 0.0, life := 3.0) -> Projectile:
	var p := Projectile.new()
	p.room = room
	p.team = "enemy"
	p.style = style
	if color != null:
		p.color = color
	p.source = self
	p.position = from
	p.velocity = vel
	p.gravity = gravity
	p.homing = homing
	p.life = life
	p.damage = Damage.make(damage, facing, 110.0)
	p.damage.source = self
	get_parent().add_child(p)
	return p


# Arco que cai no ponto `target` depois de `fly` segundos.
func lob(style: String, from: Vector2, target: Vector2, fly: float, damage: float, color: Variant = null, gravity := 420.0) -> Projectile:
	var vel := Vector2((target.x - from.x) / fly, (target.y - from.y) / fly - 0.5 * gravity * fly)
	return shoot(style, from, vel, damage, color, gravity, 0.0, fly + 1.5)
