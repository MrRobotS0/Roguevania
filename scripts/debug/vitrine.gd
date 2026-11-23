extends Node

# Vitrine: abre o jogo de verdade e passa pelos domínios, parando alguns
# segundos em cada um, com o herói imortal. Serve para fotografar a arte sem
# jogar (a versão de navegador num Chrome sem janela tira os prints).
#
#   Godot --path . res://scripts/debug/vitrine.tscn -- --dominios=mar_de_cinzas,saloes --segundos=6
#
# No navegador o título da aba vira "VITRINE <domínio>" quando o domínio
# está montado, e "VITRINE FIM" no final.

const ALL := ["mar_de_cinzas", "saloes", "forja_rubra", "necropole", "torre_babel", "jardim_primordial",
	"catedral", "carcosa", "observatorio", "ventre", "penhascos", "cavernas", "bosque"]

var main: Node
var stages: Array = ALL.duplicate()
var seconds := 6.0
var _i := -1
var _clock := 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"dominios": stages = Array(kv[1].split(","))
			"segundos": seconds = float(kv[1])
	Meta.use_path("user://vitrine.save", true)
	Meta.data["intro_seen"] = true
	Options.data["hints"] = false
	Sfx.muted = true
	# pelo jogo (main.gd com --vitrine, como no navegador) ou sozinha
	if main == null:
		main = load("res://scenes/main.tscn").instantiate()
		add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main.start_run(7)
	_next()


func _next() -> void:
	_i += 1
	if _i >= stages.size():
		_title("VITRINE FIM")
		return
	var id: String = stages[_i]
	Run.go(id)
	main.screen.close()
	main._load_stage()
	_clock = 0.0
	await get_tree().create_timer(minf(1.5, seconds * 0.5)).timeout
	_title("VITRINE " + id)


func _title(t: String) -> void:
	print(t)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.title = '%s'" % t)


func _process(delta: float) -> void:
	var lv: Level = main.level if main else null
	if lv and is_instance_valid(lv.player):
		lv.player.hp = lv.player.max_hp
	_clock += delta
	if _clock >= seconds and _i < stages.size():
		_clock = -999.0
		_next()
