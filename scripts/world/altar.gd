class_name Altar
extends Interactable

# Fragmento Divino: escolhe um atributo para crescer. Todo fragmento dá
# vida extra; Vigor dá mais.

var used := false


var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_light = Glow.attach(self, Palette.GOLD, 56.0, 0.8, Vector2(0, -22))
	prop("altar")


func can_interact(_p: Player) -> bool:
	return not used


func prompt() -> String:
	return "TOCAR O FRAGMENTO DIVINO"


func detail() -> String:
	return "ESCOLHA UM ATRIBUTO PARA CRESCER"


func interact(p: Player) -> void:
	var options: Array[Dictionary] = []
	for stat: String in Combat.STATS:
		var hint: String = {
			"furia": "+15% DANO DAS ARMAS DE FÚRIA · +10 VIDA",
			"astucia": "+15% DANO DAS ARMAS DE ASTÚCIA · +10 VIDA",
			"vigor": "+15% DANO DAS ARMAS DE VIGOR · +20 VIDA",
		}[stat]
		options.append({"label": "%s  (NÍVEL %d)" % [Combat.STAT_NAMES[stat], p.levels[stat] + 1],
			"detail": hint, "color": Combat.STAT_COLORS[stat]})
	menu().open_choice("FRAGMENTO DIVINO", "UM DEUS SE PARTIU EM PEDAÇOS. ESTE É UM DELES.", options,
		func(i: int) -> void:
			var stat: String = Combat.STATS[i]
			p.add_level(stat)
			used = true
			Fx.burst(global_position + Vector2(0, -12), Combat.STAT_COLORS[stat], 20, 120.0, 0.6, -40.0)
			Sfx.play("fragment")
			Fx.toast("+1 " + Combat.STAT_NAMES[stat]), false)


func _draw() -> void:
	if used:
		_light.energy = 0.0
		return
	var bob := sin(_t * 2.5) * 2.0
	var i := int(_t * 2.0) % 3
	var c: Color = Combat.STAT_COLORS[Combat.STATS[i]]
	var glow := c
	glow.a = 0.3
	draw_rect(Rect2(-6, -28 + bob, 12, 12), glow)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -27 + bob), Vector2(4, -22 + bob),
		Vector2(0, -16 + bob), Vector2(-4, -22 + bob)]), c)
