extends Node

# Os comandos são registrados aqui em vez do project.godot para ficarem
# legíveis e fáceis de trocar. Teclas físicas: funcionam igual no ABNT.

const ACTIONS := ["left", "right", "up", "down", "jump", "attack1", "attack2", "skill1", "skill2",
	"roll", "heal", "interact", "pause", "confirm", "cancel", "reset", "debug", "map"]

const KEYS := {
	"left": [KEY_A, KEY_LEFT],
	"right": [KEY_D, KEY_RIGHT],
	"up": [KEY_W, KEY_UP],
	"down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE, KEY_W],   # W também pula (e continua sendo "cima" nos menus)
	"attack1": [KEY_J],
	"attack2": [KEY_K],
	"skill1": [KEY_Q, KEY_U],   # Q e F (U e I continuam valendo)
	"skill2": [KEY_F, KEY_I],
	"roll": [KEY_SHIFT, KEY_L],
	"heal": [KEY_R],
	"interact": [KEY_E],
	"pause": [KEY_ESCAPE],
	"confirm": [KEY_ENTER, KEY_SPACE, KEY_J, KEY_E],
	"cancel": [KEY_ESCAPE, KEY_BACKSPACE],
	"reset": [KEY_F5],
	"debug": [KEY_F1],
	"map": [KEY_M, KEY_TAB],
}

const PAD_BUTTONS := {
	"left": [JOY_BUTTON_DPAD_LEFT],
	"right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP],
	"down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A],
	"attack1": [JOY_BUTTON_X],
	"attack2": [JOY_BUTTON_Y],
	"skill1": [JOY_BUTTON_LEFT_SHOULDER],
	"skill2": [JOY_BUTTON_RIGHT_SHOULDER],
	"roll": [JOY_BUTTON_B],
	"interact": [JOY_BUTTON_DPAD_UP],
	"pause": [JOY_BUTTON_START],
	"confirm": [JOY_BUTTON_A],
	"cancel": [JOY_BUTTON_B],
	"map": [JOY_BUTTON_BACK],
}

const PAD_AXES := {
	"left": [JOY_AXIS_LEFT_X, -1.0],
	"right": [JOY_AXIS_LEFT_X, 1.0],
	"up": [JOY_AXIS_LEFT_Y, -1.0],
	"down": [JOY_AXIS_LEFT_Y, 1.0],
	"heal": [JOY_AXIS_TRIGGER_LEFT, 1.0],
	"roll": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
}


func _ready() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, 0.4)

	_touch_bridge()

	for action: String in KEYS:
		for code: int in KEYS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = code as Key
			InputMap.action_add_event(action, key)

	for action: String in PAD_BUTTONS:
		for button: int in PAD_BUTTONS[action]:
			var pad := InputEventJoypadButton.new()
			pad.button_index = button as JoyButton
			InputMap.action_add_event(action, pad)

	for action: String in PAD_AXES:
		var motion := InputEventJoypadMotion.new()
		motion.axis = PAD_AXES[action][0]
		motion.axis_value = PAD_AXES[action][1]
		InputMap.action_add_event(action, motion)

	for pair in [["attack1", MOUSE_BUTTON_LEFT], ["attack2", MOUSE_BUTTON_RIGHT]]:
		var click := InputEventMouseButton.new()
		click.button_index = pair[1]
		InputMap.action_add_event(pair[0], click)


# --- dicas de tecla na tela --------------------------------------------------------
# A última coisa que o jogador apertou decide se as dicas mostram teclado ou controle.

const KEY_HINTS := {
	"attack1": "J", "attack2": "K", "skill1": "Q", "skill2": "F", "heal": "R",
	"interact": "E", "confirm": "J/E", "cancel": "ESC", "move": "W/S", "roll": "SHIFT", "jump": "ESPAÇO/W", "map": "M",
	"walk": "A/D", "down": "S",
}
const PAD_HINTS := {
	"attack1": "X", "attack2": "Y", "skill1": "LB", "skill2": "RB", "heal": "LT",
	"interact": "CIMA", "confirm": "A", "cancel": "B", "move": "CIMA/BAIXO", "roll": "B", "jump": "A", "map": "SELECT",
	"walk": "ANALÓGICO", "down": "BAIXO",
}

