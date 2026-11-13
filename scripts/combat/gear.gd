class_name Gear
extends RefCounted

# Um item achado na partida: a arma/habilidade + o nível de qualidade.
# Quanto mais fundo no mundo, maior o nível que cai.

var data: Resource
var tier := 0
var affixes: Array[String] = []


static func of(res: Resource, level := 0) -> Gear:
	var g := Gear.new()
	g.data = res
	g.tier = level
	return g


func is_weapon() -> bool:
	return data is WeaponData


func title() -> String:
	var t: String = data.title
	if not affixes.is_empty():
		t += " " + String(Catalog.AFFIXES[affixes[0]]["title"])
	return t + (" +%d" % tier if tier > 0 else "")


func has(affix: String) -> bool:
	return affixes.has(affix)


func affix_text() -> String:
	var parts := PackedStringArray()
	for a in affixes:
		parts.append(String(Catalog.AFFIXES[a]["detail"]))
	return " · ".join(parts)


func power() -> float:
	return 1.0 + 0.15 * tier


# Força da arma em dano por segundo do combo inteiro (ou do arco), já com o
# nível. Serve para comparar duas armas no chão: "FORÇA 34 → 41".
func strength() -> int:
	if not is_weapon():
		return 0
	var w: WeaponData = data
	var dmg := 0.0
	var time := 0.0
	if w.category == "bow":
		dmg = float(w.shot.get("damage", 0.0)) * float(w.shot.get("count", 1))
		time = float(w.shot.get("draw", 0.4)) + float(w.shot.get("recover", 0.2))
	else:
		for m: Dictionary in w.moves:
			dmg += float(m.get("damage", 0.0))
			time += float(m.get("startup", 0.0)) + float(m.get("active", 0.0)) + float(m.get("recover", 0.0))
	if time <= 0.0:
		return 0
	return roundi(dmg / time * power())


func stat() -> String:
	return data.stat
