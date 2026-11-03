class_name Screen
extends Control

# Telas cheias: título (com opções), morte e vitória. Desenha por cima de
# tudo e espera o jogador escolher ou confirmar.

signal confirmed
signal title_option(id: String)

const TITLE_OPTIONS := [
	["start", "COMEÇAR"],
	["skins", "APARÊNCIA"],
	["options", "OPÇÕES"],
	["controls", "COMANDOS"],
	["quit", "SAIR"],
]

var mode := ""
var lines: Array = []       # [[texto, cor]]
var _t := 0.0
var _index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_title() -> void:
	mode = "title"
	_index = 0
	var stats: Dictionary = Meta.data
	lines = []
	if int(stats["runs"]) > 0:
		lines = [["PARTIDAS %d   ·   VITÓRIAS %d   ·   MAIS ABATES %d" % [stats["runs"], stats["wins"], stats["best_kills"]], Palette.UI_DIM]]
	_open()


func show_death(p: Player, place: String) -> void:
	mode = "death"
	lines = [
		[place.to_upper(), Palette.UI_DIM],
		["%d INIMIGOS DERROTADOS   ·   %s" % [p.kills, _clock(Run.time)], Palette.UI_TEXT],
		["%d DE ESSÊNCIA SE PERDEU NA CINZA" % p.essence, Palette.ESSENCE],
	]
	_open()


func show_victory(p: Player) -> void:
	mode = "victory"
	lines = [
		["O IMPERADOR CEGO CAIU EM " + _clock(Run.time), Palette.UI_TEXT],
		["%d INIMIGOS DERROTADOS" % p.kills, Palette.UI_DIM],
		["CAMINHO: " + " > ".join(PackedStringArray(Run.path.map(func(id: String) -> String: return String(Catalog.STAGE_NAMES.get(id, id)).trim_prefix("O ").trim_prefix("A ").trim_prefix("Os ")))).to_upper(), Palette.GOLD],
		[("BRASAS DO DEUS LIBERADAS: %d" % mini(Run.heat + 1, Run.MAX_HEAT)) if Run.heat < Run.MAX_HEAT else "VOCÊ VENCEU COM TODAS AS BRASAS.", Palette.BURN],
		["O QUE ACONTECEU COM OS DEUSES CONTINUA SEM RESPOSTA.", Palette.UI_DIM],
	]
	_open()


func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _open() -> void:
	_t = 0.0
	visible = true


func close() -> void:
	visible = false
	mode = ""


func _menu_open() -> bool:
	var m := get_tree().get_first_node_in_group("menu")
	if m != null and m.is_open():
		return true
	for n in get_parent().get_children():
		if n is OptionsScreen and n.is_open():
			return true
	return false


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()
	if _t < 0.6 or _menu_open():
		return
	if mode == "title":
		if Input.is_action_just_pressed("up"):
			_index = wrapi(_index - 1, 0, TITLE_OPTIONS.size())
			Sfx.play("ui_move", -12.0)
		elif Input.is_action_just_pressed("down"):
			_index = wrapi(_index + 1, 0, TITLE_OPTIONS.size())
			Sfx.play("ui_move", -12.0)
		elif Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("attack1"):
			pick(TITLE_OPTIONS[_index][0])
		return
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("attack1"):
		confirmed.emit()


# Também usado pelos testes.
func pick(id: String) -> void:
	Sfx.play("ui_ok", -6.0)
	if id == "start":
		confirmed.emit()
	else:
		title_option.emit(id)


func _draw() -> void:
	var size := get_viewport_rect().size
	var veil := Palette.UI_SHADOW
	veil.a = 0.92 if mode != "title" else 0.5
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	var mid := size.x * 0.5
	match mode:
		"title":
			_embers(size)
			PixelFont.body_centered(self, "O LEGADO", Vector2(mid, 58), Palette.UI_TEXT, 3)
			PixelFont.body_centered(self, "DOS DEUSES", Vector2(mid, 86), Palette.GOLD, 3)
			PixelFont.body_centered(self, "OS DEUSES SUMIRAM. SEUS DOMÍNIOS FICARAM.", Vector2(mid, 112), Palette.UI_DIM)
			_title_menu(Vector2(mid, 140))
		"death":
			PixelFont.body_centered(self, "VOCÊ MORREU", Vector2(mid, 74), Palette.HURT, 3)
		"victory":
			PixelFont.body_centered(self, "A JORNADA TERMINOU", Vector2(mid, 70), Palette.GOLD, 2)
	var y := size.y - 34.0 if mode == "title" else 106.0
	for l in lines:
		PixelFont.body_centered(self, l[0], Vector2(mid, y), l[1])
		y += PixelFont.BODY_LINE
	if mode != "title" and _t > 0.6 and int(_t * 2.0) % 2 == 0:
		PixelFont.body_centered(self, "%s  NOVA PARTIDA" % Controls.hint("confirm"), Vector2(mid, size.y - 36), Palette.UI_TEXT)
	if mode == "title":
		PixelFont.draw_centered(self, "NOME, ARTE E SONS PROVISÓRIOS", Vector2(mid, size.y - 12), Palette.UI_FRAME.lightened(0.3))


func _title_menu(top: Vector2) -> void:
	for i in TITLE_OPTIONS.size():
		var label: String = TITLE_OPTIONS[i][1]
		var y := top.y + i * 14.0
		var selected := i == _index
		if selected:
			var w := PixelFont.body_width(label) + 24.0
			var hl := Palette.UI_FRAME
			hl.a = 0.7
			draw_rect(Rect2(roundf(top.x - w * 0.5), y - 6, roundf(w), 13), hl)
			var bob := 1.0 if int(_t * 4.0) % 2 == 0 else 0.0
			PixelFont.body(self, ">", Vector2(roundf(top.x - w * 0.5) + 4 + bob, y - 3), Palette.GOLD)
		PixelFont.body_centered(self, label, Vector2(top.x, y), Palette.UI_TEXT if selected else Palette.UI_DIM)


# Brasas subindo devagar: o deserto ainda queima.
func _embers(size: Vector2) -> void:
	for i in 36:
		var speed := 10.0 + (i * 7) % 13
		var life := fposmod(_t * speed / size.y + i * 0.137, 1.0)
		var x := fposmod(i * 83.0 + sin(_t * 0.7 + i) * 12.0, size.x)
		var y := size.y + 6.0 - life * (size.y + 12.0)
		var c := Palette.BURN if i % 3 else Palette.DANGER
		c.a = sin(life * PI) * 0.8
		draw_rect(Rect2(floorf(x), floorf(y), 1 if i % 4 else 2, 1 if i % 4 else 2), c)
