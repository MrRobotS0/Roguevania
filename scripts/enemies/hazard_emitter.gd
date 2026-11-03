class_name HazardEmitter
extends Node2D

# Perigo de cenário genérico: solta um Hazard no lugar (ou perto do herói)
# por tempo ou quando ele chega perto. As subclasses só escolhem o estilo.

var room: Room
var player: Player
var style := "tendril"
var every := 3.0
var proximity := 0.0         # > 0: só dispara com o herói a essa distância
var follow := false          # true: cai onde o herói está (meteoro)
var width := 16.0
var height := 46.0
var damage := 16.0
var delay := 0.7
var linger := 0.4
var _clock := 0.0


func _ready() -> void:
	z_index = 1
	_clock = fposmod(position.x * 0.017, every)


func _physics_process(delta: float) -> void:
	_clock += delta
	if _clock < every or not is_instance_valid(player) or not player.alive():
		return
	var d := player.global_position - global_position
	if proximity > 0.0 and (absf(d.x) > proximity or absf(d.y) > 40.0):
		return
	_clock = 0.0
	var hz := Hazard.new()
	hz.player = player
	hz.style = style
	hz.width = width
	hz.height = height
	hz.damage = damage
	hz.delay = delay
	hz.linger = linger
	hz.position = Vector2(player.global_position.x if follow else global_position.x, global_position.y)
	get_parent().add_child(hz)
