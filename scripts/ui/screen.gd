class_name Screen
extends Control

# Telas cheias: título (com opções), morte e vitória. Desenha por cima de
# tudo e espera o jogador escolher ou confirmar.

signal confirmed
signal title_option(id: String)

# Menu do título: só o essencial. O resto mora em EXTRAS (main.gd abre a lista).
const TITLE_OPTIONS := [
	["update", "ATUALIZAR AGORA"],
	["continue", "CONTINUAR"],
	["start", "COMEÇAR"],
	["modes", "MODOS"],
	["options", "OPÇÕES"],
	["extras", "EXTRAS"],
	["quit", "SAIR"],
]
const EXTRAS := [
	["codex", "CÓDICE"],
	["stats", "ESTATÍSTICAS"],
	["controls", "COMANDOS"],
	["credits", "CRÉDITOS"],
]
# só no navegador (moksha.com.br): abrem uma página do site em outra aba
const WEB_EXTRAS := [
	["ranking", "RANKING"],
	["profile", "MEU PERFIL"],
	["feedback", "BUG OU SUGESTÃO"],
]
const WEB_PAGES := {"ranking": "/ranking.html", "feedback": "/conta.html#feedback"}

# ouro do título, em degraus: contorno, relevo e as duas faces da letra
const INK := Color("1a0b04")
const BRONZE := Color("6b3410")
const GOLD_DEEP := Color("d27c22")
const GOLD_FACE := Color("ffd866")
const MENU_X := 34.0
const MENU_STEP := 15.0

var mode := ""
var lines: Array = []       # [[texto, cor]]
var _t := 0.0
var _index := 0
var _options: Array = []
var to_title := false       # depois do final verdadeiro, volta ao título (o Novo Jogo+ mora lá)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# a atualização terminou de baixar com o título aberto: a opção aparece na hora
	Updater.ready_to_apply.connect(func(_v: String) -> void:
		if mode == "title":
			show_title())


func show_title() -> void:
	mode = "title"
	_index = 0
	var saved := Run.saved()
	_options = TITLE_OPTIONS.filter(func(o: Array) -> bool:
		if o[0] == "update":
			return Updater.pending != ""
		if o[0] == "quit":
			return not OS.has_feature("web")    # numa aba, quem fecha é o navegador
		return o[0] != "continue" or not saved.is_empty())
	lines = []
	if not saved.is_empty():
		var where: String = Catalog.STAGE_NAMES.get(saved["stage"], saved["stage"])
		if saved["in_passage"]:
			where = "A Passagem"
		lines = [["PARTIDA SALVA: %s   ·   %s" % [where.to_upper(), _clock(float(saved["time"]))], Palette.GOLD]]
	_open()


func show_death(p: Player, place: String) -> void:
	mode = "death"
	lines = [
		[place.to_upper(), Palette.UI_DIM],
		[("1 INIMIGO DERROTADO   ·   %s" % _clock(Run.time)) if p.kills == 1 else ("%d INIMIGOS DERROTADOS   ·   %s" % [p.kills, _clock(Run.time)]), Palette.UI_TEXT],
		["%d DE ESSÊNCIA SE PERDEU NA CINZA" % p.essence, Palette.ESSENCE],
	]
	_open()


