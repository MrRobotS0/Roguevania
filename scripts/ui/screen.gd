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
	# a conta trouxe outro legado (ou saiu): o título mostra o nome e a partida certa
	Meta.account_changed.connect(func() -> void:
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
	elif int(Meta.data["runs"]) > 0:
		var next := Meta.closest_feat_text()
		if next != "":
			lines = [[next, Palette.UI_DIM]]
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
		if (n is OptionsScreen or n is AccountScreen) and n.is_open():
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
			# Enter/Espaço/A; o clique do mouse entra pelo _input, só em cima de um item
			pick(_options[_index][0])
		return
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("attack1"):
		confirmed.emit()


# Mouse no título: passar por cima escolhe, clique entra. Nas telas de morte e
# vitória o clique já vale (é o golpe 1).
var _hit: Array = []

func _input(event: InputEvent) -> void:
	if not visible or mode != "title" or not (event is InputEventMouse):
		return
	if _t < 0.6 or _menu_open() or not Controls.ui_ready():
		return
	var i := Menu.row_at(self, event, _hit)
	if i < 0:
		return
	if event is InputEventMouseMotion:
		if i != _index:
			_index = i
			Sfx.play("ui_move", -12.0)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_index = i
		pick(_options[i][0])


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
# que some para a direita, onde o cenário aparece limpo. Tudo com profundidade:
# poeira desfocada passando perto da lente, o logo como um bloco de ouro que
# gira devagar no ar e os botões como placas (a escolhida sobe e acende).
func _draw_title(size: Vector2) -> void:
	_bokeh(size)
	var dark := Palette.UI_SHADOW
	var clear := dark
	dark.a = 0.82
	clear.a = 0.0
	var edge := 250.0
	draw_rect(Rect2(0, 0, 150, size.y), dark)
	draw_polygon(PackedVector2Array([Vector2(150, 0), Vector2(edge, 0), Vector2(edge, size.y), Vector2(150, size.y)]),
		PackedColorArray([dark, clear, clear, dark]))
	var logo_w := _logo(Vector2(MENU_X - 4, 22))
	_sigil(Vector2(MENU_X - 2, 78), logo_w)
	_title_menu(Vector2(MENU_X, 104))
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


# Movimento do título (giro do logo, poeira) só com os efeitos de tela ligados.
func _motion() -> bool:
	return bool(Options.get_value("postfx"))


# Poeira perto da lente: poucos pontos grandes, fora de foco, passando mais
# rápido que o cenário. É o que diz "isto está na frente de tudo".
func _bokeh(size: Vector2) -> void:
	if not _motion():
		return
	for i in 9:
		var sp := 14.0 + float((i * 37) % 11) * 2.0
		var x := fposmod(float(i * 151) + _t * sp, size.x + 60.0) - 30.0
		var y := fposmod(float(i * 89) + sin(_t * 0.4 + i) * 12.0, size.y)
		var r := 3 + i % 3
		var c := Color(GOLD_FACE, 0.035 + 0.02 * float(i % 2))
		var at := Vector2(x, y).round()
		# disco em degraus de pixel (linha por linha), não quadrado
		for dy in range(-r, r + 1):
			var half := floorf(sqrt(float(r * r - dy * dy)) + 0.3)
			draw_rect(Rect2(at + Vector2(-half, dy), Vector2(half * 2.0 + 1.0, 1)), c)


# MOKSHA como um bloco de ouro maciço: dez camadas da palavra empilhadas para
# trás (do bronze ao escuro), e a direção da pilha balança devagar, como se o
# logo girasse no ar. Na frente, contorno escuro, face funda embaixo e a face
# de ouro, com um brilho que corre pelas letras de tempos em tempos. Cada
# camada sai duas vezes, 2 px para o lado: o traço da fonte é de 1 pixel.
const LOGO_DEPTH := 10


func _logo(at: Vector2) -> float:
	var swing := sin(_t * 0.7) if _motion() else 0.35
	if _motion():
		at.y += roundf(sin(_t * 1.3) * 1.5)
	var w := float(PixelFont.body_width("MOKSHA", 4) + 2)
	for i in range(LOGO_DEPTH, 0, -1):
		var k := float(i) / LOGO_DEPTH
		var off := Vector2(roundf(swing * i * 0.8), i + 1)
		_bold(at + off, BRONZE.lerp(INK, k * 0.85))
	for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(-2, -2), Vector2(2, -2)]:
		_bold(at + d, INK)
	_bold(at + Vector2(0, 1), GOLD_DEEP)
	_logo_face(at)
	return w


