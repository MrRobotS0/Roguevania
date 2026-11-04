class_name Hud
extends Control

# Informação de combate, sempre no mesmo lugar:
#   canto superior esquerdo: vida (com a sombra amarela do dano recente) e frascos
#   canto superior direito:  essência e atributos (ícone + nível: espada, olho, escudo)
#   rodapé:                  os 4 slots com recarga, e o que dá para usar ali perto
# As teclas mostradas seguem o último aparelho usado (teclado ou controle).
#   centro alto:             faixas (nome do bioma, chefe, tempestade) e avisos curtos
#   base:                    barra do chefe

const BAR := Vector2(96, 7)
const SLOT := 18.0

# Ícones 7x7: "#" cor cheia, "+" tom de dentro.
const ICONS := {
	"furia": ["......#", ".....#.", "....#..", "#..#...", ".##....", ".##....", "#..#..."],
	"astucia": [".......", "..###..", ".#+++#.", "#++#++#", ".#+++#.", "..###..", "......."],
	"vigor": ["#######", "#+++++#", "#+++++#", "#+++++#", ".#+++#.", "..#+#..", "...#..."],
	"essence": ["...#...", "..#+#..", ".#+++#.", "#+++++#", ".#+++#.", "..#+#..", "...#..."],
	"gold": [".#####.", "#+++++#", "#++#++#", "#+###+#", "#++#++#", "#+++++#", ".#####."],
	"scroll": ["#######", "#+++++#", "#+###+#", "#+++++#", "#+##++#", "#+++++#", "#######"],
	"skull": [".#####.", "#######", "#.#.#.#", "#######", ".#####.", ".#.#.#.", "......."],
}

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
var _theme := HudTheme.of("")
var _theme_from := HudTheme.of("")
var _theme_to := HudTheme.of("")
var _theme_k := 1.0


# Muda a moldura para a do domínio, com uma troca curta (0,3 s).
func use_theme(id: String) -> void:
	_theme_from = _theme
	_theme_to = HudTheme.of(id)
	_theme_k = 0.0


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
	if _theme_k < 1.0:
		_theme_k = move_toward(_theme_k, 1.0, delta / 0.3)
		_theme = HudTheme.blend(_theme_from, _theme_to, _theme_k)
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
		_draw_flasks(Vector2(8, 23))
		_draw_right(size)
		_draw_slots(size)
		_draw_prompt(size)
		if is_instance_valid(boss) and boss.alive() and boss.state != "intro":
			_draw_boss(size)
	if player and is_instance_valid(player):
		_draw_status(size)
	_draw_banner(size)
	_draw_toasts(size)


func _draw_health(at: Vector2) -> void:
	var ratio := float(player.hp) / player.max_hp
	HudTheme.panel(self, Rect2(at, BAR), _theme, _t)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * _ghost), BAR.y)), Palette.UI_HP_GHOST)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * ratio), BAR.y)), Palette.UI_HP)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * ratio), 1)), Palette.UI_HP.lightened(0.35))
	if _theme["style"] == "circuit":
		# no Observatório a vida é medida em células
		var gap: Color = _theme["bg"]
		for x in range(6, int(BAR.x), 6):
			draw_rect(Rect2(at.x + x, at.y, 1, BAR.y), gap)
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
	PixelFont.body(self, Controls.hint("heal"), at + Vector2(player.max_flasks * 9 + 3, 1), Palette.UI_DIM)


func _icon(kind: String, at: Vector2, color: Color) -> void:
	var inner := color.lightened(0.45) if kind in ["essence", "scroll"] else color.darkened(0.45)
	var rows: Array = ICONS[kind]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == ".":
				continue
			draw_rect(Rect2(at + Vector2(x + 1, y + 1), Vector2.ONE), Palette.UI_SHADOW)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				draw_rect(Rect2(at + Vector2(x, y), Vector2.ONE), color if row[x] == "#" else inner)


func _draw_right(size: Vector2) -> void:
	var x := size.x - 8.0
	var essence := "%d" % player.essence
	var w := PixelFont.body_width(essence)
	PixelFont.body(self, essence, Vector2(x - w, 8), Palette.ESSENCE)
	_icon("essence", Vector2(x - w - 11, 8), Palette.ESSENCE)
	var gold := "%d" % player.gold
	var gx := x - w - 22 - PixelFont.body_width(gold)
	PixelFont.body(self, gold, Vector2(gx, 8), Palette.GOLD)
	_icon("gold", Vector2(gx - 11, 8), Palette.GOLD)
	if not player.blueprints.is_empty():
		var n := "%d" % player.blueprints.size()
		var nx := x - PixelFont.body_width(n)
		PixelFont.body(self, n, Vector2(nx, 34), Palette.GLASS)
		_icon("scroll", Vector2(nx - 11, 34), Palette.GLASS)
	var cx := x
	for stat in ["vigor", "astucia", "furia"]:
		var label := "%d" % player.levels[stat]
		var color: Color = Combat.STAT_COLORS[stat]
		cx -= PixelFont.body_width(label)
		PixelFont.body(self, label, Vector2(cx, 21), color)
		cx -= 10.0
		_icon(stat, Vector2(cx, 21), color)
		cx -= 9.0


