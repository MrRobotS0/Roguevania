extends SceneTree

# Sonda da auditoria: quanto custa UM quadro de lógica + desenho (lado do processador,
# sem placa de vídeo) em cada tipo de fase, e o que pesa dentro de um andar gerado.
#
#   Godot --headless --fixed-fps 60 --path <projeto> --script tools/sonda_cpu.gd
#
# Com --fixed-fps cada volta do laço simula exatamente 1/60 s (um passo de física e um
# de processo) e roda o mais rápido que der: o tempo de relógio por volta é o custo de
# processador de um quadro. Não grava nada no projeto (save próprio em user://).

const FRAMES := 240
const WARM := 90

var main: Node
var lines: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func _say(text: String) -> void:
	print(text)
	lines.append(text)


func _wait(n: int) -> void:
	for i in n:
		await process_frame


func _measure() -> float:
	await _wait(WARM)
	var t0 := Time.get_ticks_usec()
	await _wait(FRAMES)
	return (Time.get_ticks_usec() - t0) / 1000.0 / FRAMES


func _counts() -> String:
	var lv: Node = main.level
	var lights := 0
	var actors := 0
	var redraw := 0
	for n in lv.get_children():
		if n is PointLight2D:
			lights += 1
		for c in n.get_children():
			if c is PointLight2D:
				lights += 1
	actors = get_nodes_in_group("enemies").size()
	var room: Node = lv.get("room")
	return "sala %dx%d blocos, %d filhos da fase, %d inimigos, %d luzes pontuais, %d nós no total" % [
		room.get("cols"), room.get("rows"), lv.get_child_count(), actors, lights, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))]


func _load(stage: String) -> void:
	var run: Node = root.get_node("Run")
	run.call("go", stage)
	main.screen.close()
	main._load_stage()
	await _wait(5)
	if main.level and main.level.player:
		main.level.player.hp = 100000
		main.level.player.max_hp = 100000


func _run() -> void:
	var meta: Node = root.get_node("Meta")
	meta.call("use_path", "user://sonda_auditoria.save", true)
	meta.get("data")["intro_seen"] = true
	root.get_node("Options").get("data")["hints"] = false
	root.get_node("Sfx").set("muted", true)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _wait(3)
	main.start_run(7)
	await _wait(3)

	_say("== custo de processador por quadro (ms), nativo, sem vídeo ==")
	for stage in ["beira", "lobo", "mar_de_cinzas", "jardim_primordial", "catedral", "forja_rubra", "saloes"]:
		await _load(stage)
		var ms: float = await _measure()
		_say("%-18s %5.2f ms  | %s" % [stage, ms, _counts()])

	# dentro de um andar gerado: desliga uma coisa de cada vez (acumulando)
	for stage in ["jardim_primordial", "catedral"]:
		await _load(stage)
		var lv: Node = main.level
		var base: float = await _measure()
		_say("-- %s: tudo ligado %5.2f ms" % [stage, base])
		main.hud.visible = false
		var a: float = await _measure()
		_say("   sem o HUD (minimapa incluso)        %5.2f ms  (HUD = %.2f)" % [a, base - a])
		for e in get_nodes_in_group("enemies"):
			e.set_physics_process(false)
			e.set_process(false)
			e.visible = false
		var b: float = await _measure()
		_say("   + inimigos parados e invisíveis     %5.2f ms  (inimigos = %.2f)" % [b, a - b])
		var names := {}
		for n in lv.get_children():
			var cls := ""
			var s: Script = n.get_script()
			if s:
				cls = s.get_global_name()
			if cls in ["Grass", "Puddles", "Reflection", "TorchShadows", "CloudShadows", "ContactShadows"]:
				n.set_process(false)
				(n as CanvasItem).visible = false
				names[cls] = true
		var c: float = await _measure()
		_say("   + sem %s  %5.2f ms  (= %.2f)" % [", ".join(PackedStringArray(names.keys())), c, b - c])
		for n in lv.get_children():
			if n is Node2D and n != lv.get("player") and n != lv.get("room") and not (n is Camera2D):
				n.set_process(false)
				n.set_physics_process(false)
				(n as Node2D).visible = false
		var d: float = await _measure()
		_say("   + sem objetos, braseiros e o resto  %5.2f ms  (= %.2f)" % [d, c - d])
		main.backdrop.visible = false
		main.ambience.visible = false
		main.foreground.visible = false
		main.weather.visible = false
		main.post_fx.visible = false
		var e2: float = await _measure()
		_say("   + sem fundo, ar, primeiro plano     %5.2f ms  (= %.2f)" % [e2, d - e2])
		main.hud.visible = true
		main.backdrop.visible = true
		main.ambience.visible = true
		main.foreground.visible = true
		main.weather.visible = true
		main.post_fx.visible = true

	var f := FileAccess.open("user://sonda_auditoria.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
	quit()
