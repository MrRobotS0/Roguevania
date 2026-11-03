class_name FireVent
extends Node2D

# Respiro da Forja: uma grade no chão que solta um jato de fogo de tempos em
# tempos. O chão brilha antes (aviso); dá para passar no intervalo.

const EVERY := 2.8

var room: Room
var player: Player
var _clock := 0.0


func _ready() -> void:
	z_index = 1
	_clock = fposmod(position.x * 0.013, EVERY)


func _physics_process(delta: float) -> void:
	_clock += delta
	if _clock >= EVERY:
		_clock = 0.0
		var jet := Hazard.new()
		jet.player = player
		jet.style = "fire"
		jet.delay = 0.7
		jet.linger = 0.55
		jet.width = 16.0
		jet.height = 46.0
		jet.damage = 16.0
		jet.position = position
		get_parent().add_child(jet)
	queue_redraw()


func _draw() -> void:
	var iron := Color("2a2220")
	draw_rect(Rect2(-9, -2, 18, 2), iron)
	for i in 4:
		draw_rect(Rect2(-7 + i * 4, -2, 2, 1), Palette.BURN.darkened(0.4 - 0.3 * (_clock / EVERY)))