func _draw_slots(size: Vector2) -> void:
	var keys := [Controls.hint("attack1"), Controls.hint("attack2"), Controls.hint("skill1"), Controls.hint("skill2")]
	var gear := [player.weapon(0), player.weapon(1), player.skill(0), player.skill(1)]
	var start := Vector2(8, size.y - SLOT - 8)
	for i in 4:
		var p := start + Vector2(i * (SLOT + 4) + (6 if i >= 2 else 0), 0)
		var g: Gear = gear[i]
		HudTheme.panel(self, Rect2(p, Vector2(SLOT, SLOT)), _theme, _t, false)
		if g:
			draw_rect(Rect2(p, Vector2(SLOT, SLOT)), Combat.STAT_COLORS[g.stat()].darkened(0.2), false, 1.0)
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
			"bow" when data.shot.get("look", "") == "staff":
				draw_line(c + Vector2(-5, 6), c + Vector2(3, -2), Palette.WOOD_TOP, 1.0)
				draw_rect(Rect2(c.x + 2, c.y - 6, 4, 4), col)
				draw_rect(Rect2(c.x + 3, c.y - 5, 1, 1), Palette.FLASH)
			"bow" when data.shot.get("look", "") == "crossbow":
				draw_rect(Rect2(c.x - 6, c.y, 12, 2), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x + 3, c.y - 5, 1, 11), Palette.UI_DIM)
				draw_rect(Rect2(c.x - 2, c.y - 2, 6, 1), col)
				draw_rect(Rect2(c.x - 2, c.y + 3, 6, 1), col)
			"bow":
				draw_rect(Rect2(c.x - 3, c.y - 6, 1, 12), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x - 2, c.y - 7, 2, 1), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x - 2, c.y + 6, 2, 1), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x, c.y - 6, 1, 12), Palette.UI_DIM)
				draw_rect(Rect2(c.x - 3, c.y, 8, 1), col)
			_:
				var shape := String(data.moves[0].get("shape", "")) if data.moves.size() > 0 else ""
				if shape == "lash":
					for i in 6:
						draw_rect(Rect2(c.x - 6 + i * 2, c.y + 4 - i * 2 + (i % 2), 2, 1), col)
					draw_rect(Rect2(c.x - 6, c.y + 4, 2, 3), Palette.WOOD_TOP)
				elif shape == "spin":
					draw_line(c + Vector2(-4, 6), c + Vector2(2, -5), Palette.WOOD_TOP, 1.0)
					draw_rect(Rect2(c.x - 1, c.y - 7, 7, 2), col)
					draw_rect(Rect2(c.x + 5, c.y - 5, 2, 2), col)
				elif shape == "jab":
					draw_rect(Rect2(c.x - 5, c.y - 3, 5, 6), col)
					draw_rect(Rect2(c.x + 1, c.y - 4, 5, 6), col.lightened(0.2))
					draw_rect(Rect2(c.x + 1, c.y - 4, 5, 1), Palette.FLASH)
				elif shape == "smash":
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
			"trap":
				draw_rect(Rect2(c.x - 6, c.y + 3, 12, 2), Palette.STONE_TOP)
				for i in 4:
					draw_rect(Rect2(c.x - 5 + i * 3, c.y - 2 - (i % 2) * 2, 1, 5 + (i % 2) * 2), col)
			"turret":
				draw_rect(Rect2(c.x - 1, c.y - 1, 2, 7), Palette.WOOD_TOP)
				draw_rect(Rect2(c.x - 4, c.y - 6, 8, 5), col)
				draw_rect(Rect2(c.x - 1, c.y - 5, 2, 2), Palette.FLASH)
			"spirit":
				draw_rect(Rect2(c.x - 3, c.y - 4, 6, 7), col)
				draw_rect(Rect2(c.x - 2, c.y - 6, 4, 2), col.lightened(0.3))
				draw_rect(Rect2(c.x - 1, c.y + 4, 2, 2), col.darkened(0.3))
			"bell":
				draw_rect(Rect2(c.x - 3, c.y - 5, 6, 2), col)
				draw_rect(Rect2(c.x - 4, c.y - 3, 8, 6), col)
				draw_rect(Rect2(c.x - 5, c.y + 3, 10, 1), col.darkened(0.3))
				draw_rect(Rect2(c.x - 1, c.y + 4, 2, 2), Palette.STONE_TOP)
			"roots":
				draw_rect(Rect2(c.x - 6, c.y + 4, 12, 2), Palette.WOOD_TOP)
				for i in 4:
					draw_rect(Rect2(c.x - 5 + i * 3, c.y - 1 - (i % 2) * 3, 2, 5 + (i % 2) * 3), col)
			"meteor":
				draw_line(c + Vector2(-6, -6), c + Vector2(1, 1), col.darkened(0.4), 2.0)
				draw_rect(Rect2(c.x, c.y - 1, 5, 5), col)
				draw_rect(Rect2(c.x + 1, c.y, 2, 2), Palette.FLASH)
			"hook":
				for i in 5:
					draw_rect(Rect2(c.x - 6 + i * 2, c.y + 4 - i * 2, 2, 2), col if i % 2 else col.darkened(0.3))
				draw_rect(Rect2(c.x + 3, c.y - 6, 3, 3), Palette.BLADE)
			_:
				draw_line(c + Vector2(-6, 4), c + Vector2(6, -4), col, 2.0)
	if g.tier > 0:
		PixelFont.draw(self, "+%d" % g.tier, c + Vector2(1, 3), Palette.GOLD)


