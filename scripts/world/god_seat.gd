class_name GodSeat
extends Interactable

# Uma das cadeiras da sala depois da porta, com a brasa de um deus que não
# consegue morrer. A do deus que se escondia está fria: ele não está aqui. Ainda.

var god := ""
var line := ""
var color := Palette.GOLD
var cold := false           # sem brasa: só dá para olhar
var last_ember := false     # a brasa da Vigia: apagá-la encerra a história
var rested := false
var _flame := 1.0
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_light = Glow.attach(self, color, 44.0, 0.9, Vector2(0, -22))
	if cold:
		_flame = 0.0


func can_interact(_p: Player) -> bool:
	return visible and not rested


func prompt() -> String:
	return "OLHAR A CADEIRA FRIA" if cold else "APAGAR A BRASA"


func detail() -> String:
	return god


func interact(_p: Player) -> void:
	rested = true
	if last_ember:
		Sfx.play("portal")
		level.exit_used.emit("soltar")
		return
	Sfx.play("page", -4.0)
	if not cold:
		Fx.burst(global_position + Vector2(0, -22), color, 14, 40.0, 0.8, -40.0, 2.0)
	menu().open_text(god, line)


# A Vigia senta aqui e a brasa dela acende.
func light_up() -> void:
	cold = false
	last_ember = true
	rested = false
	_flame = 1.0
	var keeper := prop("keeper")
	keeper.position = Vector2(16, 0)


func _process(delta: float) -> void:
	super._process(delta)
	if rested and not last_ember:
		_flame = move_toward(_flame, 0.0, delta * 1.2)
	_light.energy = 0.9 * _flame


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
	if _flame <= 0.0:
		if not cold:
			draw_rect(Rect2(-2, -12, 4, 1), Color("8a8290"))
		return
	var c := color
	c.a = _flame
	var flick := 1.0 if int(_t * 7.0) % 2 == 0 else 0.0
	var tall := 7.0 * _flame
	draw_rect(Rect2(-2, -11.0 - tall, 4, tall), c)
	draw_rect(Rect2(-1 + flick, -13.0 - tall, 2, 2), c)
	var core := Palette.FLASH
	core.a = _flame
	draw_rect(Rect2(-1, -11.0 - tall * 0.5, 2, tall * 0.5), core)
