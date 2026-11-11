class_name ChallengeStone
extends Interactable

# Evento: a Pedra do Desafio. Despertada, chama levas de inimigos do domínio
# em volta dela (a última com um elite). Quem vence todas leva um item
# melhor, ouro e Essência. Recusar não custa nada.

const WAVES := 2
const WAVE_GAP := 0.9

var started := false
var done := false
var _wave := 0
var _spawned: Array = []
var _gap := 0.0
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	prop("stele")
	_light = Glow.attach(self, Palette.DANGER, 48.0, 0.7, Vector2(0, -18))


func can_interact(_p: Player) -> bool:
	return visible and not started


func prompt() -> String:
	return "DESPERTAR A PEDRA DO DESAFIO"


func detail() -> String:
	return "LEVAS DE INIMIGOS · RECOMPENSA MELHOR"


func interact(_p: Player) -> void:
	var options: Array[Dictionary] = [
		{"label": "DESPERTAR", "detail": "%d LEVAS DE INIMIGOS SURGEM EM VOLTA" % WAVES, "color": Palette.DANGER},
		{"label": "DEIXAR QUIETA", "detail": ""},
	]
	menu().open_choice("PEDRA DO DESAFIO", "\"PROVE QUE AINDA SABE LUTAR.\"", options, func(i: int) -> void:
		if i == 0:
			_begin())


func _begin() -> void:
	started = true
	Sfx.play("omen")
	Fx.add_shake(3.0)
	Fx.toast("O DESAFIO COMEÇOU")
	_next_wave()


func _next_wave() -> void:
	_wave += 1
	var lv: Level = level
	var count := 2 + mini(lv.tier, 4) / 2 + (_wave - 1)
	_spawned.clear()
	for i in count:
		var path := lv.biome.pick_enemy("e", lv.rng) if lv.biome else ""
		if path == "":
			path = "res://scripts/enemies/grunt.gd"
		var side := -1.0 if i % 2 == 0 else 1.0
		var at := spot(side * (40.0 + 22.0 * float(i / 2)))
		var e := lv.spawn_script(path, at, _wave == WAVES and i == 0)
		e.face_player.call_deferred()
		_spawned.append(e)
		Fx.burst(at + Vector2(0, -10), Palette.DANGER, 14, 120.0, 0.5)


# Um lugar com chão perto da pedra, a `dx` px dela (volta em direção à pedra
# se ali for parede ou buraco).
func spot(dx: float) -> Vector2:
	var lv: Level = level
	var t := Room.TILE
	var x := global_position.x + dx
	var ty := floori((global_position.y - 8.0) / t)
	for i in 16:
		var tx := floori(x / t)
		var floor_ok := lv.room.is_solid(tx, ty + 1) or lv.room.is_platform_at(Vector2(x, global_position.y + 2.0))
		if floor_ok and not lv.room.is_solid(tx, ty) and not lv.room.is_solid(tx, ty - 1):
			return Vector2(x, global_position.y)
		x -= signf(dx) * 6.0
	return global_position


func _process(delta: float) -> void:
	super._process(delta)
	if not started or done:
		return
	var left := _spawned.filter(func(e: Variant) -> bool: return is_instance_valid(e) and (e as Enemy).alive())
	if not left.is_empty():
		return
	_gap += delta
	if _gap < WAVE_GAP:
		return
	_gap = 0.0
	if _wave < WAVES:
		Fx.toast("LEVA %d DE %d" % [_wave + 1, WAVES])
		_next_wave()
	else:
		_reward()


func _reward() -> void:
	done = true
	var lv: Level = level
	var item := Pickup.new()
	item.gear = Catalog.random_gear(lv.rng, lv.tier + 1)
	item.level = lv
	item.position = global_position + Vector2(20, 0)
	lv.add_child.call_deferred(item)
	lv.drop_gold(global_position + Vector2(0, -16), 25 * (1 + lv.tier))
	lv.drop_orbs(global_position + Vector2(0, -16), 10 + 4 * lv.tier, "essence")
	Fx.burst(global_position + Vector2(0, -16), Palette.GOLD, 24, 140.0, 0.6, -40.0)
	Sfx.play("fragment")
	Fx.toast("DESAFIO VENCIDO")


func _draw() -> void:
	if done:
		_light.energy = 0.0
		return
	var k := 0.5 + 0.5 * sin(_t * (6.0 if started else 2.5))
	var c := Palette.DANGER
	c.a = 0.35 + 0.45 * k
	draw_rect(Rect2(-2, -26, 4, 8), c)
	draw_rect(Rect2(-4, -22, 8, 2), c)
	if started:
		PixelFont.draw_centered(self, "%d/%d" % [_wave, WAVES], Vector2(0, -38), Palette.DANGER)
