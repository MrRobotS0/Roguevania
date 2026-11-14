class_name Hud
extends Control

# Informação de combate, sempre no mesmo lugar:
#   canto superior esquerdo: vida (com a sombra amarela do dano recente) e frascos
#   canto superior direito:  essência e atributos (ícone + nível: espada, olho, escudo)
#   rodapé:                  os 4 slots com recarga, e o que dá para usar ali perto
# As teclas mostradas seguem o último aparelho usado (teclado ou controle).
#   centro alto:             faixas (nome do bioma, chefe, tempestade) e avisos curtos
#   base:                    barra do chefe

const BAR_W := 120.0
const BOSS_W := 240.0

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
var _skin := HudSkin.of("")
var _below_health := 30.0    # onde termina o bloco da vida (frascos e maldição vêm embaixo)
var _slots_end := 150.0      # onde terminam os slots (a barra do chefe começa depois)


# Troca a pele inteira do HUD pela do domínio (molduras, barras, slots,
# fitas) e as cores, com uma troca curta (0,3 s) nas cores.
func use_theme(id: String) -> void:
	_skin = HudSkin.of(id)
	_theme_from = _theme
	_theme_to = HudTheme.of(id)
	_theme_k = 0.0


func _ready() -> void:
	Fx.toasted.connect(func(text: String) -> void: _toasts.append([text, 2.4]))
	Fx.bannered.connect(func(title: String, sub: String) -> void:
		_banner = title
		_banner_sub = sub
		_banner_t = 0.0)


# O guardião do Modo Waves chega com a arena já montada.
func show_boss(boss_node: Enemy) -> void:
	boss = boss_node
	_boss_shown = float(boss.hp)


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
		var left := _draw_health()
		_draw_flasks(Vector2(left, _below_health))
		_draw_right(size)
		_draw_minimap(size)
		_draw_slots(size)
		_draw_prompt(size)
		_draw_offscreen(size)
		if is_instance_valid(boss) and boss.alive() and boss.state != "intro":
			_draw_boss(size)
	if player and is_instance_valid(player):
		_draw_status(size)
	_draw_banner(size)
	_draw_toasts(size)


# O enfeite do domínio, a moldura da vida e o número ao lado. Devolve o x
# onde a barra começa (os frascos alinham com ela).
func _draw_health() -> float:
	var gem := _skin.part_size("gem")
	_skin.gem(self, Vector2(5, 4))
	var at := Vector2(5 + gem.x + 1, 5)
	var inner := _skin.hbar(self, "bar", at, BAR_W)
	var ratio := float(player.hp) / player.max_hp
	draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * _ghost), inner.size.y)), Palette.UI_HP_GHOST)
	draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * ratio), inner.size.y)), Palette.UI_HP)
	draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * ratio), 1)), Palette.UI_HP.lightened(0.35))
	if _theme["style"] == "circuit":
		# no Observatório a vida é medida em células
		var gap: Color = _theme["bg"]
		for x in range(6, int(inner.size.x), 6):
			draw_rect(Rect2(inner.position.x + x, inner.position.y, 1, inner.size.y), gap)
	var bar_h := _skin.height("bar")
	var text_y := at.y + roundf((bar_h - PixelFont.GLYPH_H) * 0.5)
	PixelFont.draw(self, "%d/%d" % [player.hp, player.max_hp], Vector2(at.x + BAR_W + 4, text_y), _skin.color("text"))
	if player.has_status("burn"):
		PixelFont.draw(self, "QUEIMANDO", Vector2(at.x + BAR_W + 44, text_y), Palette.BURN)
	_below_health = at.y + bar_h + 3
	return at.x


# x onde a coluna da esquerda começa (depois do enfeite do domínio)
func _slot_left() -> float:
	return 5 + _skin.part_size("gem").x + 1


func _draw_flasks(at: Vector2) -> void:
	if Run.mode == Run.WAVES:
		_draw_wave_flasks(at)
		return
	for i in player.max_flasks:
		_draw_flask(at + Vector2(i * 9, 0), 3 if i < player.flasks else 0)
	PixelFont.body(self, Controls.hint("heal"), at + Vector2(player.max_flasks * 9 + 3, 1), Palette.UI_DIM)


