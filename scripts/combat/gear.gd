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


func stat() -> String:
	return data.stat