# A face da frente, letra por letra: a que está no brilho fica quase branca.
func _logo_face(at: Vector2) -> void:
	if PixelFont.face == "sistema" or not _motion():
		_bold(at, GOLD_FACE)
		return
	var word := "MOKSHA"
	var band := fposmod(_t * 0.45, 2.2) * 5.0 - 1.5   # passa pelas 6 letras e descansa
	var none := Color(0, 0, 0, 0)
	for j in word.length():
		var glow := clampf(1.0 - absf(float(j) - band) / 1.3, 0.0, 1.0)
		var c := GOLD_FACE.lerp(Color("fff6d8"), glow * 0.85)
		var x := at.x + j * PixelFont.BODY_ADVANCE * 4
		PixelFont.body(self, word[j], Vector2(x, at.y), c, 4, none)
		PixelFont.body(self, word[j], Vector2(x + 2, at.y), c, 4, none)


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


# Os botões são placas: face, espessura embaixo e sombra. A escolhida sobe,
# mostra mais da lateral e acende em ouro; as outras ficam rebaixadas e
# apagadas. A subida é suave (mola curta), mas a escolha vale na hora.
const PLATE_W := 124.0
const PLATE_H := 12.0
var _raise: Array = []


func _title_menu(top: Vector2) -> void:
	_hit.clear()
	if _raise.size() != _options.size():
		_raise.resize(_options.size())
		_raise.fill(0.0)
	var dt := get_process_delta_time()
	for i in _options.size():
		var label: String = _options[i][1]
		var y := top.y + i * MENU_STEP
		_hit.append([Rect2(top.x - 16.0, y - 7.0, PLATE_W + 10.0, MENU_STEP), i])
		var selected := i == _index
		_raise[i] = move_toward(float(_raise[i]), 1.0 if selected else 0.0, dt / 0.12)
		var r: float = ease(float(_raise[i]), -2.0)
		_plate(Vector2(top.x - 8.0, y - 7.0), r, selected)
		var color := Palette.GOLD.lerp(GOLD_FACE, r * 0.6) if selected else Palette.UI_DIM
		if _options[i][0] == "update":
			color = Palette.ESSENCE if not selected else Palette.GOLD
		var lift := roundf(r * 2.0)
		PixelFont.body(self, label, Vector2(top.x + roundf(r * 3.0), y - 4 - lift), color)
		if selected:
			# marcador: um losango de 5 px que respira, na ponta da placa
			var bob := 1.0 if int(_t * 3.0) % 2 == 0 else 0.0
			var mx := top.x - 17.0 + bob
			var my := y - lift
			draw_rect(Rect2(mx + 2, my - 3, 1, 1), Palette.GOLD)
			draw_rect(Rect2(mx + 1, my - 2, 3, 1), Palette.GOLD)
			draw_rect(Rect2(mx, my - 1, 5, 1), Palette.GOLD)
			draw_rect(Rect2(mx + 1, my, 3, 1), Palette.GOLD)
			draw_rect(Rect2(mx + 2, my + 1, 1, 1), Palette.GOLD)


func _plate(at: Vector2, r: float, selected: bool) -> void:
	var lift := roundf(r * 2.0)
	var thick := 2.0 + roundf(r * 2.0)
	# rebaixada: só um vulto escuro com a espessura insinuada; escolhida: placa de ouro
	var face := Color(0.06, 0.04, 0.09, 0.28).lerp(Color(0.24, 0.15, 0.06, 0.92), r)
	var side := Color(0.02, 0.01, 0.03, 0.35).lerp(Color(0.42, 0.2, 0.05, 0.95), r)
	var top := at + Vector2(0, -lift)
	if r > 0.05:
		# sombra embaixo (fica onde a placa estava)
		draw_rect(Rect2(at + Vector2(3, PLATE_H + 1), Vector2(PLATE_W - 2, 2)), Color(0, 0, 0, 0.45 * r))
	# lateral (espessura) e face
	draw_rect(Rect2(top + Vector2(0, PLATE_H), Vector2(PLATE_W, thick)), side)
	draw_rect(Rect2(top, Vector2(PLATE_W, PLATE_H)), face)
	if r > 0.05:
		# quina de luz em cima e na esquerda; a direita fica na sombra
		var light := Color(1, 0.9, 0.6, 0.45 * r)
		draw_rect(Rect2(top, Vector2(PLATE_W, 1)), light)
		draw_rect(Rect2(top, Vector2(1, PLATE_H)), Color(light, light.a * 0.6))
		draw_rect(Rect2(top + Vector2(PLATE_W - 1, 1), Vector2(1, PLATE_H - 1)), Color(0, 0, 0, 0.35 * r))
	if selected:
		# a borda de ouro da escolhida
		draw_rect(Rect2(top + Vector2(0, PLATE_H - 1), Vector2(PLATE_W, 1)), Color(Palette.GOLD, 0.55 * r))
