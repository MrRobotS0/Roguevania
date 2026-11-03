class_name Keeper
extends Interactable

# A Vigia: guardiã sem rosto que fica entre as regiões. Troca Essência por
# desbloqueios permanentes e enche os frascos uma vez.

const LINES := [
	"VOCÊ DE NOVO. OU OUTRO IGUAL A VOCÊ. É DIFÍCIL DIZER.",
	"A ESSÊNCIA É O QUE SOBRA QUANDO ALGO MORRE ACREDITANDO. TRAGA MAIS.",
	"EU VIGIO A PASSAGEM DESDE QUE OS DEUSES SAÍRAM POR ELA.",
]

var refilled := false


func prompt() -> String:
	return "FALAR COM A VIGIA"


func detail() -> String:
	return "TROCA ESSÊNCIA POR DESBLOQUEIOS PERMANENTES"


func interact(p: Player) -> void:
	if not refilled:
		refilled = true
		p.flasks = p.max_flasks
		p.gear_changed.emit()
		Fx.toast("FRASCOS CHEIOS")
	_open_shop(p)


func _offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in Catalog.all_gear():
		if r.starter or Meta.is_unlocked(r.id):
			continue
		var kind := "ARMA" if r is WeaponData else "HABILIDADE"
		out.append({"id": r.id, "title": r.title, "cost": r.unlock_cost,
			"detail": "%s DE %s · PASSA A APARECER NAS PARTIDAS" % [kind, Combat.STAT_NAMES[r.stat]]})
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
		options.append({"label": "%s  ·  %d" % [o["title"], cost], "detail": o["detail"],
			"disabled": p.essence < cost, "color": Palette.ESSENCE})
	options.append({"label": "SAIR", "detail": "A ESSÊNCIA QUE SOBRAR SE PERDE SE VOCÊ MORRER"})
	var line: String = LINES[int(Run.time) % LINES.size()]
	menu().open_choice("A VIGIA  ·  ESSÊNCIA: %d" % p.essence, line, options,
		func(i: int) -> void:
			if i >= offers.size():
				return
			var o: Dictionary = offers[i]
			p.essence -= int(o["cost"])
			Meta.unlock(o["id"])
			p.gear_changed.emit()
			Sfx.play("unlock")
			Fx.toast("DESBLOQUEADO: " + String(o["title"]).to_upper())
			_open_shop.call_deferred(p))


func _draw() -> void:
	var sway := sin(_t * 1.5)
	draw_rect(Rect2(-6, -30, 12, 30), Color("2b2f3a"))
	draw_rect(Rect2(-7, -34, 14, 6), Color("1c1f27"))
	draw_rect(Rect2(-3, -31, 6, 3), Color("0b0c10"))
	var lamp := Palette.ESSENCE
	lamp.a = 0.7 + 0.3 * sin(_t * 3.0)
	draw_rect(Rect2(8, -22 + sway, 4, 5), lamp)
	draw_rect(Rect2(9, -26 + sway, 1, 4), Palette.STONE_TOP)
	draw_rect(Rect2(6, -28, 1, 28), Palette.WOOD)
