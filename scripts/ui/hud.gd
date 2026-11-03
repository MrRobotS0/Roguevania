class_name Hud
extends Control

# Informação de combate, sempre no mesmo lugar:
#   canto superior esquerdo: vida (com a sombra amarela do dano recente) e frascos
#   canto superior direito:  essência e atributos (F/A/V)
#   rodapé:                  os 4 slots (J K U I) com recarga, e o que dá para usar ali perto
#   centro alto:             faixas (nome do bioma, chefe, tempestade) e avisos curtos
#   base:                    barra do chefe

const BAR := Vector2(96, 7)
const SLOT := 18.0

var player: Player
var boss: Enemy
var _ghost := 1.0
var _ghost_wait := 0.0
var _banner := ""
var _banner_sub := ""
var _banner_t := 99.0
var _toasts: Array = []
var _boss_shown := 0.0
var _t := 0.0


func _ready() -> void:
	Fx.toasted.connect(func(text: String) -> void: _toasts.append([text, 2.4]))
	Fx.bannered.connect(func(title: String, sub: String) -> void:
		_banner = title
		_banner_sub = sub
		_banner_t = 0.0)


func bind(who: Player, boss_node: Enemy = null) -> void:
	player = who
	boss = boss_node
	_ghost = 1.0
	_toasts.clear()
	if boss:
		_boss_shown = float(boss.hp)
	who.health_changed.connect(func(_h: int, _m: int) -> void: _ghost_wait = 0.45)


func _process(delta: float) -> void:
	_t += delta
	_banner_t += delta
	for t in _toasts:
		t[1] -= delta
	_toasts = _toasts.filter(func(t: Array) -> bool: return t[1] > 0.0)
	if player == null or not is_instance_valid(player):
		queue_redraw()
		return
	var ratio := float(player.hp) / player.max_hp
	if ratio > _ghost:
		_ghost = ratio
	_ghost_wait -= delta
	if _ghost_wait <= 0.0:
		_ghost = move_toward(_ghost, ratio, delta * 0.8)
	if is_instance_valid(boss):
		_boss_shown = move_toward(_boss_shown, boss.hp, delta * 300.0)
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	if player and is_instance_valid(player):
		_draw_health(Vector2(8, 8))
		_draw_flasks(Vector2(8, 20))
		_draw_right(size)
		_draw_slots(size)
		_draw_prompt(size)
		if is_instance_valid(boss) and boss.alive() and boss.state != "intro":
			_draw_boss(size)
	_draw_banner(size)
	_draw_toasts(size)


func _draw_health(at: Vector2) -> void:
	var ratio := float(player.hp) / player.max_hp
	draw_rect(Rect2(at - Vector2(2, 2), BAR + Vector2(4, 4)), Palette.UI_SHADOW)
	draw_rect(Rect2(at - Vector2(1, 1), BAR + Vector2(2, 2)), Palette.UI_FRAME)
	draw_rect(Rect2(at, BAR), Palette.UI_BAR_BG)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * _ghost), BAR.y)), Palette.UI_HP_GHOST)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * ratio), BAR.y)), Palette.UI_HP)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * ratio), 1)), Palette.UI_HP.lightened(0.35))
	PixelFont.draw(self, "%d/%d" % [player.hp, player.max_hp], at + Vector2(BAR.x + 6, 1), Palette.UI_TEXT)
	if player.has_status("burn"):
		PixelFont.draw(self, "QUEIMANDO", at + Vector2(BAR.x + 46, 1), Palette.BURN)


func _draw_flasks(at: Vector2) -> void:
	for i in player.max_flasks:
		var p := at + Vector2(i * 9, 0)
		var full := i < player.flasks
		var glass := Palette.UI_DIM if full else Palette.UI_FRAME
		draw_rect(Rect2(p + Vector2(2, 0), Vector2(3, 2)), glass)
		draw_rect(Rect2(p + Vector2(1, 2), Vector2(5, 6)), glass)
		draw_rect(Rect2(p + Vector2(2, 4), Vector2(3, 3)), Palette.UI_HP if full else Palette.UI_BAR_BG)
	PixelFont.draw(self, "Q", at + Vector2(player.max_flasks * 9 + 2, 2), Palette.UI_DIM)


