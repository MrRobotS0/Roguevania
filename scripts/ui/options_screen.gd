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
	return [
		{"id": "lang", "label": "IDIOMA", "value": Lang.NAMES[Lang.lang]},
		{"id": "master", "label": "VOLUME GERAL", "value": _pct("master")},
		{"id": "music", "label": "MÚSICA", "value": _pct("music")},
		{"id": "sfx", "label": "EFEITOS", "value": _pct("sfx")},
		{"id": "fullscreen", "label": "TELA CHEIA", "value": _yes("fullscreen")},
		{"id": "shake", "label": "TREMOR DE TELA", "value": _pct("shake")},
		{"id": "flashes", "label": "PISCADAS FORTES", "value": "NORMAIS" if Options.flashes() else "REDUZIDAS"},
		{"id": "vibration", "label": "VIBRAÇÃO DO CONTROLE", "value": _yes("vibration")},
		{"id": "timer", "label": "CRONÔMETRO NA TELA", "value": _yes("timer")},
		{"id": "hints", "label": "DICAS", "value": _yes("hints")},
		{"id": "numbers", "label": "NÚMEROS DE DANO", "value": _yes("numbers")},
		{"id": "keys", "label": "TECLAS", "value": ">"},
		{"id": "back", "label": "VOLTAR", "value": ""},
	]


func _pct(key: String) -> String:
	return "%d%%" % roundi(float(Options.get_value(key)) * 100.0)


func _yes(key: String) -> String:
	return "SIM" if Options.get_value(key) else "NÃO"


func _input(event: InputEvent) -> void:
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
		if _page == "keys":
			_page = "main"
			_index = 8
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
		"master", "music", "sfx", "shake":
			var v := float(Options.get_value(id))
			var i := clampi(roundi(v * 10.0) + step, 0, 10)
			Options.set_value(id, STEPS[i])
			Sfx.play("ui_move", -10.0)
		"fullscreen", "flashes", "vibration", "timer", "hints", "numbers":
			Options.set_value(id, not Options.get_value(id))
			Sfx.play("ui_move", -10.0)


func _confirm(id: String) -> void:
	match id:
		"back":
			if _page == "keys":
				_page = "main"
				_index = 11   # volta para TECLAS
			else:
				close()
		"keys":
			_page = "keys"
			_index = 0
		"reset_keys":
			Options.set_value("keys", {})
		"fullscreen", "flashes", "vibration", "timer", "hints", "numbers", "lang":
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
	var line := 15.0
	var head := 30.0
	var foot := 14.0
	var box_h := head + 6.0 + rows.size() * line + 6.0 + foot
	var box := Rect2(roundf((size.x - WIDTH) * 0.5), roundf((size.y - box_h) * 0.5), WIDTH, roundf(box_h))
	# a mesma caixa do Menu: painel escuro, cabeçalho e rodapé em faixas próprias
	draw_rect(box.grow(3), Palette.UI_SHADOW)
	draw_rect(box.grow(1), Menu.FRAME)
	draw_rect(box, Menu.PANEL)
	draw_rect(Rect2(box.position, Vector2(WIDTH, head)), Menu.HEAD)
	draw_rect(Rect2(box.position + Vector2(0, head), Vector2(WIDTH, 1)), Menu.FRAME)
	var x := box.position.x + 12.0
	var y := box.position.y + 8.0
	PixelFont.body(self, "OPÇÕES" if _page == "main" else "TECLAS", Vector2(x, y), Palette.GOLD, 2)
	y = box.position.y + head + 7.0
	for i in rows.size():
		var r: Dictionary = rows[i]
		var selected := i == _index
		if selected:
			draw_rect(Rect2(box.position.x + 4, y - 3, WIDTH - 8, line - 1), Menu.PICK)
			draw_rect(Rect2(box.position.x + 4, y - 3, 2, line - 1), Palette.GOLD)
		var color := Palette.UI_TEXT if selected else Menu.ROW_TEXT
		PixelFont.body(self, r["label"], Vector2(x + 4, y), color)
		var value: String = r["value"]
		if selected and _waiting:
			value = "APERTE UMA TECLA" if int(_t * 3.0) % 2 == 0 else ""
		elif selected and value != "" and value != ">" and _page == "main":
			value = "< " + value + " >"
		var vw := PixelFont.body_width(value)
		PixelFont.body(self, value, Vector2(box.end.x - 12 - vw, y), Palette.GOLD if selected else Menu.SUB)
		y += line
	var hint := "%s ESCOLHER   ←/→ MUDAR   %s VOLTAR" % [Controls.hint("move"), Controls.hint("cancel")]
	var top := box.end.y - foot
	draw_rect(Rect2(box.position.x, top, WIDTH, 1), Menu.FRAME)
	draw_rect(Rect2(box.position.x, top + 1, WIDTH, foot - 1), Menu.HEAD)
	PixelFont.body(self, hint, Vector2(x, top + 1), Menu.SUB)
