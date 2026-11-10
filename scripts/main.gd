extends Node2D

# Fluxo do jogo: título → Beira (onde se escolhe e se renasce) → arco → partida
# (fase gerada → sala do chefe) → morte → Beira de novo. Também cuida da pausa (Esc).

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
	# no título o ar do domínio fica de leve: o menu é o que importa
	ambience.modulate.a = 0.35
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
	if screen.mode == "victory" and screen.to_title:
		_show_title()
		return
	if _abandon_saved_first(_on_screen_confirmed):
		return
	screen.close()
	_begin()


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
		"controls":
			menu.open_text("COMANDOS", CONTROLS)
		"options":
			options_screen.open()
		"stats":
			menu.open_text("ESTATÍSTICAS", Meta.stats_text())
		"extras":
			# o que saiu do menu principal: uma lista curta à parte
			var list: Array = Screen.EXTRAS.duplicate()
			if OS.has_feature("web"):
				list.append_array(Screen.WEB_EXTRAS)
			var options: Array[Dictionary] = []
			for o in list:
				options.append({"label": o[1], "detail": "ABRE EM OUTRA ABA" if Screen.WEB_EXTRAS.has(o) else ""})
			menu.open_choice("EXTRAS", "", options, func(i: int) -> void:
				_on_title_option.call_deferred(String(list[i][0])))
		"ranking", "feedback":
			open_site_page(Screen.WEB_PAGES[id])
		"profile":
			open_site_page("/perfil.html?nome=" + Meta.player_name.uri_encode())
		"codex":
			open_codex()
		"credits":
			var file := "res://content/creditos%s.txt" % ("_en" if Lang.lang == "en" else "")
			menu.open_text("CRÉDITOS", FileAccess.get_file_as_string(file))
		"modes":
			open_modes()
		"daily":
			if _abandon_saved_first(_on_title_option.bind("daily")):
				return
			screen.close()
			Run.new_daily()
			_load_stage()
		"weekly":
			open_weekly()
		"weekly_go":
			if _abandon_saved_first(_on_title_option.bind("weekly_go")):
				return
			screen.close()
			Run.new_weekly()
			_load_stage()
			var names: Array = Run.rules.map(func(id: String) -> String: return String(Run.rule(id)["title"]).to_upper())
			Fx.banner("DESAFIO DA SEMANA", "   ·   ".join(PackedStringArray(names)))
		"waves":
			if _abandon_saved_first(_on_title_option.bind("waves")):
				return
			screen.close()
			Run.new_waves()
			_load_stage()
		"quit":
			get_tree().quit()


