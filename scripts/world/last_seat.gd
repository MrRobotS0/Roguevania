class_name LastSeat
extends Interactable

# A décima terceira cadeira: a do deus que ardeu, com o nome do herói gravado.
# Só dá para sentar depois de olhar todas as outras.

var sat := false
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_light = Glow.attach(self, Palette.GOLD, 40.0, 0.0, Vector2(0, -18))


func can_interact(_p: Player) -> bool:
	return visible and not sat


func prompt() -> String:
	return "SENTAR" if _left() == 0 else "A CADEIRA COM O SEU NOME"


func detail() -> String:
	var left := _left()
	if left == 0:
		return "O DEUS QUE ARDEU"
	return "FALTAM %d CADEIRAS" % left if left != 1 else "FALTA UMA CADEIRA"


func interact(_p: Player) -> void:
	if _left() > 0:
		Sfx.play("block", -6.0)
		return
	sat = true
	Sfx.play("portal")
	level.exit_used.emit("descanso")


func _left() -> int:
	return level.seats_left() if level else 12


func _process(delta: float) -> void:
	super._process(delta)
	_light.energy = 0.8 + 0.15 * sin(_t * 2.0) if _left() == 0 and not sat else 0.12


func _draw() -> void:
	var stone := Color("4a4252")
	var dark := Color("2a2432")
	var edge := Color("6b6178")
	draw_rect(Rect2(-7, -30, 14, 20), stone)
	draw_rect(Rect2(-7, -30, 14, 1), edge)
	draw_rect(Rect2(-5, -28, 10, 16), dark)
	draw_rect(Rect2(-9, -11, 18, 3), edge)
	draw_rect(Rect2(-8, -8, 2, 8), dark)
	draw_rect(Rect2(6, -8, 2, 8), dark)
	# cinza no assento e o nome gravado: um risco de ouro na pedra
	draw_rect(Rect2(-6, -12, 12, 1), Color("8a8290"))
	var gold := Palette.GOLD
	gold.a = 0.55 + 0.4 * sin(_t * 2.0) if _left() == 0 else 0.45
	draw_rect(Rect2(-3, -24, 6, 1), gold)
