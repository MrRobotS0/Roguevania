class_name Inscription
extends Interactable

# Pedra com texto: a história é contada aos pedaços, pelo cenário.

var text := ""
var read := false


func prompt() -> String:
	return "LER A INSCRIÇÃO"


func interact(_p: Player) -> void:
	read = true
	Sfx.play("page", -4.0)
	menu().open_text("INSCRIÇÃO", text)


func _draw() -> void:
	draw_rect(Rect2(-6, -18, 12, 18), Palette.STONE)
	draw_rect(Rect2(-6, -18, 12, 1), Palette.STONE_LIGHT)
	var ink := Palette.GOLD if not read else Palette.UI_DIM
	ink.a = 0.6 + 0.3 * sin(_t * 2.0) if not read else 0.5
	for i in 4:
		draw_rect(Rect2(-4, -15 + i * 4, 3 + (i * 5) % 6, 1), ink)
