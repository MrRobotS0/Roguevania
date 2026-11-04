extends Node2D

# Fluxo do jogo: título → partida (fase gerada → sala do chefe) → morte ou
# vitória → título. Também cuida da pausa (Esc).

var level: Level
var hud: Hud
var menu: Menu
var screen: Screen
var backdrop: Backdrop
var ambience: Ambience
var weather: Weather
var foreground: Foreground
var curtain: Curtain
var map_view: MapView
var options_screen: OptionsScreen
var cutscene: Cutscene
var guide: Guide
var _playing := false


func _ready() -> void:
	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	backdrop = Backdrop.new()
	# o fundo fica mais apagado que o mundo jogável, que é iluminado
	backdrop.modulate = Color(0.7, 0.66, 0.72)
	back.add_child(backdrop)
	# o ar do domínio (raios, névoa, partículas) fica entre o fundo e o mundo
	ambience = Ambience.new()
	back.add_child(ambience)

	var front_scenery := CanvasLayer.new()
	front_scenery.layer = 4
	add_child(front_scenery)
	foreground = Foreground.new()
	front_scenery.add_child(foreground)

	# Brilho (bloom) no que é muito claro: fogo, luz do Imperador, Essência.
	# Vale para o mundo e o clima; o HUD (camada 10) fica fora.
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = 6
	env.glow_enabled = true
	env.glow_intensity = 0.95
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 0.74
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var air := CanvasLayer.new()
	air.layer = 5
	add_child(air)
	weather = Weather.new()
	air.add_child(weather)

	var lens := CanvasLayer.new()
	lens.layer = 7
	add_child(lens)
	lens.add_child(Vignette.new())
	curtain = Curtain.new()
	var cover := CanvasLayer.new()
	cover.layer = 9
	add_child(cover)
	cover.add_child(curtain)

	var front := CanvasLayer.new()
	front.layer = 10
	add_child(front)
	hud = Hud.new()
	front.add_child(hud)
	guide = Guide.new()
	front.add_child(guide)
	map_view = MapView.new()
	front.add_child(map_view)
	screen = Screen.new()
	front.add_child(screen)
	menu = Menu.new()
	front.add_child(menu)
	options_screen = OptionsScreen.new()
	front.add_child(options_screen)
	cutscene = Cutscene.new()
	front.add_child(cutscene)
	screen.confirmed.connect(_on_screen_confirmed)
	screen.title_option.connect(_on_title_option)

	_show_title()


func _show_title() -> void:
	_playing = false
	Run.active = false
	_clear_level()
	_load_backdrop_preview()
	screen.show_title()
	Music.play("titulo")


func _load_backdrop_preview() -> void:
	_use_biome(Catalog.biome("mar_de_cinzas"))


func _use_biome(b: BiomeData) -> void:
	hud.use_theme(b.id)
	backdrop.style = b.backdrop
	backdrop.sky = b.sky
	backdrop.layers = b.layers
	ambience.use(b.id)
	foreground.style = b.backdrop
	foreground.ink = b.ink


# Começar outra partida com uma salva esperando: pergunta antes de jogar fora.
func _abandon_saved_first(then: Callable) -> bool:
	if screen.mode != "title" or Run.saved().is_empty():
		return false
	var options: Array[Dictionary] = [
		{"label": "NÃO, VOLTAR", "detail": ""},
		{"label": "SIM, COMEÇAR DE NOVO", "detail": "A PARTIDA SALVA SE PERDE", "color": Palette.HURT},
	]
	menu.open_choice("ABANDONAR A PARTIDA SALVA?", "", options, func(i: int) -> void:
		if i == 1:
			Run.discard_saved()
			then.call_deferred())
	return true


func _on_screen_confirmed() -> void:
	if _abandon_saved_first(_on_screen_confirmed):
		return
	var unlocked := int(Meta.data["heat"])
	if screen.mode != "title" or unlocked <= 0:
		screen.close()
		_begin(-1, 0)
		return
	# Brasas do Deus: quem já venceu escolhe a dificuldade
	var options: Array[Dictionary] = []
	for h in unlocked + 1:
		options.append({"label": HEAT_NAMES[h], "detail": HEAT_DETAILS[h],
			"color": Palette.UI_TEXT if h == 0 else Palette.BURN.lerp(Palette.HURT, h / 4.0)})
	menu.open_choice("BRASAS DO DEUS", "QUANTO MAIS BRASA, MAIS O DEUS MORTO RESISTE.", options,
		func(i: int) -> void:
			screen.close()
			_begin(-1, i))
	menu.select(unlocked)


const HEAT_NAMES := ["Sem brasa", "1 brasa", "2 brasas", "3 brasas", "4 brasas"]
const HEAT_DETAILS := [
	"COMO DA PRIMEIRA VEZ",
	"INIMIGOS +40% DE VIDA, +25% DE DANO",
	"+80% VIDA, +50% DANO, UM FRASCO A MENOS",
	"+120% VIDA, +75% DANO, UM FRASCO A MENOS",
	"+160% VIDA, +100% DANO, UM FRASCO A MENOS",
]


