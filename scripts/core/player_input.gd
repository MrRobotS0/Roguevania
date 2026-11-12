class_name PlayerInput
extends RefCounted

# O herói lê o controle por aqui, nunca direto do Input. Assim os testes e
# as demonstrações trocam o controle por um roteiro (ScriptedInput).

const ACTIONS := ["left", "right", "up", "down", "jump", "attack1", "attack2", "skill1", "skill2", "roll", "heal", "interact"]

var _held := {}
var _prev := {}


func poll() -> void:
	_prev = _held.duplicate()
	for action: String in ACTIONS:
		_held[action] = _read(action)


func _read(action: String) -> bool:
	return Input.is_action_pressed(action)


# Controle de verdade (teclado, controle, toque)? Roteiros e o robô dizem que não.
func is_live() -> bool:
	return true


func held(action: String) -> bool:
	return _held.get(action, false)


func just(action: String) -> bool:
	return _held.get(action, false) and not _prev.get(action, false)


func released(action: String) -> bool:
	return _prev.get(action, false) and not _held.get(action, false)


func axis() -> float:
	return float(held("right")) - float(held("left"))


# Depois de um menu: o que ainda estiver apertado não conta como "apertou agora".
func sync() -> void:
	for action: String in ACTIONS:
		_held[action] = _read(action)
	_prev = _held.duplicate()
