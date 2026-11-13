class_name OptionsScreen
extends Control

# Tela de opções. ↑/↓ escolhe a linha, ←/→ muda o valor, confirmar alterna
# ou entra em "teclas". Na lista de teclas, confirmar espera a próxima tecla.

const REBINDABLE := ["left", "right", "up", "down", "jump", "attack1", "attack2", "skill1", "skill2",
	"roll", "heal", "interact", "map"]
const ACTION_NAMES := {
	"left": "ESQUERDA", "right": "DIREITA", "up": "CIMA", "down": "BAIXO", "jump": "PULAR",
	"attack1": "ARMA 1", "attack2": "ARMA 2", "skill1": "HABILIDADE 1", "skill2": "HABILIDADE 2",
	"roll": "ROLAR", "heal": "CURAR", "interact": "USAR", "map": "MAPA",
}
const STEPS := [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
const WIDTH := 330.0

signal closed

var _page := "main"
var _index := 0
var _waiting := false
var _was_paused := false
var _t := 0.0
var _hit: Array = []          # [retângulo, índice] de cada linha (mouse)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	_page = "main"
	_index = 0
	_waiting = false
	_was_paused = get_tree().paused
	get_tree().paused = true
	visible = true
	Controls.lock_ui()
	Sfx.play("ui_open", -8.0)


func close() -> void:
	visible = false
	Controls.lock_ui()
	get_tree().paused = _was_paused
	get_tree().call_group("player", "absorb_input")
	closed.emit()


func _rows() -> Array:
	if _page == "keys":
		var out: Array = []
		for a: String in REBINDABLE:
			out.append({"id": a, "label": ACTION_NAMES[a], "value": Controls.key_name(a)})
		out.append({"id": "reset_keys", "label": "VOLTAR AO PADRÃO", "value": ""})
		out.append({"id": "back", "label": "VOLTAR", "value": ""})
		return out
	var rows: Array = []
	match _page:
		"som":
			rows = [
				{"id": "master", "label": "VOLUME GERAL", "value": _pct("master")},
				{"id": "music", "label": "MÚSICA", "value": _pct("music")},
				{"id": "sfx", "label": "EFEITOS", "value": _pct("sfx")},
			]
		"tela":
			rows = [
				{"id": "font", "label": "FONTE", "value": PixelFont.face_name(PixelFont.face)},
				{"id": "fullscreen", "label": "TELA CHEIA", "value": _yes("fullscreen")},
				{"id": "shake", "label": "TREMOR DE TELA", "value": _pct("shake")},
				{"id": "flashes", "label": "PISCADAS FORTES", "value": "NORMAIS" if Options.flashes() else "REDUZIDAS"},
				{"id": "numbers", "label": "NÚMEROS DE DANO", "value": _yes("numbers")},
				{"id": "minimap", "label": "MINIMAPA", "value": _yes("minimap")},
				{"id": "timer", "label": "CRONÔMETRO NA TELA", "value": _yes("timer")},
			]
			if OS.has_feature("web"):
				# no navegador o jogo já fica sempre em tela cheia (web/shell.html)
				rows = rows.filter(func(r: Dictionary) -> bool: return r["id"] != "fullscreen")
		"jogo":
			rows = [
				{"id": "lang", "label": "IDIOMA", "value": Lang.NAMES[Lang.lang]},
				{"id": "hints", "label": "DICAS", "value": _yes("hints")},
				{"id": "easy_dodge", "label": "ESQUIVA FACILITADA", "value": _yes("easy_dodge")},
				{"id": "colorblind", "label": "AVISOS PARA DALTONISMO", "value": _yes("colorblind")},
				{"id": "vibration", "label": "VIBRAÇÃO DO CONTROLE", "value": _yes("vibration")},
			]
		_:
			# página principal: só as seções, uma linha cada
			return [
				{"id": "som", "label": "SOM", "value": ">"},
				{"id": "tela", "label": "TELA", "value": ">"},
				{"id": "jogo", "label": "JOGO", "value": ">"},
				{"id": "keys", "label": "TECLAS", "value": ">"},
				{"id": "back", "label": "VOLTAR", "value": ""},
			]
	rows.append({"id": "back", "label": "VOLTAR", "value": ""})
	return rows


const SECTIONS := ["som", "tela", "jogo", "keys"]
const SECTION_TITLES := {"main": "OPÇÕES", "som": "SOM", "tela": "TELA", "jogo": "JOGO", "keys": "TECLAS"}


# Volta da seção para a página principal, com a seção marcada.
func _back_to_main() -> void:
	var from := _page
	_page = "main"
	_index = maxi(SECTIONS.find(from), 0)


func _pct(key: String) -> String:
	return "%d%%" % roundi(float(Options.get_value(key)) * 100.0)


func _yes(key: String) -> String:
	return "SIM" if Options.get_value(key) else "NÃO"


func _input(event: InputEvent) -> void:
	if visible and not _waiting and event is InputEventMouse:
		_mouse(event)
		return
	if not visible or not _waiting:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var keys: Dictionary = Options.get_value("keys").duplicate()
		var action: String = REBINDABLE[_index]
		if event.physical_keycode != KEY_ESCAPE:
			keys[action] = [int(event.physical_keycode)]
			Options.set_value("keys", keys)
			Sfx.play("ui_ok", -6.0)
		_waiting = false
		get_viewport().set_input_as_handled()


# Mouse: passar por cima escolhe a linha; clique esquerdo muda para a frente
# (ou entra), direito volta o valor; a roda sobe e desce na lista.
func _mouse(event: InputEvent) -> void:
	if not Controls.ui_ready():
		return
	var i := Menu.row_at(self, event, _hit)
	if event is InputEventMouseMotion:
		if i >= 0 and i != _index:
			_index = i
			Sfx.play("ui_move", -12.0)
		return
	var b := event as InputEventMouseButton
	if b == null or not b.pressed:
		return
	get_viewport().set_input_as_handled()
	var rows := _rows()
	match b.button_index:
		MOUSE_BUTTON_WHEEL_DOWN:
			_index = wrapi(_index + 1, 0, rows.size())
		MOUSE_BUTTON_WHEEL_UP:
			_index = wrapi(_index - 1, 0, rows.size())
		MOUSE_BUTTON_LEFT:
			if i >= 0:
				_index = i
				var id: String = rows[i]["id"]
				if id in ["master", "music", "sfx", "shake"]:
					_change(id, 1)
				else:
					_confirm(id)
		MOUSE_BUTTON_RIGHT:
			if i >= 0:
				_index = i
				_change(rows[i]["id"], -1)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()
	if _waiting or not Controls.ui_ready():
		return
	var rows := _rows()
	if Input.is_action_just_pressed("up"):
		_index = wrapi(_index - 1, 0, rows.size())
		Sfx.play("ui_move", -12.0)
	elif Input.is_action_just_pressed("down"):
		_index = wrapi(_index + 1, 0, rows.size())
		Sfx.play("ui_move", -12.0)
	elif Input.is_action_just_pressed("left"):
		_change(rows[_index]["id"], -1)
	elif Input.is_action_just_pressed("right"):
		_change(rows[_index]["id"], 1)
	elif Input.is_action_just_pressed("confirm"):
		_confirm(rows[_index]["id"])
	elif Input.is_action_just_pressed("cancel"):
		if _page != "main":
			_back_to_main()
		else:
			close()


# Também usado pelos testes.
func change(id: String, step: int) -> void:
	_change(id, step)


func _change(id: String, step: int) -> void:
	match id:
		"lang":
			var i := wrapi(Lang.LANGS.find(Lang.lang) + step, 0, Lang.LANGS.size())
			Options.set_value("lang", Lang.LANGS[i])
			Lang.use(Lang.LANGS[i])
			Sfx.play("ui_move", -10.0)
		"font":
			var f := wrapi(PixelFont.FACES.find(PixelFont.face) + step, 0, PixelFont.FACES.size())
			Options.set_value("font", PixelFont.FACES[f])
			Sfx.play("ui_move", -10.0)
		"master", "music", "sfx", "shake":
			var v := float(Options.get_value(id))
			var i := clampi(roundi(v * 10.0) + step, 0, 10)
			Options.set_value(id, STEPS[i])
			Sfx.play("ui_move", -10.0)
		"fullscreen", "flashes", "vibration", "timer", "hints", "numbers", "minimap", "colorblind", "easy_dodge":
			Options.set_value(id, not Options.get_value(id))
			Sfx.play("ui_move", -10.0)


func _confirm(id: String) -> void:
	match id:
		"back":
			if _page != "main":
				_back_to_main()
			else:
				close()
		"keys", "som", "tela", "jogo":
			_page = id
			_index = 0
			Sfx.play("ui_ok", -8.0)
		"reset_keys":
			Options.set_value("keys", {})
		"fullscreen", "flashes", "vibration", "timer", "hints", "numbers", "minimap", "colorblind", "easy_dodge", "lang", "font":
			_change(id, 1)
		_:
			if _page == "keys" and REBINDABLE.has(id):
				_waiting = true


func _draw() -> void:
	var size := get_viewport_rect().size
	var veil := Palette.UI_SHADOW
	veil.a = 0.82
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	var rows := _rows()
	var wd := 264.0 if _page in ["main", "som"] else WIDTH   # seção curta, caixa estreita
	var line := 12.0 if rows.size() > 12 else 15.0
	var head := 26.0
	var foot := 14.0
	var box_h := head + 6.0 + rows.size() * line + 6.0 + foot
	var box := Rect2(roundf((size.x - wd) * 0.5), roundf((size.y - box_h) * 0.5), wd, roundf(box_h))
	# a mesma caixa do Menu: painel escuro, cabeçalho e rodapé em faixas próprias
	draw_rect(box.grow(3), Palette.UI_SHADOW)
	draw_rect(box.grow(1), Menu.FRAME)
	draw_rect(box, Menu.PANEL)
	draw_rect(Rect2(box.position, Vector2(wd, head)), Menu.HEAD)
	draw_rect(Rect2(box.position + Vector2(0, head), Vector2(wd, 1)), Menu.FRAME)
	var x := box.position.x + 12.0
	var y := box.position.y + 8.0
	PixelFont.body(self, SECTION_TITLES.get(_page, "OPÇÕES"), Vector2(x, y), Palette.GOLD, 2)
	y = box.position.y + head + 7.0
	_hit.clear()
	for i in rows.size():
		var r: Dictionary = rows[i]
		var selected := i == _index
		_hit.append([Rect2(box.position.x + 4, y - 3, wd - 8, line - 1), i])
		if selected:
			draw_rect(Rect2(box.position.x + 4, y - 3, wd - 8, line - 1), Menu.PICK)
			draw_rect(Rect2(box.position.x + 4, y - 3, 2, line - 1), Palette.GOLD)
		var color := Palette.UI_TEXT if selected else Menu.ROW_TEXT
		PixelFont.body(self, r["label"], Vector2(x + 4, y), color)
		var value: String = r["value"]
		if selected and _waiting:
			value = "APERTE UMA TECLA" if int(_t * 3.0) % 2 == 0 else ""
		elif selected and value != "" and value != ">" and _page != "keys":
			value = "< " + value + " >"
		var vw := PixelFont.body_width(value)
		PixelFont.body(self, value, Vector2(box.end.x - 12 - vw, y), Palette.GOLD if selected else Menu.SUB)
		y += line
	var hint := "%s ESCOLHER   ←/→ MUDAR   %s VOLTAR" % [Controls.hint("move"), Controls.hint("cancel")]
	if _page == "main":
		hint = "%s ESCOLHER   %s ENTRAR   %s VOLTAR" % [Controls.hint("move"), Controls.hint("confirm"), Controls.hint("cancel")]
	elif _page == "keys":
		hint = "%s ESCOLHER   %s TROCAR   %s VOLTAR" % [Controls.hint("move"), Controls.hint("confirm"), Controls.hint("cancel")]
	var top := box.end.y - foot
	draw_rect(Rect2(box.position.x, top, wd, 1), Menu.FRAME)
	draw_rect(Rect2(box.position.x, top + 1, wd, foot - 1), Menu.HEAD)
	PixelFont.body(self, hint, Vector2(x, top + 1), Menu.SUB)