# Modo Waves: cada frasco tem dois usos. O que já foi usado uma vez fica pela metade;
# o vazio some, senão a fila só cresce.
func _draw_wave_flasks(at: Vector2) -> void:
	var count := ceili(player.flasks / float(Run.FLASK_USES))
	for i in count:
		var half := i == count - 1 and player.flasks % Run.FLASK_USES == 1
		_draw_flask(at + Vector2(i * 9, 0), 1 if half else 3)
	if count > 0:
		PixelFont.body(self, Controls.hint("heal"), at + Vector2(count * 9 + 3, 1), Palette.UI_DIM)


# Quanto de líquido aparece: 0 = vazio, 1 = pela metade, 3 = cheio.
func _draw_flask(p: Vector2, liquid: int) -> void:
	var glass := _skin.color("text") if liquid > 0 else _skin.color("dim")
	draw_rect(Rect2(p + Vector2(2, 0), Vector2(3, 2)), glass)
	draw_rect(Rect2(p + Vector2(1, 2), Vector2(5, 6)), glass)
	draw_rect(Rect2(p + Vector2(2, 4), Vector2(3, 3)), Palette.UI_BAR_BG)
	if liquid > 0:
		draw_rect(Rect2(p + Vector2(2, 7 - liquid), Vector2(3, liquid)), Palette.UI_HP)


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
	# placa escura atrás dos números do canto: legíveis em qualquer cenário
	var plate := Palette.UI_SHADOW
	plate.a = 0.62
	var plate_h := 44.0 if not player.blueprints.is_empty() else 31.0
	draw_rect(Rect2(size.x - 104.0, 4.0, 100.0, plate_h), plate)
	draw_rect(Rect2(size.x - 104.0, 4.0 + plate_h, 100.0, 1), Color(Menu.FRAME, 0.5))
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
	var cell := _skin.part_size("slot")
	var start := Vector2(6, size.y - cell.y - 5)
	for i in 4:
		var p := start + Vector2(i * (cell.x + 2) + (6 if i >= 2 else 0), 0)
		var g: Gear = gear[i]
		var inner := _skin.slot(self, p)
		var mid := (inner.position + inner.size * 0.5).round()
		if g:
			# a cor do atributo num traço embaixo do ícone, sem cobrir a moldura
			draw_rect(Rect2(mid.x - 4, inner.end.y - 2, 8, 1), Combat.STAT_COLORS[g.stat()])
			_draw_icon(g, mid)
			if i >= 2:
				var cd: float = player.skill_cd[i - 2]
				var data: SkillData = g.data
				if cd > 0.0 and data.cooldown > 0.0:
					var k := cd / data.cooldown
					var shade := Palette.UI_SHADOW
					shade.a = 0.75
					draw_rect(Rect2(inner.position.x, inner.position.y + inner.size.y * (1.0 - k), inner.size.x, inner.size.y * k), shade)
					PixelFont.draw_centered(self, "%d" % ceili(cd), mid, Palette.UI_TEXT)
		PixelFont.draw(self, keys[i], p + Vector2(2, -6), _skin.color("text"))
		_slots_end = p.x + cell.x


func _draw_icon(g: Gear, c: Vector2) -> void:
	var tex := GearIcon.of(g.data)
	if tex:
		draw_texture(tex, (c - Vector2(8, 8)).round())
		return
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


# Ataque vindo de fora da tela: seta vermelha na borda, apontando para quem
# está preparando o golpe ou o tiro (com a visão ampla isso é raro, mas acontece).
func _draw_offscreen(size: Vector2) -> void:
	if not player.is_inside_tree():
		return
	var xf := player.get_viewport().get_canvas_transform()
	var screen := Rect2(Vector2.ZERO, size)
	var mid := size * 0.5
	for e: Enemy in player.get_tree().get_nodes_in_group("enemies"):
		if not e.alive() or not e.telegraphing():
			continue
		var p := xf * e.center()
		if screen.grow(-2.0).has_point(p):
			continue
		if e.global_position.distance_to(player.global_position) > 420.0:
			continue
		var dir := (p - mid).normalized()
		var at := Vector2(clampf(p.x, 12.0, size.x - 12.0), clampf(p.y, 22.0, size.y - 12.0)).round()
		var c := Palette.DANGER if int(e.state_time * 14.0) % 2 == 0 else Palette.FLASH
		var side := Vector2(-dir.y, dir.x)
		var tip := at + dir * 6.0
		var a1 := at - dir * 3.0 + side * 5.0
		var a2 := at - dir * 3.0 - side * 5.0
		draw_colored_polygon(PackedVector2Array([tip + dir * 2.0, a1 + (a1 - at).normalized() * 2.0, a2 + (a2 - at).normalized() * 2.0]), Palette.UI_SHADOW)
		draw_colored_polygon(PackedVector2Array([tip, a1, a2]), c)


