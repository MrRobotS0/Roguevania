class_name PactAltar
extends Interactable

# Evento: o Altar do Pacto. Cobra em sangue (parte da vida máxima, mas nunca
# mata: sobra pelo menos 1) e dá um item dois níveis acima do andar.

const PRICE := 0.3
const BLOOD := Color("c0303a")

var used := false
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	prop("pedestal")
	_light = Glow.attach(self, BLOOD, 52.0, 0.8, Vector2(0, -22))


func can_interact(_p: Player) -> bool:
	return visible and not used


func prompt() -> String:
	return "OFERECER SANGUE AO ALTAR"


func detail() -> String:
	return "CUSTA %d%% DA VIDA MÁXIMA · ITEM MUITO MELHOR" % roundi(PRICE * 100.0)


func cost(p: Player) -> int:
	return roundi(p.max_hp * PRICE)


func interact(p: Player) -> void:
	var options: Array[Dictionary] = [
		{"label": "PAGAR %d DE VIDA" % cost(p), "detail": "NUNCA MATA: SOBRA PELO MENOS 1", "color": Color("ff6070")},
		{"label": "RECUSAR", "detail": ""},
	]
	menu().open_choice("ALTAR DO PACTO", "\"SANGUE POR FERRO. É UMA TROCA JUSTA.\"", options, func(i: int) -> void:
		if i == 0:
			pay(p))


func pay(p: Player) -> void:
	if used:
		return
	used = true
	p.hp = maxi(1, p.hp - cost(p))
	p.health_changed.emit(p.hp, p.max_hp)
	var lv: Level = level
	var item := Pickup.new()
	item.gear = Catalog.random_gear(lv.rng, lv.tier + 2)
	item.level = lv
	item.position = global_position + Vector2(20, 0)
	lv.add_child.call_deferred(item)
	Fx.burst(p.center(), BLOOD, 18, 110.0, 0.5, 200.0)
	Fx.burst(global_position + Vector2(0, -22), BLOOD, 16, 90.0, 0.6, -40.0)
	Fx.add_shake(3.0)
	Sfx.play("curse")
	Fx.toast("O ALTAR ACEITOU")
	p.gear_changed.emit()


func _draw() -> void:
	if used:
		_light.energy = 0.0
		return
	var bob := sin(_t * 2.0) * 1.5
	var c := BLOOD
	draw_rect(Rect2(-3, -30 + bob, 6, 6), c)
	draw_rect(Rect2(-2, -31 + bob, 4, 1), c.lightened(0.3))
	draw_rect(Rect2(-1, -24 + bob, 2, 2), c.darkened(0.3))
