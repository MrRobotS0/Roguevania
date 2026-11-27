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


# A planta enrolada (papel com riscos azuis e os rolos escuros nas pontas) gira no
# ar em fatias: o desenho vem de tools/gen_pilhas.py.
func _draw() -> void:
	var bob := roundf(sin(_t * 3.0) * 1.5) if _rest else 0.0
	Stack.of("planta").draw(self, Vector2(0, -2 + bob), _t * 2.2)
