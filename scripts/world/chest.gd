class_name Chest
extends Interactable

# Baú: ouro e às vezes uma arma. O maldito paga muito melhor, mas enquanto
# a maldição durar qualquer golpe mata (some depois de alguns abates).

const CURSE_KILLS := 10

var cursed := false
var opened := false
var _body: Sprite2D


func _ready() -> void:
	super._ready()
	_body = prop("chest_cursed" if cursed else "chest")
	if cursed:
		Glow.attach(self, Color("8f5fd0"), 40.0, 0.7, Vector2(0, -8))


func can_interact(_p: Player) -> bool:
	return visible and not opened


func prompt() -> String:
	return "ABRIR O BAÚ MALDITO" if cursed else "ABRIR O BAÚ"


func detail() -> String:
	return "TESOURO MELHOR · QUALQUER GOLPE MATA ATÉ %d ABATES" % CURSE_KILLS if cursed else ""


func interact(p: Player) -> void:
	if not cursed:
		_open(p)
		return
	var options: Array[Dictionary] = [
		{"label": "ABRIR", "detail": "QUALQUER GOLPE MATA ATÉ VOCÊ DERROTAR %d INIMIGOS" % CURSE_KILLS, "color": Color("c08fff")},
		{"label": "DEIXAR FECHADO", "detail": ""},
	]
	menu().open_choice("BAÚ MALDITO", "UMA VOZ PROMETE MUITO. NÃO DIZ O PREÇO.", options, func(i: int) -> void:
		if i == 0:
			p.curse = CURSE_KILLS
			Sfx.play("curse")
			_open(p))


func _open(p: Player) -> void:
	opened = true
	SpriteSheet.set_region(_body, "props", "chest_cursed" if cursed else "chest", 1)
	Sfx.play("pickup")
	var lv: Level = level
	var bonus := 2 if cursed else 0
	lv.drop_gold(global_position + Vector2(0, -10), (12 + lv.rng.randi_range(0, 10)) * (1 + lv.tier) * (3 if cursed else 1))
	if cursed or lv.rng.randf() < 0.45:
		var item := Pickup.new()
		item.gear = Catalog.random_gear(lv.rng, lv.tier + bonus)
		item.level = lv
		item.position = global_position + Vector2(18, 0)
		lv.add_child.call_deferred(item)
	if lv.rng.randf() < (0.5 if cursed else 0.12):
		lv.drop_blueprint(global_position + Vector2(0, -14))
	Fx.burst(global_position + Vector2(0, -10), Palette.GOLD, 16, 110.0, 0.5, 200.0)
	p.gear_changed.emit()
