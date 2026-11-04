class_name Merchant
extends Interactable

# Mercador de passagem: troca ouro por armas, cura e frascos. O estoque é
# sorteado quando a fase nasce; o que se compra aparece no chão, ao lado.

var _stock: Array[Dictionary] = []
var _body: Sprite2D


func _ready() -> void:
	super._ready()
	_body = prop("merchant")
	Glow.attach(self, Palette.GOLD, 40.0, 0.5, Vector2(10, -14))


func prompt() -> String:
	return "NEGOCIAR COM O MERCADOR"


func detail() -> String:
	return "TROCA OURO POR ARMAS E CURA"


func stock() -> Array[Dictionary]:
	if _stock.is_empty():
		var lv: Level = level
		var taken: Array = []
		for i in 3:
			var g := Catalog.random_gear(lv.rng, lv.tier + 1, taken)
			taken.append(g.data.id)
			_stock.append({"kind": "gear", "gear": g, "cost": 55 + 30 * g.tier + 10 * lv.tier})
		_stock.append({"kind": "heal", "cost": 40 + 10 * lv.tier})
		_stock.append({"kind": "flask", "cost": 75 + 15 * lv.tier})
	return _stock


func interact(p: Player) -> void:
	var options: Array[Dictionary] = []
	var items := stock()
	for o in items:
		var cost := price(o, p)
		var label := ""
		var detail_text := ""
		var icon: Texture2D = null
		match o["kind"]:
			"gear":
				var g: Gear = o["gear"]
				label = g.title()
				icon = GearIcon.of(g.data)
				detail_text = "%s DE %s" % ["ARMA" if g.is_weapon() else "HABILIDADE", Combat.STAT_NAMES[g.stat()]]
			"heal":
				label = "Pão de Cinza"
				icon = GearIcon.named("pao")
				detail_text = "CURA METADE DA VIDA AGORA"
			"flask":
				label = "Frasco Extra"
				icon = GearIcon.named("frasco")
				detail_text = "+1 FRASCO DE CURA NESTA PARTIDA"
		var sold: bool = o.get("sold", false)
		options.append({"label": "%s  ·  %d OURO" % [label, cost] if not sold else label + "  ·  VENDIDO",
			"detail": detail_text, "disabled": sold or p.gold < cost, "color": Palette.GOLD, "icon": icon})
	options.append({"label": "SAIR", "detail": "OURO: %d" % p.gold})
	menu().open_choice("O MERCADOR", "\"TUDO TEM PREÇO. ATÉ O QUE CAIU DO CÉU.\"", options,
		func(i: int) -> void:
			if i >= items.size():
				return
			_buy(p, items[i])
			interact.call_deferred(p))


func price(o: Dictionary, p: Player) -> int:
	var cost: int = o["cost"]
	return roundi(cost * 0.7) if p.has_mutation("barganha") else cost


func _buy(p: Player, o: Dictionary) -> void:
	if p.gold < price(o, p) or o.get("sold", false):
		return
	p.gold -= price(o, p)
	o["sold"] = true
	match o["kind"]:
		"gear":
			var item := Pickup.new()
			item.gear = o["gear"]
			item.level = level
			item.position = global_position + Vector2(22, 0)
			level.add_child(item)
		"heal":
			p.heal(p.max_hp / 2)
		"flask":
			p.max_flasks += 1
			p.flasks += 1
	Sfx.play("merchant_buy", -4.0)
	p.gear_changed.emit()


func _draw() -> void:
	SpriteSheet.set_region(_body, "props", "merchant", int(_t * 2.0))
