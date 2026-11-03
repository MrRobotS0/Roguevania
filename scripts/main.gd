extends Node2D

# Fluxo do jogo: título → partida (fase gerada → sala do chefe) → morte ou
# vitória → título. Também cuida da pausa (Esc).

var level: Level
var hud: Hud
var menu: Menu
var screen: Screen
var backdrop: Backdrop
var weather: Weather
var _playing := false


func _ready() -> void:
	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	backdrop = Backdrop.new()
	back.add_child(backdrop)

	var air := CanvasLayer.new()
	air.layer = 5
	add_child(air)
	weather = Weather.new()
	air.add_child(weather)

	var front := CanvasLayer.new()
	front.layer = 10
	add_child(front)
	hud = Hud.new()
	front.add_child(hud)
	menu = Menu.new()
	front.add_child(menu)
	screen = Screen.new()
	front.add_child(screen)
	screen.confirmed.connect(_on_screen_confirmed)

	_show_title()


func _show_title() -> void:
	_playing = false
	Run.active = false
	_clear_level()
	_load_backdrop_preview()
	screen.show_title()


func _load_backdrop_preview() -> void:
	var b := Catalog.biome("mar_de_cinzas")
	backdrop.style = b.backdrop
	backdrop.sky = b.sky


func _on_screen_confirmed() -> void:
	screen.close()
	start_run()


func start_run(seed_value := -1) -> void:
	Run.new_run(seed_value)
	_load_stage()


func _load_stage() -> void:
	_clear_level()
	Engine.time_scale = 1.0
	Fx.shake = 0.0
	Fx.visibility = 1.0
	var stage := Run.current()
	var b := Catalog.biome(stage["biome"])
	backdrop.style = b.backdrop
	backdrop.sky = b.sky

	level = Level.new()
	add_child(level)
	if stage["kind"] == "chefe":
		level.build_boss(b, Run.seed_value)
		weather.kind = ""
	else:
		level.build_generated(b, Run.seed_value)
		weather.kind = b.weather
	weather.player = level.player
	Run.load_player(level.player)
	hud.bind(level.player, level.boss)
	level.player.died.connect(_on_player_died)
	level.exit_used.connect(_on_exit)
	_playing = true
	Run.active = true


func _clear_level() -> void:
	weather.kind = ""
	weather.strength = 0.0
	if level:
		remove_child(level)
		level.queue_free()
		level = null
	hud.player = null
	hud.boss = null


func _on_exit(dest: String) -> void:
	Run.save_player(level.player)
	if dest == "fim":
		_playing = false
		Run.active = false
		Meta.record_run(true, level.player.kills)
		screen.show_victory(level.player)
		return
	if Run.advance():
		_load_stage()
	else:
		_show_title()


func _on_player_died() -> void:
	if not _playing:
		return
	_playing = false
	Run.active = false
	Meta.record_run(false, level.player.kills)
	var place := level.biome.title if level.biome else "TREINO"
	if level.is_boss_room:
		place = "O Trono do Imperador Cego"
	screen.show_death(level.player, place)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		Fx.debug = not Fx.debug
	elif event.is_action_pressed("reset") and _playing:
		start_run()
	elif event.is_action_pressed("pause") and _playing and not menu.is_open():
		_pause()


func _pause() -> void:
	var options: Array[Dictionary] = [
		{"label": "CONTINUAR", "detail": ""},
		{"label": "COMANDOS", "detail": "TECLADO E CONTROLE"},
		{"label": "DESISTIR DA PARTIDA", "detail": "VOLTA AO TÍTULO; A ESSÊNCIA SE PERDE"},
	]
	menu.open_choice("PAUSA", "", options, _on_pause_pick)


func _on_pause_pick(i: int) -> void:
	if i == 1:
		menu.open_text.call_deferred("COMANDOS", CONTROLS)
	elif i == 2:
		Meta.record_run(false, level.player.kills)
		_show_title()


const CONTROLS := "A / D  OU SETAS: ANDAR\nESPAÇO: PULAR (SEGURE PARA PULAR MAIS ALTO)\nJ: ARMA 1   K: ARMA 2   (MOUSE: ESQUERDO E DIREITO)\nU: HABILIDADE 1   I: HABILIDADE 2\nSHIFT: ROLAR (INVENCÍVEL DURANTE A ROLAGEM)\nS + J NO AR: MERGULHO\nS + ESPAÇO: DESCER DA PLATAFORMA\nQ: BEBER FRASCO   E: USAR / PEGAR\nESC: PAUSA   F1: DEBUG\n\nCONTROLE: A PULA, X E Y ARMAS, LB E RB HABILIDADES, B OU RT ROLA, LT CURA, CIMA USA"
