extends Node

# O robô que joga sozinho, sem tela, para medir o jogo:
#
#   Godot --headless --fixed-fps 60 --path . res://tests/robo.tscn -- --partidas=20 --brasas=0 --reflexo=0.75
#
# Joga partidas inteiras com o jogo de verdade (main.tscn), uma atrás da
# outra, guardando o progresso num save próprio (user://robo.save, nunca o
# real): plantas entregues e compras na Vigia valem para as partidas
# seguintes, como para um jogador. No fim escreve docs/ROBO.md com onde ele
# morre, quanto tempo cada andar leva, quem mais machuca e onde ficou preso.

const STAGE_LIMIT := 420.0      # s de jogo num andar antes de desistir dele
const SAVE := "user://robo.save"

var main: Node
var bot := Bot.new()
var runs := 10
var heat := 0
var seed0 := 1000
var out_path := "res://docs/ROBO.md"
var results: Array = []
var _level: Level
var _run_index := -1
var _run: Dictionary = {}
var _stage: Dictionary = {}
var _hurt_before := {}
var _menu_answers := 0
var _ending := false
var _wall_start := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"partidas": runs = int(kv[1])
			"brasas": heat = int(kv[1])
			"reflexo": bot.reflex = float(kv[1])
			"semente": seed0 = int(kv[1])
			"saida": out_path = kv[1]
			"rastro": bot.trace = kv[1] == "1"
	Meta.use_path(SAVE, true)
	Meta.data["intro_seen"] = true
	Options.data["hints"] = false
	Sfx.muted = true
	_wall_start = Time.get_ticks_msec()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	_next_run()


func _next_run() -> void:
	_run_index += 1
	if _run_index >= runs:
		_finish()
		return
	bot.rng.seed = seed0 + _run_index
	Engine.time_scale = 1.0
	_run = {"seed": seed0 + _run_index, "heat": heat, "stages": [], "result": "", "stuck": []}
	_ending = false
	main.screen.close()
	main.start_run(seed0 + _run_index, heat)


func _physics_process(_delta: float) -> void:
	if main == null or _run.is_empty():
		return
	if main.cutscene.is_open():
		main.cutscene.advance()
		return
	if main.menu.is_open():
		_answer(main.menu)
		return
	_menu_answers = 0
	if main.screen.visible and main.screen.mode in ["death", "victory", "title"] and not _ending:
		_end_run("vitória" if main.screen.mode == "victory" else "morte")
		return
	if main.level != _level and is_instance_valid(main.level) and main.level.player:
		_start_stage(main.level)
	if _level and Run.stage_time > STAGE_LIMIT and not _ending:
		_close_stage("tempo esgotado")
		_end_run("tempo esgotado", false)


func _start_stage(lv: Level) -> void:
	if not _stage.is_empty():
		_close_stage("passou")
	_level = lv
	lv.player.pad = bot
	bot.exit_pick = bot.rng.randi_range(0, 1)
	bot.stuck_events.clear()
	bot.setup(lv.player, lv)
	_hurt_before = Run.hurt_by.duplicate()
	_stage = {"id": Run.stage_id, "kind": lv.kind, "start": Run.time, "kills": _kills(),
		"flasks": lv.player.flasks, "hp_start": lv.player.hp, "max_hp": lv.player.max_hp}


func _kills() -> int:
	var n := 0
	for k in Run.kills_by:
		n += int(Run.kills_by[k])
	return n


func _close_stage(how: String) -> void:
	if _stage.is_empty():
		return
	var p: Player = _level.player if is_instance_valid(_level) else null
	var hurt := {}
	for k in Run.hurt_by:
		var d := int(Run.hurt_by[k]) - int(_hurt_before.get(k, 0))
		if d > 0:
			hurt[k] = d
	_stage["time"] = Run.time - float(_stage["start"])
	_stage["how"] = how
	_stage["hurt"] = hurt
	if p:
		_stage["kills"] = _kills() - int(_stage["kills"])
		_stage["flasks_used"] = maxi(int(_stage["flasks"]) - p.flasks, 0)
		_stage["hp_end"] = p.hp
		_stage["gear"] = p.weapons.map(func(g: Variant) -> String: return g.title() if g else "-") \
			+ p.skills.map(func(g: Variant) -> String: return g.title() if g else "-")
		_stage["levels"] = p.levels.duplicate()
	_stage["stuck"] = bot.stuck_events.map(func(s: Array) -> String: return "%s %s" % [s[1], s[5]] if s.size() > 5 and s[5] != "" else "%s" % [s[1]])
	for s in bot.stuck_events:
		print("  preso em %s pos %s indo %s alvo %s" % [s[1], s[3], s[2], s[4]])
	_run["stages"].append(_stage)
	_stage = {}


