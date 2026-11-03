extends Node

# Progresso permanente (sobrevive à morte): o que foi desbloqueado e as
# estatísticas. Fica em user://legado.save (pasta de dados do Godot).
# Testes trocam o caminho com use_path() — nunca escrevem no save real.

const DEFAULT_PATH := "user://legado.save"

var path := DEFAULT_PATH
var data := {}


func _ready() -> void:
	_load()


func use_path(p: String, wipe := false) -> void:
	path = p
	if wipe and FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_load()


func _defaults() -> Dictionary:
	return {"unlocked": [], "runs": 0, "wins": 0, "best_kills": 0, "deaths": 0}


func _load() -> void:
	data = _defaults()
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		for k in parsed:
			data[k] = parsed[k]


func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


func is_unlocked(id: String) -> bool:
	return data["unlocked"].has(id)


func has_gear(r: Resource) -> bool:
	return r.starter or is_unlocked(r.id)


func unlock(id: String) -> void:
	if not is_unlocked(id):
		data["unlocked"].append(id)
		save()


func record_run(won: bool, kills: int) -> void:
	data["runs"] += 1
	if won:
		data["wins"] += 1
	else:
		data["deaths"] += 1
	data["best_kills"] = maxi(int(data["best_kills"]), kills)
	save()
