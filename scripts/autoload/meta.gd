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
	return {"unlocked": [], "runs": 0, "wins": 0, "best_kills": 0, "deaths": 0, "skin": "andarilho",
		"blueprints": [], "runes": [], "heat": 0,
		"stats": {}, "daily": {}, "best_time": 0.0, "lore": [], "intro_seen": false,
		"hints": []}


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


# --- aparências ---------------------------------------------------------------------

func feat_done(feat: String) -> bool:
	match feat:
		"boss":
			return int(data["wins"]) >= 1
		"deaths10":
			return int(data["deaths"]) >= 10
	return false


func has_skin(s: SkinData) -> bool:
	match s.unlock:
		"essence":
			return is_unlocked(s.id)
		"feat":
			return feat_done(s.feat)
	return true


func current_skin() -> SkinData:
	var s := Catalog.skin(String(data["skin"]))
	return s if has_skin(s) else Catalog.skin("andarilho")


func wear(id: String) -> void:
	data["skin"] = id
	save()


# --- runas (poderes que ficam para sempre) e plantas -------------------------------

func has_rune(id: String) -> bool:
	return data["runes"].has(id)


func add_rune(id: String) -> void:
	if not has_rune(id):
		data["runes"].append(id)
		save()


func knows(id: String) -> bool:
	return data["blueprints"].has(id)


func learn(ids: Array) -> int:
	var fresh := 0
	for id in ids:
		if not knows(id):
			data["blueprints"].append(id)
			fresh += 1
	save()
	return fresh


# Vitória numa dificuldade libera a próxima.
func record_heat_win(level: int) -> void:
	if level + 1 > int(data["heat"]):
		data["heat"] = mini(level + 1, 4)
		save()


# --- estatísticas, recorde e desafio do dia -------------------------------------------

func _add(table: String, key: String, n: int) -> void:
	var st: Dictionary = data["stats"]
	if not st.has(table):
		st[table] = {}
	st[table][key] = int(st[table].get(key, 0)) + n


# Chamado no fim de toda partida (morte, vitória ou desistência).
func record_stats(won: bool) -> bool:
	for k in Run.kills_by:
		_add("kills_by", k, Run.kills_by[k])
	for k in Run.weapon_kills:
		_add("weapon_kills", k, Run.weapon_kills[k])
	if not won and Run.killer != "":
		_add("deaths_by", Run.killer, 1)
	_add("reached", Run.stage_id, 1)
	var st: Dictionary = data["stats"]
	st["deepest"] = maxi(int(st.get("deepest", 0)), Run.path.size())
	st["time"] = float(st.get("time", 0.0)) + Run.time
	var record := false
	if won and (float(data["best_time"]) <= 0.0 or Run.time < float(data["best_time"])):
		data["best_time"] = Run.time
		record = true
	if Run.daily != "":
		var day: Dictionary = data["daily"].get(Run.daily, {"tries": 0, "best_depth": 0, "best_time": 0.0})
		day["tries"] = int(day["tries"]) + 1
		day["best_depth"] = maxi(int(day["best_depth"]), Run.path.size())
		if won and (float(day["best_time"]) <= 0.0 or Run.time < float(day["best_time"])):
			day["best_time"] = Run.time
		data["daily"][Run.daily] = day
	save()
	return record


func stats_text() -> String:
	var st: Dictionary = data["stats"]
	var lines := PackedStringArray()
	var clock := func(t: float) -> String: return "%d:%02d" % [int(t) / 60, int(t) % 60]
	lines.append("PARTIDAS %d · VITÓRIAS %d · MORTES %d" % [data["runs"], data["wins"], data["deaths"]])
	lines.append("ANDAR MAIS FUNDO: %d DE 8 · TEMPO JOGADO: %s" % [int(st.get("deepest", 0)), clock.call(float(st.get("time", 0.0)))])
	if float(data["best_time"]) > 0.0:
		lines.append("MELHOR VITÓRIA: %s" % clock.call(float(data["best_time"])))
	lines.append("")
	for pair in [["deaths_by", "QUEM MAIS TE MATOU"], ["kills_by", "QUEM VOCÊ MAIS MATOU"], ["weapon_kills", "SUAS ARMAS FAVORITAS"]]:
		var table: Dictionary = st.get(pair[0], {})
		if table.is_empty():
			continue
		var keys := table.keys()
		keys.sort_custom(func(a, b) -> bool: return int(table[a]) > int(table[b]))
		var top := PackedStringArray()
		for k in keys.slice(0, 3):
			var name := String(k)
			if pair[0] == "weapon_kills":
				var r := Catalog.find(name)
				name = r.title if r else name
			top.append("%s (%d)" % [name.to_upper(), int(table[k])])
		lines.append("%s: %s" % [pair[1], ", ".join(top)])
	var today: Dictionary = data["daily"].get(Run.today(), {})
	if not today.is_empty():
		lines.append("")
		lines.append("DESAFIO DE HOJE: %d TENTATIVAS · MAIS FUNDO %d%s" % [today["tries"], today["best_depth"],
			(" · VENCEU EM " + clock.call(float(today["best_time"]))) if float(today["best_time"]) > 0.0 else ""])
	return "\n".join(lines)


# --- Códice -----------------------------------------------------------------------

func note_lore(text: String) -> bool:
	if text == "" or data["lore"].has(text):
		return false
	data["lore"].append(text)
	save()
	return true


func known_creatures() -> Array:
	return data["stats"].get("kills_by", {}).keys()
