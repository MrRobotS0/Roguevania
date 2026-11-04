class_name Keeper
extends Interactable

# A Vigia: guardiã sem rosto que fica entre as regiões. Troca Essência por
# desbloqueios permanentes e enche os frascos uma vez.

const LINES := [
	"MOKSHA. VOCÊ DE NOVO. OU OUTRO IGUAL A VOCÊ. É DIFÍCIL DIZER.",
	"A ESSÊNCIA É O QUE SOBRA QUANDO ALGO MORRE ACREDITANDO. TRAGA MAIS.",
	"EU VIGIO A PASSAGEM DESDE QUE OS DEUSES SAÍRAM POR ELA.",
]

var refilled := false
var _body: Sprite2D


func _ready() -> void:
	super._ready()
	Glow.attach(self, Palette.ESSENCE, 50.0, 0.7, Vector2(13, -29))
	_body = prop("keeper")


func prompt() -> String:
	return "FALAR COM A VIGIA"


func detail() -> String:
	return "TROCA ESSÊNCIA POR DESBLOQUEIOS PERMANENTES"


func interact(p: Player) -> void:
	if not p.blueprints.is_empty():
		var fresh := Meta.learn(p.blueprints)
		p.blueprints.clear()
		Sfx.play("unlock", -4.0)
		Fx.toast("A VIGIA GUARDOU %d PLANTA%s" % [fresh, "S" if fresh != 1 else ""])
	if not refilled:
		refilled = true
		p.flasks = p.max_flasks
		p.gear_changed.emit()
		Fx.toast("FRASCOS CHEIOS")
	_open_shop(p)


func _offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in Catalog.all_gear():
		if r.starter or Meta.is_unlocked(r.id) or not Meta.knows(r.id):
			continue
		var kind := "ARMA" if r is WeaponData else "HABILIDADE"
		out.append({"id": r.id, "title": r.title, "cost": r.unlock_cost,
			"detail": "%s DE %s · PASSA A APARECER NAS PARTIDAS" % [kind, Combat.STAT_NAMES[r.stat]]})
	for s in Catalog.skins():
		if s.unlock != "essence" or Meta.is_unlocked(s.id):
			continue
		out.append({"id": s.id, "title": "Aparência: " + s.title, "cost": s.cost,
			"detail": "SÓ MUDA O VISUAL · ESCOLHA NO TÍTULO", "figure": s.colors()})
	for b: Dictionary in Catalog.BLESSINGS:
		if Meta.is_unlocked(b["id"]):
			continue
		if b.has("needs") and not Meta.is_unlocked(b["needs"]):
			continue
		out.append(b)
	return out


func _open_shop(p: Player) -> void:
	var offers := _offers()
	var options: Array[Dictionary] = []
	for o in offers:
		var cost: int = o["cost"]
		var option := {"label": "%s  ·  %d" % [o["title"], cost], "detail": o["detail"],
			"disabled": p.essence < cost, "color": Palette.ESSENCE}
		if o.has("figure"):
			option["figure"] = o["figure"]
		options.append(option)
	options.append({"label": "SAIR", "detail": "A ESSÊNCIA QUE SOBRAR SE PERDE SE VOCÊ MORRER"})
	var line: String = LINES[int(Run.time) % LINES.size()]
	menu().open_choice("A VIGIA  ·  ESSÊNCIA: %d" % p.essence, line, options,
		func(i: int) -> void:
			if i >= offers.size():
				return
			var o: Dictionary = offers[i]
			if p.essence < int(o["cost"]):
				return
			p.essence -= int(o["cost"])
			Meta.unlock(o["id"])
			p.gear_changed.emit()
			Sfx.play("unlock")
			Fx.toast("DESBLOQUEADO: " + String(o["title"]).to_upper())
			_open_shop.call_deferred(p))


func _draw() -> void:
	SpriteSheet.set_region(_body, "props", "keeper", int(_t * 2.0))