func _on_title_option(id: String) -> void:
	match id:
		"continue":
			continue_run()
		"update":
			Updater.restart_into()
		"skins":
			open_skins()
		"controls":
			menu.open_text("COMANDOS", CONTROLS)
		"options":
			options_screen.open()
		"stats":
			menu.open_text("ESTATÍSTICAS", Meta.stats_text())
		"codex":
			open_codex()
		"credits":
			var file := "res://content/creditos%s.txt" % ("_en" if Lang.lang == "en" else "")
			menu.open_text("CRÉDITOS", FileAccess.get_file_as_string(file))
		"daily":
			if _abandon_saved_first(_on_title_option.bind("daily")):
				return
			screen.close()
			Run.new_daily()
			_load_stage()
		"quit":
			get_tree().quit()


# Escolha de aparência. As trancadas aparecem apagadas, dizendo como ganhar.
func open_skins() -> void:
	var list := Catalog.skins()
	var current := Meta.current_skin()
	var options: Array[Dictionary] = []
	for s in list:
		var owned := Meta.has_skin(s)
		var label := s.title + ("  ·  EM USO" if s == current else "")
		options.append({"label": label, "detail": s.lore if owned else s.how_to_get(),
			"disabled": not owned, "figure": s.colors(),
			"color": Palette.GOLD if s == current else Palette.UI_TEXT})
	menu.open_choice("APARÊNCIA", "SÓ MUDA O VISUAL. VALE PARA A PRÓXIMA PARTIDA.", options,
		func(i: int) -> void:
			open_chromas.call_deferred(list[i]))
	menu.select(list.find(current))


# Cromas de uma aparência: a original e as variações de cor.
func open_chromas(s: SkinData) -> void:
	var ids: Array[String] = [""]
	for c: Dictionary in s.chromas:
		ids.append(String(c["id"]))
	var worn := Meta.current_skin() == s
	var now := Meta.chroma_of(s)
	var options: Array[Dictionary] = []
	for id in ids:
		var owned := Meta.has_chroma(s, id)
		var c := s.chroma_data(id)
		var title := "Original" if id == "" else String(c["title"])
		var label := title + ("  ·  EM USO" if worn and id == now else "")
		options.append({"label": label, "figure": s.colors(id), "disabled": not owned,
			"detail": "" if owned else "COMPRE COM A VIGIA · %d DE ESSÊNCIA" % int(c.get("cost", 0)),
			"color": Palette.GOLD if worn and id == now else Palette.UI_TEXT})
	menu.open_choice(s.title.to_upper(), "CROMAS: A MESMA APARÊNCIA EM OUTRAS CORES.", options,
		func(i: int) -> void:
			Meta.wear(s.id, ids[i])
			open_skins.call_deferred())
	menu.select(maxi(ids.find(now), 0) if worn else 0)


# Na primeira partida, antes de tudo, a abertura.
func _begin(seed_value: int, heat: int) -> void:
	if Meta.data.get("intro_seen", false):
		start_run(seed_value, heat)
		return
	Music.play("passagem")
	cutscene.play(PackedStringArray(Story.INTRO), func() -> void:
		Meta.data["intro_seen"] = true
		Meta.save()
		start_run(seed_value, heat))


func open_codex() -> void:
	var lore: Array = Meta.data["lore"]
	var known := Meta.known_creatures()
	var options: Array[Dictionary] = [
		{"label": "INSCRIÇÕES  ·  %d LIDAS" % lore.size(), "detail": "O QUE AS PEDRAS CONTAM"},
		{"label": "BESTIÁRIO  ·  %d DE %d" % [known.size(), Story.BESTIARY.size()], "detail": "O QUE VOCÊ JÁ DERROTOU"},
		{"label": "REVER A ABERTURA", "detail": ""},
	]
	menu.open_choice("CÓDICE", "", options, _on_codex_pick)


func _on_codex_pick(i: int) -> void:
	match i:
		0:
			_codex_lore.call_deferred()
		1:
			_codex_bestiary.call_deferred()
		2:
			cutscene.play.call_deferred(PackedStringArray(Story.INTRO), Callable())


func _codex_lore() -> void:
	var lore: Array = Meta.data["lore"]
	if lore.is_empty():
		menu.open_text("INSCRIÇÕES", "NENHUMA AINDA. AS PEDRAS COM LETRAS DOURADAS TÊM ALGO A DIZER.")
		return
	menu.open_text("INSCRIÇÕES", "\n\n".join(PackedStringArray(lore.map(func(t: String) -> String: return "· " + t))))


func _codex_bestiary() -> void:
	var known := Meta.known_creatures()
	var lines := PackedStringArray()
	for title: String in Story.BESTIARY:
		if known.has(title):
			lines.append("%s: %s" % [title, Story.BESTIARY[title]])
		else:
			lines.append("??? ")
	menu.open_text("BESTIÁRIO", "\n".join(lines))


func continue_run() -> void:
	var s := Run.saved()
	if s.is_empty():
		return
	screen.close()
	Run.restore(s)
	_load_stage()


func start_run(seed_value := -1, heat := 0) -> void:
	Run.new_run(seed_value, heat)
	_load_stage()