func _draw_prompt(size: Vector2) -> void:
	if not player.is_inside_tree():   # herói saindo da cena (troca de fase)
		return
	var it := player.nearest_interactable()
	if it == null:
		return
	var key := Controls.hint("interact")
	var title: String = it.call("prompt")
	var detail: String = it.call("detail")
	var y := size.y - 56.0
	if is_instance_valid(boss) and boss.alive():
		# a barra do chefe tem a fita do nome em cima: o aviso sobe para não cobrir
		y -= _skin.height("header") + 4.0
	var key_w := PixelFont.body_width(key) + 6.0
	# a segunda linha (comparação "FORÇA 34 → 41") vem depois de um 

	var lines := detail.split("
", false)
	var w := PixelFont.body_width(title) + key_w + 6.0
	for l in lines:
		w = maxf(w, PixelFont.body_width(l))
	w = minf(w + 14.0, size.x - 8.0)
	y -= 12.0 * maxf(lines.size() - 1, 0)
	var box := Rect2(roundf(size.x * 0.5 - w * 0.5), y - 5, roundf(w), 17.0 + 12.0 * lines.size())
	_skin.panel(self, box, 1.0, 3.0)
	var left := box.position.x + 7.0
	draw_rect(Rect2(left - 2, y - 2, key_w, 11), _skin.color("dim"))
	PixelFont.body(self, key, Vector2(left + 1, y), _skin.color("text"))
	PixelFont.body(self, title, Vector2(left + key_w + 4, y), Palette.UI_TEXT)
	for i in lines.size():
		var c := Palette.UI_DIM
		if i > 0:
			c = _compare_color(lines[i])
		PixelFont.body(self, lines[i], Vector2(left, y + 12 + 12 * i), c)


# Verde se a arma do chão é mais forte, vermelho se é mais fraca.
func _compare_color(line: String) -> Color:
	var m := RegEx.create_from_string("([0-9]+) → ([0-9]+)").search(line)
	if m == null:
		return Palette.UI_TEXT
	var a := int(m.get_string(1))
	var b := int(m.get_string(2))
	if b > a:
		return Color("8fe07a")
	if b < a:
		return Palette.HURT
	return Palette.UI_TEXT


func _draw_boss(size: Vector2) -> void:
	var w := BOSS_W
	var bh := _skin.height("boss")
	var at := Vector2(maxf(roundf((size.x - w) * 0.5), _slots_end + 12.0), size.y - bh - 4.0)
	var inner := _skin.hbar(self, "boss", at, w)
	var iw := inner.size.x
	draw_rect(Rect2(inner.position, Vector2(roundf(iw * _boss_shown / boss.max_hp), inner.size.y)), Palette.UI_HP_GHOST)
	draw_rect(Rect2(inner.position, Vector2(roundf(iw * float(boss.hp) / boss.max_hp), inner.size.y)), Color("8f5fd0"))
	draw_rect(Rect2(inner.position, Vector2(roundf(iw * float(boss.hp) / boss.max_hp), 1)), Color("8f5fd0").lightened(0.35))
	draw_rect(Rect2(roundf(inner.position.x + iw * 0.5), inner.position.y, 1, inner.size.y), _skin.color("text"))
	# o nome numa fita do domínio, em cima da barra
	_title_ribbon(boss.title, Vector2(at.x + w * 0.5, at.y - _skin.height("header") * 0.5 - 1), _skin.color("text"), 1.0)


# Fita do domínio atrás de um título; `center` é o meio da fita.
func _title_ribbon(text: String, center: Vector2, color: Color, alpha: float, scale := 1) -> void:
	var hp: Dictionary = _skin.meta.get("header", {})
	var caps := float(hp.get("left", 8)) + float(hp.get("right", 8))
	var w := roundf(PixelFont.body_width(text, scale) + caps + 8.0)
	var h := _skin.height("header")
	_skin.hbar(self, "header", (center - Vector2(w, h) * 0.5).round(), w, alpha)
	var shadow := Palette.UI_SHADOW
	shadow.a = alpha
	color.a = alpha
	PixelFont.body_centered(self, text, center, color, scale, shadow)


func _draw_banner(size: Vector2) -> void:
	if _banner_t > 3.2:
		return
	var a := clampf(minf(_banner_t / 0.3, (3.2 - _banner_t) / 0.6), 0.0, 1.0)
	var shadow := Palette.UI_SHADOW
	shadow.a = a
	_title_ribbon(_banner, Vector2(size.x * 0.5, 52), _skin.color("text"), a, 2)
	if _banner_sub != "":
		var s := Palette.UI_TEXT
		s.a = a
		PixelFont.body_centered(self, _banner_sub, Vector2(size.x * 0.5, 52 + _skin.height("header") * 0.5 + 8), s, 1, shadow)


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
	if Run.mode == Run.WAVES and Run.wave > 0:
		PixelFont.body_centered(self, "WAVE %d" % Run.wave, Vector2(size.x * 0.5, 7), Palette.GOLD)
		if Run.wave_left > 0:
			PixelFont.draw(self, "RESTAM %d" % Run.wave_left, Vector2(size.x * 0.5 - PixelFont.width("RESTAM %d" % Run.wave_left) * 0.5, 19), Palette.UI_DIM)
	if Options.get_value("timer"):
		var t := Run.time
		var clock := "%d:%02d.%d" % [int(t) / 60, int(t) % 60, int(t * 10.0) % 10]
		PixelFont.body(self, clock, Vector2(size.x - 8 - PixelFont.body_width(clock), size.y - 22), Palette.UI_TEXT)
		var split := "ANDAR %d:%02d" % [int(Run.stage_time) / 60, int(Run.stage_time) % 60]
		PixelFont.draw(self, split, Vector2(size.x - 8 - PixelFont.width(split), size.y - 11), Palette.UI_DIM)
	if player.curse > 0:
		var violet := Color("c08fff")
		var cy := _below_health + 12.0
		_icon("skull", Vector2(_slot_left(), cy), violet)
		PixelFont.body(self, "%d" % player.curse, Vector2(_slot_left() + 11, cy), violet)
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


# --- minimapa ----------------------------------------------------------------------
# Canto de cima, embaixo do ouro: o pedaço do andar em volta do herói, só o que
# ele já viu (o mesmo do mapa grande, M / Tab). Só nos andares gerados.
# Moldura nas cores do domínio; chão com a borda de cima clara, rocha funda
# escura, plataformas em linha; os inimigos que o herói enxerga em vermelho
# (branco quando vão bater); ícones para saída, baú, mercador, altar e portal;
# a saída pulsa e, quando já foi vista mas está fora do quadro, vira uma seta
# na borda. O herói é uma seta para onde está olhando, com um anel que respira.

const MINI_W := 100.0
const MINI_H := 56.0
const MINI_SCALE := 2
const MINI_ENEMY_RANGE := 15.0   # em blocos: só os inimigos que o herói enxerga


func _draw_minimap(size: Vector2) -> void:
	if not Options.get_value("minimap") or Input.is_action_pressed("map"):
		return
	var level := player.get_parent() as Level
	if level == null or not level.is_inside_tree() or level.room == null or level.kind != "gerada":
		return
	var room := level.room
	var top := (44.0 if not player.blueprints.is_empty() else 31.0) + 11.0
	var box := Rect2(size.x - 104.0, top, MINI_W, MINI_H)
	var th := _theme
	_mini_frame(box, th)
	var s := MINI_SCALE
	var span := Vector2i(int(MINI_W) / s, int(MINI_H) / s)
	var me := player.center() / Room.TILE
	var x0 := clampi(int(me.x) - span.x / 2, 0, maxi(room.cols - span.x, 0))
	var y0 := clampi(int(me.y) - span.y / 2, 0, maxi(room.rows - span.y, 0))
	var origin := box.position + Vector2(maxf((MINI_W - room.cols * s) * 0.5, 0.0), maxf((MINI_H - room.rows * s) * 0.5, 0.0)).floor()
	var light: Color = th["light"]
	var frame: Color = th["frame"]
	var air := Color(th["bg"], 1.0).lerp(light, 0.4)
	air.a = 0.85
	var rock := Color(th["dark"], 0.95)
	var rock_dot := Color(frame.darkened(0.3), 0.9)
	var edge := light.lerp(frame, 0.45)
	var ground := light.lerp(frame, 0.1)
	var plank := Color(light, 0.8)
	for y in range(y0, mini(y0 + span.y, room.rows)):
		for x in range(x0, mini(x0 + span.x, room.cols)):
			if not level.seen(x, y):
				continue
			var at := origin + Vector2((x - x0) * s, (y - y0) * s)
			var cell := Rect2(at, Vector2(s, s))
			if room._solidish(x, y):
				if not room._solidish(x, y - 1):
					draw_rect(cell, ground)
				elif not room._solidish(x + 1, y) or not room._solidish(x - 1, y) or not room._solidish(x, y + 1):
					draw_rect(cell, edge)
				else:
					draw_rect(cell, rock)
					if (x + y) % 3 == 0:
						draw_rect(Rect2(at, Vector2(1, 1)), rock_dot)
			else:
				draw_rect(cell, air)
				if room.cell(x, y) == Room.PLATFORM:
					draw_rect(Rect2(at, Vector2(s, 1)), plank)
	var inner := box.grow(-1.0)
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	# lugares marcados
	for n in level.get_children():
		if not (n is Node2D):
			continue
		var kind := ""
		if n is ExitGate and n.visible:
			kind = "exit"
		elif n is Chest and not n.opened:
			kind = "chest"
		elif n is Merchant:
			kind = "shop"
		elif n is Altar or n is MutationAltar or n is RuneAltar or n is ChallengeStone or n is PactAltar:
			kind = "altar"
		elif n is Portal and n.found:
			kind = "portal"
		if kind == "":
			continue
		var cell := (n as Node2D).global_position / Room.TILE
		if not level.seen(int(cell.x), int(cell.y) - 1):
			continue
		var p := (origin + (cell - Vector2(x0, y0)) * s + Vector2(0, -2)).floor()
		if inner.grow(-2.0).has_point(p):
			_mini_icon(kind, p, pulse)
		elif kind == "exit":
			_mini_edge_arrow(inner, p, Palette.ESSENCE)
	# inimigos que o herói enxerga
	for e in level.enemies():
		var en := e as Enemy
		if en == null or not en.alive():
			continue
		var ecell := en.center() / Room.TILE
		if ecell.distance_to(me) > MINI_ENEMY_RANGE:
			continue
		var ep := (origin + (ecell - Vector2(x0, y0)) * s).floor()
		if not inner.grow(-2.0).has_point(ep):
			continue
		var r := 2.0 if (en.elite or en is Boss) else 1.0
		draw_rect(Rect2(ep - Vector2(r + 1, r + 1), Vector2(r * 2 + 2, r * 2 + 2)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(ep - Vector2(r, r), Vector2(r * 2, r * 2)), Palette.FLASH if en.telegraphing() else Palette.DANGER)
	# o herói
	var hp := (origin + (me - Vector2(x0, y0)) * s).floor()
	var ring := Palette.HURT
	ring.a = 0.2 + 0.4 * (1.0 - pulse)
	draw_arc(hp, 3.5 + 2.5 * pulse, 0.0, TAU, 16, ring, 1.0)
	var f := float(player.facing)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(5 * f, 0), hp + Vector2(-3 * f, -4), hp + Vector2(-1 * f, 0), hp + Vector2(-3 * f, 4)]), Palette.UI_SHADOW)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(4 * f, 0), hp + Vector2(-2 * f, -3), hp + Vector2(0, 0), hp + Vector2(-2 * f, 3)]), Palette.FLASH)
	draw_rect(Rect2(hp - Vector2(1, 1), Vector2(2, 2)), Palette.HURT)


