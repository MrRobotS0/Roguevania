class_name ExitGate
extends Interactable

# Saída para a próxima região. Saídas seladas mostram para onde o mundo
# vai crescer (biomas ainda não feitos).

signal used(dest: String)

var title := ""
var dest := ""
var sealed := false


func prompt() -> String:
	return ("SELADO: " if sealed else "ENTRAR: ") + title.to_upper()


func detail() -> String:
	return "A PASSAGEM AINDA NÃO SE ABRIU" if sealed else ""


func interact(_p: Player) -> void:
	if sealed:
		Sfx.play("block", -6.0)
		return
	Sfx.play("portal")
	used.emit(dest)


func _draw() -> void:
	var frame := Palette.STONE_TOP if not sealed else Palette.STONE
	draw_rect(Rect2(-10, -34, 3, 34), frame)
	draw_rect(Rect2(7, -34, 3, 34), frame)
	draw_rect(Rect2(-11, -37, 22, 4), frame)
	if sealed:
		draw_rect(Rect2(-7, -33, 14, 33), Palette.STONE_DEEP)
		draw_rect(Rect2(-1, -26, 2, 12), Palette.UI_FRAME)
		return
	var core := Palette.ESSENCE
	core.a = 0.45 + 0.2 * sin(_t * 3.0)
	draw_rect(Rect2(-7, -33, 14, 33), core)
	for i in 4:
		var y := -fmod(_t * 18.0 + i * 8.0, 33.0)
		draw_rect(Rect2(-4 + i * 2, y, 1, 3), Palette.FLASH)