func _draw_prompt(size: Vector2) -> void:
	var it := player.nearest_interactable()
	if it == null:
		return
	var key := Controls.hint("interact")
	var title: String = it.call("prompt")
	var detail: String = it.call("detail")
	var y := size.y - 56.0
	var key_w := PixelFont.body_width(key) + 6.0
	var w := maxf(PixelFont.body_width(title) + key_w + 6.0, PixelFont.body_width(detail)) + 14.0
	var box := Rect2(roundf(size.x * 0.5 - w * 0.5), y - 5, roundf(w), 17.0 if detail == "" else 29.0)
	HudTheme.panel(self, box, _theme, _t, false)
	var left := box.position.x + 7.0
	draw_rect(Rect2(left - 2, y - 2, key_w, 11), _theme["frame"])
	PixelFont.body(self, key, Vector2(left + 1, y), Palette.GOLD)
	PixelFont.body(self, title, Vector2(left + key_w + 4, y), Palette.UI_TEXT)
	if detail != "":
		PixelFont.body(self, detail, Vector2(left, y + 12), Palette.UI_DIM)


func _draw_boss(size: Vector2) -> void:
	var w := 260.0
	var at := Vector2((size.x - w) * 0.5, size.y - 20.0)
	PixelFont.body_centered(self, boss.title, Vector2(size.x * 0.5, at.y - 9), Palette.GOLD)
	HudTheme.panel(self, Rect2(at, Vector2(w, 5)), _theme, _t)
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
	PixelFont.body_centered(self, _banner, Vector2(size.x * 0.5, 52), c, 2, shadow)
	if _banner_sub != "":
		var s := Palette.UI_DIM
		s.a = a
		PixelFont.body_centered(self, _banner_sub, Vector2(size.x * 0.5, 72), s, 1, shadow)


func _draw_toasts(size: Vector2) -> void:
	var y := 92.0
	for t in _toasts:
		var c := Palette.GOLD
		c.a = clampf(t[1] / 0.4, 0.0, 1.0)
		var shadow := Palette.UI_SHADOW
		shadow.a = c.a
		PixelFont.body_centered(self, t[0], Vector2(size.x * 0.5, y), c, 1, shadow)
		y += PixelFont.BODY_LINE


# Maldição (abaixo dos frascos) e a contagem da Porta do Relógio (no alto).
func _draw_status(size: Vector2) -> void:
	if Options.get_value("timer"):
		var t := Run.time
		var clock := "%d:%02d.%d" % [int(t) / 60, int(t) % 60, int(t * 10.0) % 10]
		PixelFont.body(self, clock, Vector2(size.x - 8 - PixelFont.body_width(clock), size.y - 22), Palette.UI_TEXT)
		var split := "ANDAR %d:%02d" % [int(Run.stage_time) / 60, int(Run.stage_time) % 60]
		PixelFont.draw(self, split, Vector2(size.x - 8 - PixelFont.width(split), size.y - 11), Palette.UI_DIM)
	if player.curse > 0:
		var violet := Color("c08fff")
		_icon("skull", Vector2(8, 36), violet)
		PixelFont.body(self, "%d" % player.curse, Vector2(19, 36), violet)
	for door: TimedDoor in get_tree().get_nodes_in_group("timed_doors"):
		if door.is_open:
			continue
		var left := door.time_left()
		var c := Palette.GOLD if left > 20.0 else Palette.HURT
		var text := "PORTA DO RELÓGIO  %d:%02d" % [int(left) / 60, int(left) % 60] if left > 0.0 else "PORTA DO RELÓGIO FECHADA"
		if left <= 0.0:
			c = Palette.UI_DIM
		PixelFont.draw_centered(self, text, Vector2(size.x * 0.5, 10), c)
		break
