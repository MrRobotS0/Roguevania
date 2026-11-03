class_name Gear
extends RefCounted

# Um item achado na partida: a arma/habilidade + o nível de qualidade.
# Quanto mais fundo no mundo, maior o nível que cai.

var data: Resource
var tier := 0


static func of(res: Resource, level := 0) -> Gear:
	var g := Gear.new()
	g.data = res
	g.tier = level
	return g


func is_weapon() -> bool:
	return data is WeaponData


func title() -> String:
	var t: String = data.title
	return t + (" +%d" % tier if tier > 0 else "")


func power() -> float:
	return 1.0 + 0.15 * tier


func stat() -> String:
	return data.stat
