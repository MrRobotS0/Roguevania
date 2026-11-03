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
	"jump": [KEY_SPACE],
	"attack1": [KEY_J],
	"attack2": [KEY_K],
	"skill1": [KEY_U],
	"skill2": [KEY_I],
	"roll": [KEY_SHIFT, KEY_L],
	"heal": [KEY_Q],
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
	"attack1": "J", "attack2": "K", "skill1": "U", "skill2": "I", "heal": "Q",
	"interact": "E", "confirm": "J/E", "cancel": "ESC", "move": "W/S", "roll": "SHIFT", "jump": "ESPAÇO", "map": "M",
}
const PAD_HINTS := {
	"attack1": "X", "attack2": "Y", "skill1": "LB", "skill2": "RB", "heal": "LT",
	"interact": "CIMA", "confirm": "A", "cancel": "B", "move": "CIMA/BAIXO", "roll": "B", "jump": "A", "map": "SELECT",
}

var pad_mode := false


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		pad_mode = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		pad_mode = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad_mode = false


func hint(action: String) -> String:
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