func _end_run(result: String, close := true) -> void:
	_ending = true
	if close:
		_close_stage("morreu" if result == "morte" else ("venceu" if result == "vitória" else result))
	_run["result"] = result
	_run["killer"] = Run.killer if result == "morte" else ""
	_run["time"] = Run.time
	_run["reached"] = Run.stage_id
	results.append(_run)
	var line := "partida %d/%d: %s em %s (%d:%02d) %s" % [_run_index + 1, runs, result, Run.stage_id,
		int(Run.time) / 60, int(Run.time) % 60, ("por " + Run.killer) if result == "morte" else ""]
	print(line)
	_level = null
	_run = {}
	Run.discard_saved()
	main._show_title.call_deferred()
	_next_run.call_deferred()


# Os menus que aparecem no caminho, respondidos como um jogador razoável.
func _answer(menu: Menu) -> void:
	_menu_answers += 1
	var title: String = menu._title
	var options: Array[Dictionary] = menu._options
	if menu._mode != "choice" or options.is_empty():
		menu.close()
		return
	var last := options.size() - 1
	if _menu_answers > 12:
		menu.choose(last)
		return
	var p: Player = _level.player if is_instance_valid(_level) else null
	if title.begins_with("FRAGMENTO") and p:
		var g := p.weapon(0)
		menu.choose(Combat.STATS.find(g.stat()) if g else 0)
	elif title.begins_with("MUTAÇÃO"):
		menu.choose(0)
	elif title.begins_with("A VIGIA"):
		menu.choose(_first_enabled(options, last))
	elif title.begins_with("O MERCADOR") and p:
		var pick := last
		for i in last:
			if options[i].get("disabled", false):
				continue
			var label: String = options[i]["label"]
			if label.begins_with("Pão") and p.hp < p.max_hp * 0.6 or label.begins_with("Frasco"):
				pick = i
				break
		menu.choose(pick)
	elif title.begins_with("BRASAS") or title.begins_with("ABANDONAR"):
		menu.choose(0)
	else:
		menu.choose(last)


func _first_enabled(options: Array[Dictionary], last: int) -> int:
	for i in last:
		if not options[i].get("disabled", false):
			return i
	return last


# --- relatório ----------------------------------------------------------------

func _finish() -> void:
	var text := _report()
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string(text)
	var raw := FileAccess.open(SAVE.get_basename() + "_partidas.json", FileAccess.WRITE)
	if raw:
		raw.store_string(JSON.stringify(results, "  "))
	print("relatório: " + ProjectSettings.globalize_path(out_path))
	get_tree().quit()


