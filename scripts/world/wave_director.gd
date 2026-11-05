class_name WaveDirector
extends Node

# Modo Waves: arena fechada, inimigos em levas. A cada 5 waves o herói ganha um
# frasco; a cada 10 vem o guardião do domínio e, vencido ele, abre a parada
# (Vigia, mercador, altares) e a porta para o domínio seguinte.
#
# Quem some da conta é só quem o diretor pôs em campo: o que um inimigo invoca
# não segura a wave, e sai de cena junto quando ela acaba.

const PER_BLOCK := 10
const FLASK_EVERY := 5
const FIRST_DELAY := 1.6
const REST := 2.6             # respiro entre uma wave e outra
const TELEGRAPH := 0.55       # o aviso antes de um inimigo aparecer
const STAGGER := 0.45         # intervalo entre uma entrada e outra
const STALL := 60.0           # ninguém fica preso numa wave: daqui em diante os que restam definham
const STALL_DRAIN := 0.08     # fração da vida por segundo
const SAFE_DISTANCE := 90.0   # ninguém nasce em cima do herói
const MAX_COUNT := 16
const MAX_ALIVE := 8

var level: Level
var state := "wait"           # wait | fight | guardian | stop
var fight_time := 0.0
var _clock := FIRST_DELAY
var _spawn_clock := 0.0
var _queue: Array[Dictionary] = []
var _coming: Array[Dictionary] = []
var _field: Array[Enemy] = []
var _spots: Array[Vector2] = []


func _ready() -> void:
	_spots = _find_spots()
	Run.wave = Run.wave_block * PER_BLOCK
	Run.wave_left = 0
	level.boss_defeated.connect(_on_guardian_down)


# Todo chão ou plataforma com espaço para ficar de pé.
func _find_spots() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var room := level.room
	for y in range(1, room.rows - 1):
		for x in range(2, room.cols - 2):
			if room.grid[y][x] == "." and room.grid[y - 1][x] == "." and "#=".contains(room.grid[y + 1][x]):
				out.append(Vector2((x + 0.5) * Room.TILE, (y + 1) * Room.TILE))
	return out


func _physics_process(delta: float) -> void:
	if not is_instance_valid(level.player) or not level.player.alive():
		return
	match state:
		"wait":
			_clock -= delta
			if _clock <= 0.0:
				_begin_wave()
		"fight":
			_fight(delta)


func is_guardian_wave(wave: int) -> bool:
	return wave > 0 and wave % PER_BLOCK == 0


func _begin_wave() -> void:
	Run.wave += 1
	fight_time = 0.0
	_field.clear()
	Sfx.play("portal", -8.0)
	if is_guardian_wave(Run.wave):
		state = "guardian"
		Run.wave_left = 1
		level.spawn_guardian()
		return
	_queue = compose(Run.wave)
	Run.wave_left = _queue.size()
	state = "fight"
	var first_of_block := Run.wave % PER_BLOCK == 1
	Fx.banner("WAVE %d" % Run.wave, level.biome.title.to_upper() if first_of_block else "")