func _load_stage() -> void:
	_clear_level()
	Engine.time_scale = 1.0
	Fx.shake = 0.0
	Fx.visibility = 1.0
	var stage := Run.current()
	var b := Catalog.biome(stage["biome"])
	_use_biome(b)
	weather.kind = ""

	level = Level.new()
	add_child(level)
	match stage["kind"]:
		"chefe":
			level.build_boss(b, Run.stage_seed())
			foreground.style = ""
			Music.play("chefe_final" if Run.stage_id == "trono" else "chefe")
		"passagem":
			level.build_passage(b, Run.stage_seed())
			Music.play("passagem")
		_:
			level.build_generated(b, Run.stage_seed())
			weather.kind = b.weather
			Music.play(b.id)
	map_view.level = level
	Run.stage_tier = level.tier
	weather.player = level.player
	Run.load_player(level.player)
	Run.suspend()
	hud.bind(level.player, level.boss)
	guide.bind(level)
	level.player.died.connect(_on_player_died)
	# a saída é usada no meio do passo de física do herói: troca de andar no fim do quadro
	level.exit_used.connect(_on_exit, CONNECT_DEFERRED)
	_playing = true
	Run.active = true
	curtain.reveal()


func _clear_level() -> void:
	if foreground:
		foreground.style = ""
	weather.kind = ""
	weather.strength = 0.0
	if level:
		remove_child(level)
		level.queue_free()
		level = null
	hud.player = null
	hud.boss = null
	if guide:
		guide.bind(null)


func _on_exit(dest: String) -> void:
	Run.save_player(level.player)
	match dest:
		"fim":
			_playing = false
			Run.active = false
			Run.discard_saved()
			Meta.record_run(true, level.player.kills)
			Meta.record_heat_win(Run.heat)
			Run.set_meta("record", Meta.record_stats(true))
			var hero := level.player
			Music.play("passagem")
			cutscene.play(Story.ending_pages(Run.heat), func() -> void:
				screen.show_victory(hero)
				Music.play("titulo"))
			return
		"passagem":
			Run.enter_passage()
		"boss":
			Run.go(Run.boss_of(Run.stage_id))
		_:
			Run.go(dest)
	_load_stage()


func _on_player_died() -> void:
	if not _playing:
		return
	_playing = false
	Run.active = false
	Run.discard_saved()
	Meta.record_run(false, level.player.kills)
	Meta.record_stats(false)
	var place := level.biome.title if level.biome else "TREINO"
	if level.is_boss_room:
		place = "O Trono do Imperador Cego"
	screen.show_death(level.player, place)
	Music.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		Fx.debug = not Fx.debug
	elif event.is_action_pressed("reset") and _playing:
		start_run()
	elif event.is_action_pressed("pause") and _playing and not menu.is_open() and not options_screen.is_open():
		_pause()


func _pause() -> void:
	var options: Array[Dictionary] = [
		{"label": "CONTINUAR", "detail": ""},
		{"label": "OPÇÕES", "detail": "SOM, TELA, TREMOR, TECLAS"},
		{"label": "COMANDOS", "detail": "TECLADO E CONTROLE"},
		{"label": "SALVAR E SAIR", "detail": "CONTINUA DEPOIS, DO COMEÇO DESTE ANDAR"},
		{"label": "DESISTIR DA PARTIDA", "detail": "VOLTA AO TÍTULO; A ESSÊNCIA SE PERDE"},
	]
	var names: Array = level.player.mutations.map(func(id: String) -> String: return String(Catalog.mutation(id).get("title", id)))
	var info := "MUTAÇÕES: " + ", ".join(PackedStringArray(names)) if not names.is_empty() else ""
	if Run.heat > 0:
		info += ("   ·   " if info != "" else "") + "BRASAS: %d" % Run.heat
	menu.open_choice("PAUSA", info, options, _on_pause_pick)


func _on_pause_pick(i: int) -> void:
	if i == 1:
		options_screen.open.call_deferred()
	elif i == 2:
		menu.open_text.call_deferred("COMANDOS", CONTROLS)
	elif i == 3:
		_show_title()
	elif i == 4:
		Run.discard_saved()
		Meta.record_run(false, level.player.kills)
		Meta.record_stats(false)
		_show_title()


const CONTROLS := "M OU TAB (SEGURE): MAPA\nA / D  OU SETAS: ANDAR\nESPAÇO: PULAR (SEGURE PARA PULAR MAIS ALTO)\nJ: ARMA 1   K: ARMA 2   (MOUSE: ESQUERDO E DIREITO)\nU: HABILIDADE 1   I: HABILIDADE 2\nSHIFT: ROLAR (INVENCÍVEL DURANTE A ROLAGEM)\nS + J NO AR: MERGULHO\nS + ESPAÇO: DESCER DA PLATAFORMA\nQ: BEBER FRASCO   E: USAR / PEGAR\nESC: PAUSA   F1: DEBUG\n\nCONTROLE: A PULA, X E Y ARMAS, LB E RB HABILIDADES, B OU RT ROLA, LT CURA, CIMA USA"