func _draw_right(size: Vector2) -> void:
	var x := size.x - 8.0
	var essence := "%d" % player.essence
	var w := PixelFont.width(essence)
	PixelFont.draw(self, essence, Vector2(x - w, 9), Palette.ESSENCE)
	draw_rect(Rect2(x - w - 8, 9, 4, 4), Palette.ESSENCE)
	var cx := x
	for stat in ["vigor", "astucia", "furia"]:
		var label := "%s%d" % [Combat.STAT_NAMES[stat].substr(0, 1), player.levels[stat]]
		var lw := PixelFont.width(label)
		cx -= lw
		PixelFont.draw(self, label, Vector2(cx, 20), Combat.STAT_COLORS[stat])
		cx -= 8.0


func _draw_slots(size: Vector2) -> void:
	var keys := ["J", "K", "U", "I"]
	var gear := [player.weapon(0), player.weapon(1), player.skill(0), player.skill(1)]
	var start := Vector2(8, size.y - SLOT - 8)
	for i in 4:
		var p := start + Vector2(i * (SLOT + 4) + (6 if i >= 2 else 0), 0)
		var g: Gear = gear[i]
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(SLOT + 2, SLOT + 2)), Palette.UI_SHADOW)
		draw_rect(Rect2(p, Vector2(SLOT, SLOT)), Palette.UI_BAR_BG)
		var frame := Palette.UI_FRAME
		if g:
			frame = Combat.STAT_COLORS[g.stat()].darkened(0.2)
		draw_rect(Rect2(p, Vector2(SLOT, SLOT)), frame, false, 1.0)
		if g:
			_draw_icon(g, p + Vector2(SLOT, SLOT) * 0.5)
			if i >= 2:
				var cd: float = player.skill_cd[i - 2]
				var data: SkillData = g.data
				if cd > 0.0 and data.cooldown > 0.0:
					var k := cd / data.cooldown
					var shade := Palette.UI_SHADOW
					shade.a = 0.75
					draw_rect(Rect2(p.x, p.y + SLOT * (1.0 - k), SLOT, SLOT * k), shade)
					PixelFont.draw_centered(self, "%d" % ceili(cd), p + Vector2(SLOT, SLOT) * 0.5, Palette.UI_TEXT)
		PixelFont.draw(self, keys[i], p + Vector2(1, -7), Palette.UI_DIM)


func _draw_icon(g: Gear, c: Vector2) -> void:
	var col: Color = g.data.color
	if g.is_weapon():
		var data: WeaponData = g.data
		match data.category:
			"bow":
				draw_rect(Rect2(c.x - 3, c.y - 6, 1, 12), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x - 2, c.y - 7, 2, 1), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x - 2, c.y + 6, 2, 1), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x, c.y - 6, 1, 12), Palette.UI_DIM)
				draw_rect(Rect2(c.x - 3, c.y, 8, 1), col)
			_:
				if data.moves.size() > 0 and String(data.moves[0].get("shape", "")) == "smash":
					draw_rect(Rect2(c.x - 1, c.y - 6, 2, 13), Palette.WOOD_TOP)
					draw_rect(Rect2(c.x - 5, c.y - 6, 5, 6), col)
				elif data.moves.size() > 0 and String(data.moves[0].get("shape", "")) == "thrust":
					draw_rect(Rect2(c.x - 6, c.y + 5, 12, 1), Palette.WOOD_TOP)
					draw_line(c + Vector2(-6, 6), c + Vector2(6, -6), Palette.WOOD_TOP, 1.0)
					draw_rect(Rect2(c.x + 4, c.y - 7, 3, 3), col)
				else:
					draw_line(c + Vector2(-5, 5), c + Vector2(5, -5), col, 2.0)
					draw_rect(Rect2(c.x - 5, c.y + 1, 4, 1), Palette.GOLD)
	else:
		var data: SkillData = g.data
		match data.kind:
			"bomb":
				draw_rect(Rect2(c.x - 4, c.y - 3, 8, 8), Palette.STONE_TOP)
				draw_rect(Rect2(c.x - 2, c.y - 1, 4, 4), col)
				draw_rect(Rect2(c.x - 1, c.y - 6, 2, 3), Palette.DANGER)
			"shield":
				draw_rect(Rect2(c.x - 4, c.y - 6, 8, 11), col)
				draw_rect(Rect2(c.x - 2, c.y - 4, 4, 7), col.lightened(0.3))
			_:
				draw_line(c + Vector2(-6, 4), c + Vector2(6, -4), col, 2.0)
	if g.tier > 0:
		PixelFont.draw(self, "+%d" % g.tier, c + Vector2(1, 3), Palette.GOLD)