# Moldura nas cores do domínio: fundo, chanfro claro/escuro e os cantos em destaque.
func _mini_frame(box: Rect2, th: Dictionary) -> void:
	var o := box.grow(2.0)
	draw_rect(o, Color(th["dark"], 0.9))
	var bg: Color = th["bg"]
	bg.a = 0.8
	draw_rect(box, bg)
	var light: Color = th["light"]
	var frame: Color = th["frame"]
	draw_rect(Rect2(o.position, Vector2(o.size.x, 1)), Color(light, 0.6))
	draw_rect(Rect2(o.position, Vector2(1, o.size.y)), Color(light, 0.35))
	draw_rect(Rect2(o.position.x, o.end.y - 1, o.size.x, 1), frame)
	draw_rect(Rect2(o.end.x - 1, o.position.y, 1, o.size.y), frame)
	var acc: Color = th["accent"]
	var dark: Color = th["dark"]
	for c: Vector2 in [o.position, Vector2(o.end.x - 3, o.position.y), Vector2(o.position.x, o.end.y - 3), o.end - Vector2(3, 3)]:
		draw_rect(Rect2(c, Vector2(3, 3)), acc)
		draw_rect(Rect2(c + Vector2(1, 1), Vector2(1, 1)), Color(dark, 1.0))


