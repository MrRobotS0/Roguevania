class_name TimedDoor
extends Node2D

# Porta do Relógio: fica aberta só se você chegar antes do tempo do andar
# acabar (o HUD mostra a contagem). Passou do tempo, fecha de vez.

var limit := 150.0
var level: Node
var player: Player
var is_open := false
var _shut := false
var _body: Sprite2D
var _wall: StaticBody2D
var _t := 0.0


func _ready() -> void:
	add_to_group("timed_doors")
	z_index = 2
	_body = SpriteSheet.region_sprite("props", Interactable.props_palette(), "timed_door")
	add_child(_body)
	_wall = StaticBody2D.new()
	_wall.collision_layer = Room.WORLD_LAYER
	_wall.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 48)
	var holder := CollisionShape2D.new()
	holder.shape = shape
	holder.position = Vector2(0, -24)
	_wall.add_child(holder)
	add_child(_wall)


func time_left() -> float:
	return limit - Run.stage_time


func _process(delta: float) -> void:
	_t += delta
	if is_open or _shut:
		return
	if time_left() <= 0.0:
		_shut = true
		Fx.toast("A PORTA DO RELÓGIO SE FECHOU")
		return
	if is_instance_valid(player) and player.global_position.distance_to(global_position) < 40.0:
		is_open = true
		_wall.queue_free()
		SpriteSheet.set_region(_body, "props", "timed_door", 1)
		Sfx.play("secret")
		Fx.burst(global_position + Vector2(0, -24), Palette.GOLD, 14, 90.0, 0.5)