# Quantos e quem: começa em 2 e cresce. Até a wave 5 não há frasco, então o começo
# é só o domínio atual; depois entram sobras dos outros, e a arena não se repete.
func compose(wave: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := level.rng
	var count := mini(1 + ceili(wave * 0.6), MAX_COUNT)
	for i in count:
		var from := level.biome
		if wave > FLASK_EVERY and rng.randf() < 0.3:
			var group: Array = Run.WAVE_ROUTE[rng.randi_range(0, Run.WAVE_ROUTE.size() - 1)]
			from = Catalog.biome(group[rng.randi_range(0, group.size() - 1)])
		var slot := "r" if rng.randf() < 0.28 else "e"
		var path := from.pick_enemy(slot, rng)
		if path == "":
			path = from.pick_enemy("e", rng)
		if path == "":
			continue
		var elite := wave >= 6 and rng.randf() < minf(0.04 + 0.01 * wave, 0.25)
		out.append({"path": path, "elite": elite, "biome": from})
	# de 4 em 4, a partir da 8, um adversário de verdade
	if wave >= 8 and wave % 4 == 0 and not level.biome.elites.is_empty():
		out.append({"path": level.biome.elites[rng.randi_range(0, level.biome.elites.size() - 1)], "elite": true, "biome": level.biome})
	return out


func _fight(delta: float) -> void:
	fight_time += delta
	_forget_the_dead()
	for c in _coming.duplicate():
		c["t"] = float(c["t"]) - delta
		if float(c["t"]) <= 0.0:
			_coming.erase(c)
			_arrive(c)
	_spawn_clock -= delta
	var room_for := mini(2 + Run.wave / 3, MAX_ALIVE)
	if not _queue.is_empty() and _spawn_clock <= 0.0 and _field.size() + _coming.size() < room_for:
		_spawn_clock = STAGGER
		_announce(_queue.pop_front())
	Run.wave_left = _queue.size() + _coming.size() + _field.size()
	if fight_time > STALL:
		_wither(delta)
	if Run.wave_left == 0:
		_wave_cleared()


# Sem tipo no laço: quem morreu já foi liberado, e um Enemy tipado não aceita isso.
func _forget_the_dead() -> void:
	var standing: Array[Enemy] = []
	for e in _field:
		if is_instance_valid(e) and e.alive():
			standing.append(e)
	_field = standing


func _announce(entry: Dictionary) -> void:
	var at := _pick_spot()
	entry["at"] = at
	entry["t"] = TELEGRAPH
	_coming.append(entry)
	Fx.burst(at + Vector2(0, -8), Palette.DANGER, 14, 60.0, TELEGRAPH, -30.0)
	Sfx.play("ui_move", -10.0)


func _arrive(entry: Dictionary) -> void:
	var e := level.spawn_script(String(entry["path"]), entry["at"], bool(entry["elite"]))
	if bool(entry["elite"]):
		e.killed.connect(level._on_elite_killed)
	_field.append(e)


func _pick_spot() -> Vector2:
	var hero := level.player.global_position
	var far := _spots.filter(func(s: Vector2) -> bool: return s.distance_to(hero) > SAFE_DISTANCE)
	var from: Array = far if not far.is_empty() else _spots
	return from[level.rng.randi_range(0, from.size() - 1)]


# Rede de segurança: inimigo preso numa parede ou fora de alcance não trava o modo.
func _wither(delta: float) -> void:
	for e: Enemy in _field:
		var loss := maxf(1.0, e.max_hp * STALL_DRAIN * delta)
		e.hp -= ceili(loss)
		e.flash = 0.05
		if e.hp <= 0:
			e._die()


func _wave_cleared() -> void:
	state = "wait"
	_clock = REST
	_clear_leftovers()
	Fx.toast("WAVE %d VENCIDA" % Run.wave)
	Sfx.play("unlock", -8.0)
	_reward(Run.wave)


# O que foi invocado e ficou para trás some junto com a wave.
func _clear_leftovers() -> void:
	for n in level.enemies():
		if n is Enemy and n != level.boss:
			Fx.burst(n.center(), Palette.DUST, 8, 60.0, 0.4, -20.0)
			n.remove_from_group("enemies")
			n.queue_free()


func _reward(wave: int) -> void:
	if wave % FLASK_EVERY == 0:
		level.player.gain_flask()
		Fx.toast("FRASCO DE CURA  ·  %d USOS" % Run.FLASK_USES)
		Sfx.play("drink", -6.0)
	var step := wave % PER_BLOCK
	if step == 3 or step == 7:
		var item := Pickup.new()
		item.gear = Catalog.random_gear(level.rng, level.tier)
		level._place(item, _floor_at(level.rng.randf_range(90.0, 390.0)))
	elif step == 5:
		level._place(Altar.new(), _floor_at(level.rng.randf_range(90.0, 390.0)))


func _floor_at(x: float) -> Vector2:
	return Vector2(x, (level.room.rows - 4) * Room.TILE)


func _on_guardian_down() -> void:
	state = "stop"
	Run.wave_left = 0
	_clear_leftovers()
	_reward(Run.wave)
	# a parada: quem vende, quem guarda e a porta. Nada aqui enche frasco.
	level._place(Keeper.new(), _floor_at(64.0))
	level._place(Merchant.new(), _floor_at(144.0))
	level._place(MutationAltar.new(), _floor_at(232.0))
	level._place(Altar.new(), _floor_at(320.0))
	level.place_gate("Próximo domínio", "ondas", _floor_at(416.0))
