extends Node

# Os comandos são registrados aqui em vez do project.godot para ficarem
# legíveis e fáceis de trocar. Teclas físicas: funcionam igual no ABNT.

const ACTIONS := ["left", "right", "up", "down", "jump", "attack", "roll", "heal", "reset", "debug"]

const KEYS := {
	"left": [KEY_A, KEY_LEFT],
	"right": [KEY_D, KEY_RIGHT],
	"up": [KEY_W, KEY_UP],
	"down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE, KEY_K],
	"attack": [KEY_J],
	"roll": [KEY_SHIFT, KEY_L],
	"heal": [KEY_Q],
	"reset": [KEY_F5],
	"debug": [KEY_F1],
}

const PAD_BUTTONS := {
	"left": [JOY_BUTTON_DPAD_LEFT],
	"right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP],
	"down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A],
	"attack": [JOY_BUTTON_X],
	"roll": [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER],
	"heal": [JOY_BUTTON_Y],
	"reset": [JOY_BUTTON_BACK],
}

const PAD_AXES := {
	"left": [JOY_AXIS_LEFT_X, -1.0],
	"right": [JOY_AXIS_LEFT_X, 1.0],
	"up": [JOY_AXIS_LEFT_Y, -1.0],
	"down": [JOY_AXIS_LEFT_Y, 1.0],
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

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", click)
