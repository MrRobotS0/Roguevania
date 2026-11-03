class_name Brazier
extends Node2D

# Braseiro das Casas: só cenário. É a luz quente que o deserto tem à noite,
# e a chama dança (a luz acompanha).

var _t := 0.0
var _light: PointLight2D
var _seed := 0.0


func _ready() -> void:
	z_index = -1
	_seed = fposmod(position.x * 0.137, TAU)
	_light = Glow.attach(self, Color(1.0, 0.62, 0.3), 96.0, 0.9, Vector2(0, -14))
	var s := SpriteSheet.region_sprite("props", Interactable.props_palette(), "brazier")
	s.show_behind_parent = true
	add_child(s)


func _process(delta: float) -> void:
	_t += delta
	_light.energy = 0.85 + 0.12 * sin(_t * 9.0 + _seed) + 0.06 * sin(_t * 23.0)
	queue_redraw()


func _draw() -> void:
	for i in 4:
		var k := fposmod(_t * 2.2 + i * 0.27 + _seed, 1.0)
		var x := -3.0 + i * 2.0 + sin(_t * 7.0 + i) * 1.0
		var tall := 3.0 + (1.0 - k) * 6.0 + (i % 2) * 2.0
		draw_rect(Rect2(x, -14 - tall, 2, tall), Palette.BURN)
		draw_rect(Rect2(x, -14 - tall * 0.5, 2, tall * 0.5), Palette.DANGER)
	var ember := Palette.DANGER
	var rise := fposmod(_t * 0.8 + _seed, 1.0)
	ember.a = 1.0 - rise
	draw_rect(Rect2(sin(_t * 3.0 + _seed) * 3.0, -18 - rise * 22.0, 1, 1), ember)