func show_victory(p: Player, true_end := false) -> void:
	mode = "victory"
	to_title = true_end
	lines = [
		["O IMPERADOR CEGO CAIU EM " + _clock(Run.time) + ("   ·   NOVO RECORDE!" if Run.get_meta("record", false) else ""), Palette.UI_TEXT],
		["%d INIMIGOS DERROTADOS" % p.kills, Palette.UI_DIM],
		["CAMINHO: " + " > ".join(PackedStringArray(Run.path.map(func(id: String) -> String: return String(Catalog.STAGE_NAMES.get(id, id)).trim_prefix("O ").trim_prefix("A ").trim_prefix("Os ")))).to_upper(), Palette.GOLD],
	]
	if Run.plus > 0:
		lines.append(["CICLO %d VENCIDO." % Run.plus, Palette.BURN])
		lines.append(["OS PESADELOS RECUAM. AINDA NÃO SOUBERAM QUE ACABOU.", Palette.UI_DIM])
	elif true_end:
		lines.append(["OS DOZE DESCANSAM. VOCÊ NÃO.", Palette.BURN])
		lines.append(["NOVO JOGO+ LIBERADO NO BRASEIRO DA BEIRA.", Palette.GOLD])
	else:
		lines.append([("BRASAS DO DEUS LIBERADAS: %d" % mini(Run.heat + 1, Run.MAX_HEAT)) if Run.heat < Run.MAX_HEAT else "VOCÊ VENCEU COM TODAS AS BRASAS.", Palette.BURN])
		lines.append(["O QUE ACONTECEU COM OS DEUSES CONTINUA SEM RESPOSTA.", Palette.UI_DIM])
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
	if _t < 0.6 or _menu_open() or not Controls.ui_ready():
		return
	if mode == "title":
		if Input.is_action_just_pressed("up"):
			_index = wrapi(_index - 1, 0, _options.size())
			Sfx.play("ui_move", -12.0)
		elif Input.is_action_just_pressed("down"):
			_index = wrapi(_index + 1, 0, _options.size())
			Sfx.play("ui_move", -12.0)
		elif Input.is_action_just_pressed("confirm"):
			# só Enter/Espaço/A: o clique do mouse (que só dá foco à janela) não escolhe nada
			pick(_options[_index][0])
		return
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("attack1"):
		confirmed.emit()


# Também usado pelos testes.
func pick(id: String) -> void:
	Sfx.play("ui_ok", -6.0)
	Controls.lock_ui()
	if id == "start":
		confirmed.emit()
	else:
		title_option.emit(id)


func _draw() -> void:
	var size := get_viewport_rect().size
	var mid := size.x * 0.5
	if mode == "title":
		_draw_title(size)
		return
	var veil := Palette.UI_SHADOW
	veil.a = 0.92
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	match mode:
		"death":
			PixelFont.body_centered(self, "VOCÊ MORREU", Vector2(mid, 74), Palette.HURT, 3)
		"victory":
			PixelFont.body_centered(self, "A JORNADA TERMINOU", Vector2(mid, 70), Palette.GOLD, 2)
	var y := 106.0
	for l in lines:
		PixelFont.body_centered(self, l[0], Vector2(mid, y), l[1])
		y += PixelFont.BODY_LINE
	if _t > 0.6 and int(_t * 2.0) % 2 == 0:
		var next := "%s  RENASCER" if mode == "death" else ("%s  VOLTAR AO TÍTULO" if to_title else "%s  VOLTAR À BEIRA")
		PixelFont.body_centered(self, next % Controls.hint("confirm"), Vector2(mid, size.y - 36), Palette.UI_TEXT)


# Título: uma coluna à esquerda (logo, menu, rodapé) sobre um degradê escuro
# que some para a direita, onde o cenário aparece limpo.
func _draw_title(size: Vector2) -> void:
	var dark := Palette.UI_SHADOW
	var clear := dark
	dark.a = 0.82
	clear.a = 0.0
	var edge := 250.0
	draw_rect(Rect2(0, 0, 150, size.y), dark)
	draw_polygon(PackedVector2Array([Vector2(150, 0), Vector2(edge, 0), Vector2(edge, size.y), Vector2(150, size.y)]),
		PackedColorArray([dark, clear, clear, dark]))
	var logo_w := _logo(Vector2(MENU_X - 4, 26))
	_sigil(Vector2(MENU_X - 2, 72), logo_w)
	_title_menu(Vector2(MENU_X, 98))
	# rodapé: partida salva, dica de teclas e versão, pequenos e apagados
	var foot := size.y - 14.0
	var hint := "%s ESCOLHER   %s CONFIRMAR" % [Controls.hint("move"), Controls.hint("confirm")]
	PixelFont.draw(self, hint, Vector2(MENU_X, foot), Palette.UI_DIM)
	if not lines.is_empty():
		PixelFont.draw(self, String(lines[0][0]), Vector2(MENU_X, foot - 11), Color(lines[0][1]).darkened(0.15))
	var tag := "V" + Updater.version
	PixelFont.draw(self, tag, Vector2(size.x - 8 - PixelFont.width(tag), foot), Palette.UI_DIM)
	# no navegador: o personagem criado no site, em cima da versão
	if Meta.player_name != "":
		var who := Meta.player_name.to_upper()
		PixelFont.draw(self, who, Vector2(size.x - 8 - PixelFont.width(who), foot - 11), Palette.UI_DIM)