# Ícones pequenos (com contorno escuro) para o que importa no andar.
func _mini_icon(kind: String, p: Vector2, pulse: float) -> void:
	var ink := Color(0, 0, 0, 0.75)
	match kind:
		"exit":
			var glow := Palette.ESSENCE
			glow.a = 0.15 + 0.35 * pulse
			draw_rect(Rect2(p - Vector2(4, 5), Vector2(9, 10)), glow)
			draw_rect(Rect2(p - Vector2(3, 4), Vector2(7, 8)), ink)
			draw_rect(Rect2(p - Vector2(2, 3), Vector2(5, 6)), Palette.ESSENCE)
			draw_rect(Rect2(p - Vector2(1, 2), Vector2(3, 5)), Palette.ESSENCE.darkened(0.6))
		"chest":
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(7, 6)), ink)
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 4)), Palette.GOLD)
			draw_rect(Rect2(p - Vector2(2, 1), Vector2(5, 1)), Palette.GOLD.darkened(0.45))
		"shop":
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(7, 7)), ink)
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Palette.GOLD.lightened(0.3))
			draw_rect(Rect2(p - Vector2(0, 1), Vector2(1, 3)), Palette.GOLD.darkened(0.5))
		"altar":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(4, 0), p + Vector2(0, 4), p + Vector2(-4, 0)]), ink)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3), p + Vector2(3, 0), p + Vector2(0, 3), p + Vector2(-3, 0)]), Color("b8f06a"))
		"portal":
			draw_arc(p, 3.0, 0.0, TAU, 10, ink, 2.0)
			draw_arc(p, 2.5, 0.0, TAU, 10, Portal.CORE, 1.0)


# Seta na borda do quadro apontando a saída que já foi vista mas está longe.
func _mini_edge_arrow(inner: Rect2, target: Vector2, color: Color) -> void:
	var c := inner.get_center()
	var d := target - c
	if d.length() < 0.01:
		return
	d = d.normalized()
	var k := minf((inner.size.x * 0.5 - 4.0) / maxf(absf(d.x), 0.001), (inner.size.y * 0.5 - 4.0) / maxf(absf(d.y), 0.001))
	var at := (c + d * k).floor()
	var side := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([at + d * 4.5, at - d * 3.0 + side * 3.5, at - d * 3.0 - side * 3.5]), Color(0, 0, 0, 0.7))
	draw_colored_polygon(PackedVector2Array([at + d * 3.0, at - d * 2.0 + side * 2.5, at - d * 2.0 - side * 2.5]), Color(color, 0.6 + 0.4 * sin(_t * 5.0)))
