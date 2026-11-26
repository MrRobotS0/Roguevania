extends Node

# Vitrine: abre o jogo de verdade e passa pelos domínios, parando alguns
# segundos em cada um, com o herói imortal. Serve para fotografar a arte sem
# jogar (a versão de navegador num Chrome sem janela tira os prints).
#
#   Godot --path . res://scripts/debug/vitrine.tscn -- --dominios=mar_de_cinzas,saloes --segundos=6
#
# --robo=1 põe o robô (scripts/debug/bot.gd) para jogar: anda, luta e usa
# habilidade, ainda imortal. É o que tools/filmar.py grava para o trailer.
# --hud=0 esconde o HUD (tomadas de cinema do trailer).
# --lento=0.5 roda o mundo na metade da velocidade: o navegador sem janela desenha
# ~30 qps e o vídeo acelerado 2x sai com 60.
# "titulo" na lista de domínios mostra a tela de título.
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
var robo := false
var hud := true
var bot: Bot
var _level: Level
var pilhas := false        # --pilhas=1: baús, item e moedas ao lado do herói (ver o sprite stacking)
var _pilhas_level: Level


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"dominios": stages = Array(kv[1].split(","))
			"segundos": seconds = float(kv[1])
			"robo": robo = kv[1] == "1"
			"pilhas": pilhas = kv[1] == "1"
			"hud": hud = kv[1] != "0"
			"lento": Fx.base_time_scale = float(kv[1])
	# os menus pausam o jogo; a vitrine precisa continuar para responder
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	Engine.time_scale = Fx.base_time_scale
	_next()


func _next() -> void:
	_i += 1
	if _i >= stages.size():
		_title("VITRINE FIM")
		return
	var id: String = stages[_i]
	_clock = 0.0
	if id == "titulo":
		main.screen.show_title()
		main.screen.visible = true
		await get_tree().create_timer(minf(1.5, seconds * 0.5)).timeout
		_title("VITRINE " + id)
		return
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
		if robo and lv != _level:
			_level = lv
			bot = Bot.new()
			bot.rng.seed = 7
			lv.player.pad = bot
			bot.setup(lv.player, lv)
	if pilhas and lv and is_instance_valid(lv.player) and lv != _pilhas_level:
		_pilhas_level = lv
		_spawn_stacks(lv)
	if not hud and main and main.hud:
		main.hud.visible = false
	if robo and main:
		if main.cutscene.is_open():
			main.cutscene.advance()
		elif main.menu.is_open():
			var m: Menu = main.menu
			if m._mode == "choice" and not m._options.is_empty():
				m.choose(0)
			else:
				m.close()
	_clock += delta
	if _clock >= seconds and _i < stages.size():
		_clock = -999.0
		_next()


# Objetos montados em fatias (Stack) perto do herói, no chão dele.
func _spawn_stacks(lv: Level) -> void:
	var at := lv.player.global_position
	var chest := Chest.new()
	chest.level = lv
	chest.position = at + Vector2(44, 0)
	lv.add_child(chest)
	var cursed := Chest.new()
	cursed.cursed = true
	cursed.level = lv
	cursed.position = at + Vector2(84, 0)
	lv.add_child(cursed)
	var item := Pickup.new()
	item.gear = Catalog.random_gear(lv.rng, 1)
	item.level = lv
	item.position = at + Vector2(-40, 0)
	lv.add_child(item)
	lv.drop_gold(at + Vector2(20, -30), 40)