# MOKSHA em ouro: contorno escuro, relevo em bronze, face funda embaixo e face
# clara em cima. Cada camada sai duas vezes, 2 px para o lado: a fonte de texto
# tem traço de 1 pixel e, em 4x, o logo ficava fino.
func _logo(at: Vector2) -> float:
	for d in [Vector2(0, 10), Vector2(0, 8), Vector2(0, 6)]:
		_bold(at + d, BRONZE if d.y < 10 else INK)
	for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 4), Vector2(2, 4)]:
		_bold(at + d, INK)
	_bold(at + Vector2(0, 2), GOLD_DEEP)
	_bold(at, GOLD_FACE)
	return float(PixelFont.body_width("MOKSHA", 4) + 2)


func _bold(at: Vector2, color: Color) -> void:
	var none := Color(0, 0, 0, 0)
	PixelFont.body(self, "MOKSHA", at, color, 4, none)
	PixelFont.body(self, "MOKSHA", at + Vector2(2, 0), color, 4, none)


# Selo de pixel embaixo do logo: linha, olho, linha.
func _sigil(at: Vector2, w: float) -> void:
	var gold := Palette.GOLD
	var c := at + Vector2(w * 0.5, 0)
	var line := gold
	line.a = 0.7
	draw_rect(Rect2(at.x, at.y, w * 0.5 - 12, 1), line)
	draw_rect(Rect2(c.x + 12, at.y, w * 0.5 - 12, 1), line)
	draw_rect(Rect2(c.x - 9, at.y - 2, 18, 1), gold)
	draw_rect(Rect2(c.x - 9, at.y + 2, 18, 1), gold)
	draw_rect(Rect2(c.x - 11, at.y - 1, 2, 3), gold)
	draw_rect(Rect2(c.x + 9, at.y - 1, 2, 3), gold)
	draw_rect(Rect2(c.x - 2, at.y - 1, 4, 3), gold)
	draw_rect(Rect2(c.x - 1, at.y, 2, 1), INK)


func _title_menu(top: Vector2) -> void:
	for i in _options.size():
		var label: String = _options[i][1]
		var y := top.y + i * MENU_STEP
		var selected := i == _index
		var x := top.x
		if selected:
			# marcador: um losango de 5 px que respira; o item escolhido anda 3 px
			var bob := 1.0 if int(_t * 3.0) % 2 == 0 else 0.0
			var mx := top.x - 13.0 + bob
			draw_rect(Rect2(mx + 2, y - 3, 1, 1), Palette.GOLD)
			draw_rect(Rect2(mx + 1, y - 2, 3, 1), Palette.GOLD)
			draw_rect(Rect2(mx, y - 1, 5, 1), Palette.GOLD)
			draw_rect(Rect2(mx + 1, y, 3, 1), Palette.GOLD)
			draw_rect(Rect2(mx + 2, y + 1, 1, 1), Palette.GOLD)
			x += 3.0
		var color := Palette.GOLD if selected else Palette.UI_DIM
		if _options[i][0] == "update":
			color = Palette.ESSENCE if not selected else Palette.GOLD
		PixelFont.body(self, label, Vector2(x, y - 4), color)