func _draw_prompt(size: Vector2) -> void:
	var it := player.nearest_interactable()
	if it == null:
		return
	var title: String = "E  " + it.call("prompt")
	var detail: String = it.call("detail")
	var y := size.y - 48.0
	var w := maxf(PixelFont.width(title), PixelFont.width(detail)) + 12.0
	var box := Rect2(size.x * 0.5 - w * 0.5, y - 4, w, 12.0 if detail == "" else 20.0)
	var bg := Palette.UI_SHADOW
	bg.a = 0.75
	draw_rect(box, bg)
	PixelFont.draw_centered(self, title, Vector2(size.x * 0.5, y + 2), Palette.UI_TEXT)
	if detail != "":
		PixelFont.draw_centered(self, detail, Vector2(size.x * 0.5, y + 10), Palette.UI_DIM)


func _draw_boss(size: Vector2) -> void:
	var w := 260.0
	var at := Vector2((size.x - w) * 0.5, size.y - 20.0)
	PixelFont.draw_centered(self, boss.title, Vector2(size.x * 0.5, at.y - 7), Palette.GOLD)
	draw_rect(Rect2(at - Vector2(2, 2), Vector2(w + 4, 9)), Palette.UI_SHADOW)
	draw_rect(Rect2(at - Vector2(1, 1), Vector2(w + 2, 7)), Palette.UI_FRAME)
	draw_rect(Rect2(at, Vector2(w, 5)), Palette.UI_BAR_BG)
	draw_rect(Rect2(at, Vector2(w * _boss_shown / boss.max_hp, 5)), Palette.UI_HP_GHOST)
	draw_rect(Rect2(at, Vector2(w * float(boss.hp) / boss.max_hp, 5)), Color("8f5fd0"))
	draw_rect(Rect2(at.x + w * 0.5, at.y - 1, 1, 7), Palette.UI_TEXT)


func _draw_banner(size: Vector2) -> void:
	if _banner_t > 3.2:
		return
	var a := clampf(minf(_banner_t / 0.3, (3.2 - _banner_t) / 0.6), 0.0, 1.0)
	var c := Palette.UI_TEXT
	c.a = a
	var shadow := Palette.UI_SHADOW
	shadow.a = a
	PixelFont.draw_centered(self, _banner, Vector2(size.x * 0.5, 54), c, 2, shadow)
	if _banner_sub != "":
		var s := Palette.UI_DIM
		s.a = a
		PixelFont.draw_centered(self, _banner_sub, Vector2(size.x * 0.5, 68), s, 1, shadow)


func _draw_toasts(size: Vector2) -> void:
	var y := 86.0
	for t in _toasts:
		var c := Palette.GOLD
		c.a = clampf(t[1] / 0.4, 0.0, 1.0)
		var shadow := Palette.UI_SHADOW
		shadow.a = c.a
		PixelFont.draw_centered(self, t[0], Vector2(size.x * 0.5, y), c, 1, shadow)
		y += 10.0
