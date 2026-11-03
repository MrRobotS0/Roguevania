class_name ScriptedInput
extends PlayerInput

# Controle por roteiro: then(["right", "jump"], 10) segura direita+pulo por
# 10 quadros de física, depois passa para o próximo trecho.

var _queue: Array = []


func then(actions: Array, frames: int) -> ScriptedInput:
	_queue.append([actions, frames])
	return self


func wait(frames: int) -> ScriptedInput:
	return then([], frames)


func clear() -> ScriptedInput:
	_queue.clear()
	return self


func busy() -> bool:
	return not _queue.is_empty()


func poll() -> void:
	super.poll()
	if _queue.is_empty():
		return
	_queue[0][1] -= 1
	if _queue[0][1] <= 0:
		_queue.pop_front()


func _read(action: String) -> bool:
	return not _queue.is_empty() and action in _queue[0][0]