# Toque (celular): os nomes dos botões da tela em web/shell.html
const TOUCH_HINTS := {
	"attack1": "J", "attack2": "K", "skill1": "U", "skill2": "I", "heal": "CURA",
	"interact": "USAR", "confirm": "PULO", "cancel": "II", "move": "DIRECIONAL", "roll": "ROLAR", "jump": "PULO", "map": "MAPA",
	"walk": "DIRECIONAL", "down": "BAIXO",
}
const TOUCH_HINTS_EN := {
	"heal": "HEAL", "interact": "USE", "confirm": "JUMP", "move": "STICK", "roll": "ROLL", "jump": "JUMP", "map": "MAP",
	"walk": "STICK", "down": "DOWN",
}

var pad_mode := false
var touch_mode := false     # o último comando veio dos botões da tela

# Trava de interface: a tecla que abre ou fecha uma tela não pode valer também
# para a tela que aparece no mesmo quadro (Enter em OPÇÕES ligava a 1ª opção;
# Esc que fechava as opções confirmava COMEÇAR no título).
var _ui_lock := 0


func lock_ui(frames := 3) -> void:
	_ui_lock = maxi(_ui_lock, Engine.get_process_frames() + frames)


func ui_ready() -> bool:
	return Engine.get_process_frames() > _ui_lock


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		pad_mode = true
		touch_mode = false
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		pad_mode = true
		touch_mode = false
	elif event is InputEventKey:
		pad_mode = false
		touch_mode = false
	elif event is InputEventMouseButton and not touch_mode:
		pad_mode = false


func hint(action: String) -> String:
	if touch_mode:
		if Lang.lang == "en" and TOUCH_HINTS_EN.has(action):
			return TOUCH_HINTS_EN[action]
		return TOUCH_HINTS.get(action, "?")
	if not pad_mode and _custom_hints.has(action):
		return _custom_hints[action]
	var table := PAD_HINTS if pad_mode else KEY_HINTS
	return table.get(action, "?")


# --- teclas trocadas pelo jogador (Opções) -------------------------------------------

func apply_bindings(custom: Dictionary) -> void:
	for action: String in KEYS:
		if not InputMap.has_action(action):
			continue
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		var codes: Array = custom.get(action, KEYS[action])
		for code in codes:
			var key := InputEventKey.new()
			key.physical_keycode = int(code) as Key
			InputMap.action_add_event(action, key)
	_refresh_hints(custom)


func key_name(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode).to_upper()
	return "-"


var _custom_hints := {}


func _refresh_hints(custom: Dictionary) -> void:
	_custom_hints.clear()
	for action in custom:
		_custom_hints[action] = key_name(action)


# --- toque (navegador) -----------------------------------------------------------------
# Os botões na tela do celular são HTML (web/shell.html). Eles chamam
# window.mokshaAction(ação, apertado), que vira um InputEventAction de verdade:
# o jogo e os menus recebem igual a uma tecla.

var _touch_cb: JavaScriptObject   # precisa ficar guardado, senão o navegador perde a função
var _pause_cb: JavaScriptObject
signal web_pause

func _touch_bridge() -> void:
	if not OS.has_feature("web"):
		return
	_touch_cb = JavaScriptBridge.create_callback(_on_touch)
	JavaScriptBridge.get_interface("window").mokshaAction = _touch_cb
	# tela só de toque: as dicas já começam com os nomes dos botões
	touch_mode = bool(JavaScriptBridge.eval("matchMedia('(pointer: coarse)').matches", true))
	# No navegador a escala inteira deixa faixas pretas em volta (a janela quase
	# nunca é múltipla de 480x270): lá o jogo estica até preencher a tela.
	get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	# saiu da tela cheia (Esc sem Keyboard Lock): o jogo pausa sozinho
	_pause_cb = JavaScriptBridge.create_callback(func(_args: Array) -> void: web_pause.emit())
	JavaScriptBridge.get_interface("window").mokshaPause = _pause_cb


func _on_touch(args: Array) -> void:
	var action := String(args[0]) if args.size() > 0 else ""
	if not ACTIONS.has(action):
		return
	touch_mode = true
	pad_mode = false
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = bool(args[1]) if args.size() > 1 else true
	ev.strength = 1.0 if ev.pressed else 0.0
	Input.parse_input_event(ev)
