class_name BlueprintDrop
extends Node2D

# Planta de um item trancado. Pega encostando; fica com o herói até a próxima
# Vigia, que guarda para sempre. Morreu antes, perdeu.

var item: Resource
var player: Player
var _t := 0.0
var _vy := -120.0
var _rest := false


func _ready() -> void:
	z_index = 7
	Glow.attach(self, Palette.GLASS, 30.0, 0.7)


func _physics_process(delta: float) -> void:
	_t += delta
	if not _rest:
		_vy = minf(_vy + 500.0 * delta, 200.0)
		var room: Room = player.room if is_instance_valid(player) else null
		if room and room.is_ground_at(position + Vector2(0, 4)) and _vy > 0.0:
			_rest = true
		else:
			position.y += _vy * delta
	if is_instance_valid(player) and player.alive() and player.center().distance_to(global_position) < 14.0:
		player.blueprints.append(item.id)
		player.gear_changed.emit()
		Sfx.play("blueprint", -4.0)
		Fx.burst(global_position, Palette.GLASS, 14, 90.0, 0.5, -40.0)
		Fx.toast("PLANTA: %s" % String(item.title).to_upper())
		queue_free()
	queue_redraw()


static var _paper: Stack


# A planta enrolada: papel com riscos azuis e os rolos escuros nas pontas,
# montada em fatias para girar no ar (sprite stacking).
static func _model() -> Stack:
	if _paper == null:
		var img := Image.create(8, 7, false, Image.FORMAT_RGBA8)
		var paper := Color("e8dcc0")
		img.fill_rect(Rect2i(0, 0, 8, 7), Palette.UI_SHADOW)
		img.fill_rect(Rect2i(1, 1, 6, 5), paper)
		img.fill_rect(Rect2i(0, 1, 1, 5), paper.darkened(0.3))
		img.fill_rect(Rect2i(7, 1, 1, 5), paper.darkened(0.3))
		img.fill_rect(Rect2i(2, 2, 4, 1), Color("3a6aa0"))
		img.fill_rect(Rect2i(2, 4, 3, 1), Color("3a6aa0"))
		_paper = Stack.from_image(img, 2)
	return _paper


func _draw() -> void:
	var bob := roundf(sin(_t * 3.0) * 1.5) if _rest else 0.0
	_model().draw(self, Vector2(0, -2 + bob), _t * 2.2, 0.2)
