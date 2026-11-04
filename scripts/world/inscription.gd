class_name Inscription
extends Interactable

# Pedra com texto: a história é contada aos pedaços, pelo cenário.

var text := ""
var read := false
var _stone: Sprite2D


var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_light = Glow.attach(self, Palette.GOLD, 26.0, 0.5, Vector2(0, -12))
	_stone = prop("stele")


func prompt() -> String:
	return "LER A INSCRIÇÃO"


func interact(_p: Player) -> void:
	read = true
	Sfx.play("page", -4.0)
	if Meta.note_lore(text):
		pass
	menu().open_text("INSCRIÇÃO", text)


func _draw() -> void:
	_light.energy = 0.0 if read else 0.4 + 0.15 * sin(_t * 2.0)
	SpriteSheet.set_region(_stone, "props", "stele", 1 if read else 0)
