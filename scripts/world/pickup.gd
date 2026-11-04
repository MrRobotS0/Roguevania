class_name Pickup
extends Interactable

# Arma ou habilidade num pedestal. Pegar troca pelo que está no slot;
# o item velho fica no chão.

var gear: Gear
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_light = Glow.attach(self, gear.data.color, 44.0, 0.7, Vector2(0, -16))
	prop("pedestal")


func prompt() -> String:
	return "PEGAR " + gear.title()


func detail() -> String:
	var stat: String = Combat.STAT_NAMES.get(gear.stat(), "")
	var kind := "ARMA" if gear.is_weapon() else "HABILIDADE"
	var extra: String = gear.affix_text() if not gear.affixes.is_empty() else gear.data.describe()
	return "%s DE %s%s" % [kind, stat, (" · " + extra) if extra != "" else ""]


func interact(p: Player) -> void:
	var old := p.equip(gear)
	Sfx.play("pickup")
	Fx.burst(global_position + Vector2(0, -10), gear.data.color, 10, 80.0, 0.4, -60.0)
	if old:
		gear = old
		_light.color = gear.data.color
		_t = 0.0
	else:
		queue_free()


func _draw() -> void:
	var bob := sin(_t * 3.0) * 2.0
	var glow: Color = gear.data.color
	glow.a = 0.25 + 0.15 * sin(_t * 4.0)
	draw_rect(Rect2(-6, -24 + bob, 12, 14), glow)
	var c: Color = gear.data.color
	var tex := GearIcon.of(gear.data)
	if tex:
		draw_texture(tex, Vector2(-8, roundf(-25 + bob)))
	elif gear.is_weapon():
		var data: WeaponData = gear.data
		match data.category:
			"bow":
				draw_rect(Rect2(-1, -22 + bob, 1, 12), Palette.WOOD_TOP)
				draw_rect(Rect2(2, -21 + bob, 1, 10), c)
			_:
				draw_rect(Rect2(-1, -24 + bob, 2, 13), c)
				draw_rect(Rect2(-3, -13 + bob, 6, 1), Palette.GOLD)
	else:
		draw_rect(Rect2(-4, -20 + bob, 8, 8), c)
		draw_rect(Rect2(-2, -18 + bob, 4, 4), c.lightened(0.4))
	if gear.tier > 0:
		PixelFont.draw_centered(self, "+%d" % gear.tier, Vector2(0, -30 + bob), Palette.GOLD)
