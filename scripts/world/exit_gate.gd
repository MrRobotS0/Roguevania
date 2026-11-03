class_name ExitGate
extends Interactable

# Saída para a próxima região. Saídas seladas mostram para onde o mundo
# vai crescer (biomas ainda não feitos).

signal used(dest: String)

var title := ""
var dest := ""
var sealed := false
var hint := ""
var _frame: Sprite2D


var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_light = Glow.attach(self, Palette.ESSENCE, 64.0, 0.0, Vector2(0, -18))
	_frame = prop("gate")


func prompt() -> String:
	return ("SELADO: " if sealed else "ENTRAR: ") + title.to_upper()


func detail() -> String:
	return "A PASSAGEM AINDA NÃO SE ABRIU" if sealed else hint


func interact(_p: Player) -> void:
	if sealed:
		Sfx.play("block", -6.0)
		return
	Sfx.play("portal")
	used.emit(dest)


func _draw() -> void:
	_light.energy = 0.0 if sealed or not visible else 0.8 + 0.15 * sin(_t * 3.0)
	SpriteSheet.set_region(_frame, "props", "gate", 1 if sealed else 0)
	if sealed:
		return
	var core := Palette.ESSENCE
	core.a = 0.4 + 0.2 * sin(_t * 3.0)
	draw_rect(Rect2(-8, -36, 16, 36), core)
	for i in 5:
		var y := -fmod(_t * 18.0 + i * 7.0, 36.0)
		draw_rect(Rect2(-6 + i * 3, y, 1, 3), Palette.FLASH)