func _clock(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func _report() -> String:
	var L := PackedStringArray()
	var wins := results.filter(func(r: Dictionary) -> bool: return r["result"] == "vitória").size()
	var wall := (Time.get_ticks_msec() - _wall_start) / 1000.0
	L.append("# Relatório do robô")
	L.append("")
	L.append("%d partidas · brasas %d · reflexo %.2f · semente inicial %d · %d s de relógio" % [results.size(), heat, bot.reflex, seed0, int(wall)])
	L.append("")
	L.append("O robô joga com o jogo de verdade, sem tela. Ele não joga como gente: anda pelo caminho mais curto, reage a %d%% dos avisos e não aprende. Os números servem para **comparar** andares, chefes e inimigos entre si, não para dizer se o jogo está fácil para uma pessoa." % roundi(bot.reflex * 100))
	L.append("")
	L.append("**Vitórias:** %d de %d" % [wins, results.size()])
	L.append("")

	# por andar
	var by_stage := {}
	for r: Dictionary in results:
		for s: Dictionary in r["stages"]:
			var key: String = s["id"] + ("" if s["kind"] != "passagem" else " (passagem)")
			var agg: Dictionary = by_stage.get(key, {"n": 0, "died": 0, "time": 0.0, "lost": 0, "flasks": 0, "kills": 0, "stuck": 0, "hurt": {}})
			agg["n"] += 1
			agg["died"] += 1 if s["how"] == "morreu" else 0
			agg["time"] += float(s["time"])
			agg["flasks"] += int(s.get("flasks_used", 0))
			agg["kills"] += int(s.get("kills", 0))
			agg["stuck"] += s["stuck"].size()
			var lost := 0
			for k in s["hurt"]:
				lost += int(s["hurt"][k])
				agg["hurt"][k] = int(agg["hurt"].get(k, 0)) + int(s["hurt"][k])
			agg["lost"] += lost
			by_stage[key] = agg
	L.append("## Por andar")
	L.append("")
	L.append("| Andar | Vezes | Morreu aqui | Tempo médio | Vida perdida (média) | Frascos (média) | Abates (média) | Preso | Quem mais machucou |")
	L.append("|---|---|---|---|---|---|---|---|---|")
	for key: String in by_stage:
		var a: Dictionary = by_stage[key]
		var n := float(a["n"])
		var top := _top(a["hurt"], 3)
		L.append("| %s | %d | %d (%d%%) | %s | %d | %.1f | %.1f | %d | %s |" % [key, a["n"], a["died"], roundi(100.0 * a["died"] / n),
			_clock(a["time"] / n), roundi(a["lost"] / n), a["flasks"] / n, a["kills"] / n, a["stuck"], top])
	L.append("")

	# quem mata
	var killers := {}
	var hurt_all := {}
	for r: Dictionary in results:
		if r["killer"] != "":
			killers[r["killer"]] = int(killers.get(r["killer"], 0)) + 1
		for s: Dictionary in r["stages"]:
			for k in s["hurt"]:
				hurt_all[k] = int(hurt_all.get(k, 0)) + int(s["hurt"][k])
	L.append("## Quem mais matou")
	L.append("")
	for k in _sorted(killers):
		L.append("- %s: %d" % [k, killers[k]])
	L.append("")
	L.append("## Quem mais tirou vida (todas as partidas)")
	L.append("")
	for k in _sorted(hurt_all).slice(0, 15):
		L.append("- %s: %d" % [k, hurt_all[k]])
	L.append("")

	L.append("## Partidas")
	L.append("")
	L.append("| # | Semente | Resultado | Onde | Tempo | Morto por | Caminho |")
	L.append("|---|---|---|---|---|---|---|")
	for i in results.size():
		var r: Dictionary = results[i]
		var path := PackedStringArray()
		for s: Dictionary in r["stages"]:
			if s["kind"] != "passagem":
				path.append(s["id"])
		L.append("| %d | %d | %s | %s | %s | %s | %s |" % [i + 1, r["seed"], r["result"], r["reached"], _clock(r["time"]), r["killer"], " > ".join(path)])
	L.append("")

	L.append("## Onde o robô ficou preso")
	L.append("")
	L.append("Cada linha é um ponto em que ele não conseguiu seguir o caminho por %d s e foi empurrado para a frente. Muitos no mesmo andar podem ser sala ruim ou só o robô." % roundi(Bot.STUCK_SKIP))
	L.append("")
	var any := false
	for r: Dictionary in results:
		for s: Dictionary in r["stages"]:
			if not s["stuck"].is_empty():
				any = true
				L.append("- semente %d, %s: %s" % [r["seed"], s["id"], ", ".join(PackedStringArray(s["stuck"]))])
	if not any:
		L.append("Nenhum.")
	L.append("")
	# a mesma sala em sementes diferentes aponta para a sala, não para o robô
	var by_piece := {}
	for r: Dictionary in results:
		for s: Dictionary in r["stages"]:
			var seen := {}
			for e: String in s["stuck"]:
				var parts := e.split(" ")
				var piece := parts[parts.size() - 1] if parts.size() > 2 else ""
				if piece != "" and not seen.has(piece):
					seen[piece] = true
					by_piece[piece] = int(by_piece.get(piece, 0)) + 1
	if not by_piece.is_empty():
		L.append("### Salas onde ele prende (em quantas partidas)")
		L.append("")
		var names := by_piece.keys()
		names.sort_custom(func(a: String, b: String) -> bool: return by_piece[a] > by_piece[b])
		for n: String in names:
			L.append("- %s: %d" % [n, by_piece[n]])
		L.append("")
	return "\n".join(L)


func _sorted(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return int(d[a]) > int(d[b]))
	return keys


func _top(d: Dictionary, n: int) -> String:
	var parts := PackedStringArray()
	for k in _sorted(d).slice(0, n):
		parts.append("%s %d" % [k, d[k]])
	return ", ".join(parts)
