class_name MutationAltar
extends Interactable

# Altar das passagens: escolhe uma mutação (bônus que dura só esta partida).
# Três opções sorteadas entre as que o herói ainda não tem; no máximo três.

var used := false
var _body: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_body = prop("mutation_altar")
	_light = Glow.attach(self, Color("b8f06a"), 48.0, 0.7, Vector2(0, -18))


func can_interact(p: Player) -> bool:
	return visible and not used and p.mutations.size() < Catalog.MAX_MUTATIONS


func prompt() -> String:
	return "BEBER DO ALTAR"


func detail() -> String:
	return "UMA MUTAÇÃO PARA ESTA PARTIDA"


func choices(p: Player) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for m: Dictionary in Catalog.MUTATIONS:
		if not p.has_mutation(m["id"]):
			pool.append(m)
	var rng := RandomNumberGenerator.new()
	rng.seed = Run.stage_seed() + 17
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, 3)


func interact(p: Player) -> void:
	var picks := choices(p)
	var options: Array[Dictionary] = []
	for m in picks:
		options.append({"label": m["title"], "detail": m["detail"], "color": Color("b8f06a")})
	menu().open_choice("MUTAÇÃO", "O QUE O DEUS DEIXOU NO FUNDO DO CÁLICE. VALE ATÉ VOCÊ MORRER.", options,
		func(i: int) -> void:
			p.add_mutation(picks[i]["id"])
			used = true
			Sfx.play("fragment")
			Fx.burst(global_position + Vector2(0, -16), Color("b8f06a"), 18, 100.0, 0.6, -40.0)
			Fx.toast(String(picks[i]["title"]).to_upper()), false)


func _draw() -> void:
	SpriteSheet.set_region(_body, "props", "mutation_altar", 1 if used else 0)
	_light.energy = 0.0 if used else 0.6 + 0.15 * sin(_t * 3.0)
	if not used:
		for i in 3:
			var k := fposmod(_t * 0.6 + i * 0.33, 1.0)
			var c := Color("b8f06a")
			c.a = 1.0 - k
			draw_rect(Rect2(-3 + i * 3, -16 - k * 14, 1, 2), c)