# No navegador: abre uma página de moksha.com.br em outra aba, sem fechar o jogo.
func open_site_page(path: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open(%s, '_blank', 'noopener')" % JSON.stringify(path), true)


# O que não é a partida normal. Nada aqui passa pela Beira: as regras são as mesmas para todos.
func open_modes() -> void:
	var best := int(Meta.data.get("best_wave", 0))
	var options: Array[Dictionary] = [
		{"label": "DESAFIO DO DIA", "detail": "O MESMO MAPA PARA TODOS, SÓ HOJE. A 1ª TENTATIVA DÁ ESSÊNCIA"},
		{"label": "DESAFIO DA SEMANA", "detail": "DUAS REGRAS QUE VIRAM O JOGO. MUDAM TODA SEGUNDA"},
		{"label": "MODO WAVES", "price": ("WAVE %d" % best) if best > 0 else "", "price_color": Palette.GOLD,
			"detail": "ARENA FECHADA. FRASCO A CADA 5 WAVES, GUARDIÃO A CADA 10"},
	]
	menu.open_choice("MODOS", "", options, _on_modes_pick)


func _on_modes_pick(i: int) -> void:
	_on_title_option.call_deferred(["daily", "weekly", "waves"][i])


func open_weekly() -> void:
	var list := Run.week_rules(Run.this_week())
	var options: Array[Dictionary] = [{"label": "COMEÇAR", "detail": "O MESMO MAPA E AS MESMAS REGRAS PARA TODOS ATÉ SEGUNDA"}]
	for id: String in list:
		var r := Run.rule(id)
		options.append({"label": r["title"], "detail": r["detail"], "color": Palette.BURN})
	menu.open_choice("DESAFIO DA SEMANA", "", options, func(i: int) -> void:
		_on_title_option.call_deferred("weekly_go" if i == 0 else "weekly"))


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
	menu.open_choice("OS MANTOS", "SÓ MUDA O VISUAL.", options,
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
			if level and is_instance_valid(level.player):
				level.player.refresh_look()
			open_skins.call_deferred())
	menu.select(maxi(ids.find(now), 0) if worn else 0)


# --- a Beira ------------------------------------------------------------------------

# Na primeira vez, antes de tudo, a abertura.
func _begin() -> void:
	if Meta.data.get("intro_seen", false):
		enter_beira()
		return
	Music.play("passagem")
	cutscene.play(PackedStringArray(Story.INTRO), func() -> void:
		Meta.data["intro_seen"] = true
		Meta.save()
		enter_beira())


func enter_beira() -> void:
	Run.discard_saved()
	Run.enter_beira()
	_load_stage()
	_rebirth()


# O herói se levanta da cinza. As conquistas novas aparecem aqui.
func _rebirth() -> void:
	var p := level.player
	p.modulate = Color(0.25, 0.24, 0.28, 0.0)
	p.create_tween().tween_property(p, "modulate", Color.WHITE, 0.9)
	Fx.burst(p.center(), Color("8a8290"), 24, 70.0, 0.9, -30.0)
	Sfx.play("portal", -10.0)
	var fresh := Meta.check_feats()
	if fresh.size() == 1:
		Fx.toast("CONQUISTA: " + String(fresh[0]["title"]).to_upper())
	elif fresh.size() > 1:
		Fx.toast("%d CONQUISTAS NOVAS" % fresh.size())


func _on_station(kind: String) -> void:
	match kind:
		"mantos":
			open_skins()
		"poco":
			open_well()
		"carroca":
			open_wagon()
		"marcas":
			open_marks()
		"braseiro":
			open_brazier()


func open_well() -> void:
	var known := Meta.start_mutations()
	var ids: Array[String] = [""]
	var options: Array[Dictionary] = [{"label": "NADA", "detail": "COMEÇAR SEM MUTAÇÃO"}]
	for m: Dictionary in Catalog.MUTATIONS:
		var has := known.has(m["id"])
		ids.append(m["id"])
		options.append({"label": m["title"] if has else "???", "disabled": not has,
			"detail": m["detail"] if has else "BEBA DELA NUM ALTAR PARA O POÇO LEMBRAR", "color": Color("b8f06a")})
	_mark_current(options, ids, Run.start_mutation)
	menu.open_choice("O POÇO", "UMA MUTAÇÃO PARA COMEÇAR. CONTA ENTRE AS TRÊS DA PARTIDA.", options, func(i: int) -> void:
		Run.start_mutation = ids[i]
		Meta.pick("pick_mutation", ids[i])
		Sfx.play("mutation")
		Fx.burst(level.player.center(), Color("b8f06a"), 14, 90.0, 0.5, -40.0))
	menu.select(ids.find(Run.start_mutation))


func open_wagon() -> void:
	var ids: Array[String] = [""]
	var options: Array[Dictionary] = [{"label": "NADA", "detail": "COMEÇAR DE MÃOS VAZIAS"}]
	for a: Dictionary in Catalog.ADVANTAGES:
		var has := Meta.has_advantage(a["id"])
		ids.append(a["id"])
		var how: String = "CONQUISTA: " + String(Catalog.feat(a.get("needs", "")).get("title", "")).to_upper()
		options.append({"label": a["title"] if has else "???", "disabled": not has,
			"detail": a["detail"] if has else how})
	_mark_current(options, ids, Run.advantage)
	menu.open_choice("A CARROÇA", "LEVE UMA COISA. O RESTO FICA PARA A PRÓXIMA VEZ.", options, func(i: int) -> void:
		Run.advantage = ids[i]
		Meta.pick("pick_advantage", ids[i])
		Sfx.play("unlock", -6.0))
	menu.select(ids.find(Run.advantage))


# Marca o que está em uso, como nos mantos.
func _mark_current(options: Array[Dictionary], ids: Array[String], current: String) -> void:
	var at := ids.find(current)
	if at >= 0:
		options[at]["label"] = String(options[at]["label"]) + "  ·  EM USO"
		options[at]["color"] = Palette.GOLD


func open_marks() -> void:
	var options: Array[Dictionary] = [
		{"label": "CONQUISTAS", "price": "%d/%d" % [Meta.feats_done(), Catalog.FEATS.size()], "detail": "O QUE FICOU GRAVADO"},
		{"label": "ESTATÍSTICAS", "detail": "PARTIDAS, MORTES E QUEM TE MATOU"},
		{"label": "CÓDICE", "detail": "INSCRIÇÕES E CRIATURAS"},
	]
	menu.open_choice("AS MARCAS", "", options, _on_marks_pick)


func _on_marks_pick(i: int) -> void:
	match i:
		0:
			open_feats.call_deferred()
		1:
			menu.open_text.call_deferred("ESTATÍSTICAS", Meta.stats_text())
		2:
			open_codex.call_deferred()


func open_feats() -> void:
	var options: Array[Dictionary] = []
	for f: Dictionary in Catalog.FEATS:
		var done := Meta.feat_achieved(f)
		var hidden: bool = f.get("secret", false) and not done
		var reward := ""
		for a: Dictionary in Catalog.ADVANTAGES:
			if a.get("needs", "") == f["id"]:
				reward = "   ·   LIBERA " + String(a["title"]).to_upper()
		options.append({"label": "???" if hidden else f["title"], "price": "FEITA" if done else "",
			"price_color": Palette.GOLD, "color": Palette.GOLD if done else Palette.UI_DIM,
			"detail": "AINDA NÃO" if hidden else String(f["detail"]) + reward})
	menu.open_choice("CONQUISTAS", "", options, func(_i: int) -> void:
		open_feats.call_deferred())


# Dificuldade: as brasas liberadas e, depois do final verdadeiro, os ciclos do Novo Jogo+.
func brazier_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for h in int(Meta.data["heat"]) + 1:
		options.append({"label": HEAT_NAMES[h], "detail": HEAT_DETAILS[h], "heat": h, "plus": 0,
			"color": Palette.UI_TEXT if h == 0 else Palette.BURN.lerp(Palette.HURT, h / 4.0)})
	if Meta.awake():
		for n in range(1, clampi(int(Meta.data.get("plus", 1)), 1, Run.MAX_PLUS) + 1):
			options.append({"label": "NOVO JOGO+  ·  CICLO %d" % n, "detail": "+%d%% DE VIDA E +%d%% DE DANO ALÉM DAS 4 BRASAS" % [25 * n, 15 * n],
				"heat": Run.MAX_HEAT, "plus": n, "color": Palette.BURN.lerp(Palette.HURT, float(n) / Run.MAX_PLUS)})
	return options


func open_brazier() -> void:
	var options := brazier_options()
	menu.open_choice("O BRASEIRO", "QUANTO MAIS BRASA, MAIS O DEUS MORTO RESISTE.", options, func(i: int) -> void:
		Run.heat = options[i]["heat"]
		Run.plus = options[i]["plus"]
		Meta.data["pick_heat"] = Run.heat
		Meta.pick("pick_plus", Run.plus)
		Sfx.play("ui_ok", -6.0))
	for i in options.size():
		if options[i]["plus"] == Run.plus and (Run.plus > 0 or options[i]["heat"] == Run.heat):
			menu.select(i)


# Passou do arco: agora é partida.
func _depart() -> void:
	_playing = false
	if Run.plus > 0:
		Music.play("passagem")
		cutscene.play(PackedStringArray(Story.PLUS_INTRO), func() -> void:
			Run.depart()
			_load_stage())
		return
	Run.depart()
	_load_stage()


func open_codex() -> void:
	var lore: Array = Meta.data["lore"]
	var known := Meta.known_creatures()
	var options: Array[Dictionary] = [
		{"label": "INSCRIÇÕES  ·  %d LIDAS" % lore.size(), "detail": "O QUE AS PEDRAS CONTAM"},
		{"label": "BESTIÁRIO  ·  %d DE %d" % [known.size(), Story.BESTIARY.size()], "detail": "O QUE VOCÊ JÁ DERROTOU"},
		{"label": "REVER A ABERTURA", "detail": ""},
	]
	if Meta.awake():
		options.append({"label": "REVER O FINAL", "detail": "O QUE ACONTECEU COM OS DEUSES"})
		options.append({"label": "OS TREZE", "detail": "O DESFECHO DE CADA UM"})
	menu.open_choice("CÓDICE", "", options, _on_codex_pick)


func _on_codex_pick(i: int) -> void:
	match i:
		0:
			_codex_lore.call_deferred()
		1:
			_codex_bestiary.call_deferred()
		2:
			cutscene.play.call_deferred(PackedStringArray(Story.INTRO), Callable())
		3:
			var pages := PackedStringArray(Story.REVEAL)
			pages.append_array(Story.FINAL)
			cutscene.play.call_deferred(pages, Callable())
		4:
			_codex_gods.call_deferred()


func _codex_gods() -> void:
	var lines := PackedStringArray()
	for id: String in Story.SEATS:
		lines.append("%s: %s" % [Story.god_name(id), Story.SEATS[id]])
	menu.open_text("OS TREZE", "\n\n".join(lines))


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


func start_run(seed_value := -1, heat := 0, plus := 0) -> void:
	Run.new_run(seed_value, heat, plus)
	_load_stage()


func _load_stage() -> void:
	ambience.modulate.a = 1.0
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
		"sala":
			level.build_hall(b, Run.stage_seed())
			foreground.style = ""
			weather.kind = "stars"
			Music.play("passagem")
		"beira":
			level.build_beira(b, Run.stage_seed())
			foreground.style = ""
			weather.kind = b.weather
			Music.play("passagem")
			level.station_used.connect(_on_station)
		"ondas":
			level.build_waves(b, Run.stage_seed(), Run.wave_block)
			foreground.style = ""
			weather.kind = b.weather
			Music.play(b.id)
			level.guardian_appeared.connect(func(g: Enemy) -> void:
				hud.show_boss(g)
				Music.play("chefe_final" if b.id == "mar_de_cinzas" else "chefe"))
			level.boss_defeated.connect(func() -> void: Music.play(b.id))
		_:
			level.build_generated(b, Run.stage_seed())
			weather.kind = b.weather
			Music.play(b.id)
	map_view.level = level
	Run.stage_tier = level.tier
	weather.player = level.player
	Run.load_player(level.player)
	# na Beira ainda não há partida: nada para continuar, nem relógio
	if stage["kind"] != "beira":
		Run.suspend()
	hud.bind(level.player, level.boss)
	guide.bind(level)
	level.player.died.connect(_on_player_died)
	# a saída é usada no meio do passo de física do herói: troca de andar no fim do quadro
	level.exit_used.connect(_on_exit, CONNECT_DEFERRED)
	_playing = true
	# o relógio só corre entre o arco da Beira e o Imperador
	Run.active = stage["kind"] != "sala" and stage["kind"] != "beira"
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
	if dest == "partida":
		_depart()
		return
	Run.save_player(level.player)
	match dest:
		"fim":
			_playing = false
			Run.active = false
			Run.discard_saved()
			Meta.record_run(true, level.player.kills)
			Meta.record_heat_win(Run.heat)
			if Run.plus > 0:
				Meta.record_plus_win(Run.plus)
			Run.set_meta("record", Meta.record_stats(true))
			var hero := level.player
			Music.play("passagem")
			if Run.plus > 0:
				cutscene.play(PackedStringArray(Story.PLUS_ENDING), func() -> void:
					screen.show_victory(hero)
					Music.play("titulo"))
			elif Run.heat >= Run.MAX_HEAT:
				# a porta abre: o herói atravessa e anda até as cadeiras
				cutscene.play(Story.ending_pages(Run.heat), func() -> void:
					Run.stage_id = Run.HALL
					_load_stage())
			else:
				cutscene.play(Story.ending_pages(Run.heat), func() -> void:
					screen.show_victory(hero)
					Music.play("titulo"))
			return
		"descanso":
			# a virada: depois dela o herói ainda precisa apagar a última brasa com as próprias mãos
			get_tree().paused = true
			cutscene.play(PackedStringArray(Story.REVEAL), func() -> void:
				get_tree().paused = false
				level.hall_reveal())
			return
		"soltar":
			_playing = false
			Run.active = false
			Run.discard_saved()
			Meta.wake()
			var hero := level.player
			Music.play("passagem")
			cutscene.play(PackedStringArray(Story.FINAL), func() -> void:
				screen.show_victory(hero, true)
				Music.play("titulo"))
			return
		"passagem":
			Run.enter_passage()
		"ondas":
			Run.next_block()
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
	var best_before := int(Meta.data.get("best_wave", 0))
	Meta.record_run(false, level.player.kills)
	Meta.record_stats(false)
	var place := level.biome.title if level.biome else "TREINO"
	if level.is_boss_room:
		place = "O Trono do Imperador Cego"
	if Run.mode == Run.WAVES:
		place = "WAVE %d" % Run.wave
	screen.show_death(level.player, place)
	if Run.mode == Run.WAVES:
		screen.lines.append(["NOVO RECORDE" if Run.wave > best_before else "RECORDE: WAVE %d" % best_before, Palette.GOLD])
	Music.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		Fx.debug = not Fx.debug
	elif event.is_action_pressed("reset") and _playing and Run.stage_id != Run.HALL and Run.stage_id != Run.BEIRA:
		enter_beira()
	elif event.is_action_pressed("pause") and _playing and not menu.is_open() and not options_screen.is_open():
		_pause()


func _pause() -> void:
	if Run.stage_id == Run.BEIRA:
		var calm: Array[Dictionary] = [
			{"label": "CONTINUAR", "detail": ""},
			{"label": "OPÇÕES", "detail": "SOM, TELA, TREMOR, TECLAS"},
			{"label": "COMANDOS", "detail": "TECLADO E CONTROLE"},
			{"label": "VOLTAR AO TÍTULO", "detail": ""},
		]
		_pause_with_feedback(calm)
		menu.open_choice("PAUSA", "", calm, _on_pause_pick)
		return
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
	if Run.plus > 0:
		info += "   ·   CICLO %d" % Run.plus
	for id: String in Run.rules:
		info += ("   ·   " if info != "" else "") + String(Run.rule(id)["title"]).to_upper()
	_pause_with_feedback(options)
	menu.open_choice("PAUSA", info, options, _on_pause_pick)


const PAUSE_FEEDBACK := "BUG OU SUGESTÃO"
var _pause_count := 0


# no navegador a pausa ganha um atalho para mandar bug ou sugestão (sempre o último item)
func _pause_with_feedback(options: Array[Dictionary]) -> void:
	if OS.has_feature("web"):
		options.append({"label": PAUSE_FEEDBACK, "detail": "ABRE EM OUTRA ABA"})
	_pause_count = options.size()


func _on_pause_pick(i: int) -> void:
	if OS.has_feature("web") and i == _pause_count - 1:
		open_site_page(Screen.WEB_PAGES["feedback"])
		return
	if i == 1:
		options_screen.open.call_deferred()
	elif i == 2:
		menu.open_text.call_deferred("COMANDOS", CONTROLS)
	elif i == 3:
		_show_title()
	elif i == 4:
		Run.discard_saved()
		# na sala a partida já foi contada como vitória
		if Run.stage_id != Run.HALL:
			Meta.record_run(false, level.player.kills)
			Meta.record_stats(false)
		_show_title()


const CONTROLS := "M OU TAB (SEGURE): MAPA\nA / D  OU SETAS: ANDAR\nESPAÇO: PULAR (SEGURE PARA PULAR MAIS ALTO)\nJ: ARMA 1   K: ARMA 2   (MOUSE: ESQUERDO E DIREITO)\nU: HABILIDADE 1   I: HABILIDADE 2\nSHIFT: ROLAR (INVENCÍVEL DURANTE A ROLAGEM)\nS + J NO AR: MERGULHO\nS + ESPAÇO: DESCER DA PLATAFORMA\nQ: BEBER FRASCO   E: USAR / PEGAR\nESC: PAUSA   F1: DEBUG\n\nCONTROLE: A PULA, X E Y ARMAS, LB E RB HABILIDADES, B OU RT ROLA, LT CURA, CIMA USA"
