class_name Weather
extends Node2D

# Tempestade de cinzas do Mar de Cinzas: aviso, vento que empurra o herói,
# visão encurtada (atiradores enxergam menos) e cinza riscando a tela.
# Fica numa CanvasLayer: desenha em coordenadas de tela.

const CALM := Vector2(22.0, 32.0)
const WARN := 3.0
const STORM := 9.0

var kind := ""
var player: Player
var strength := 0.0          # 0 calmo .. 1 tempestade cheia
var wind := 0.0
var _phase := "calm"
var _t := 0.0
var _next := 25.0
var _streaks: Array = []


func _ready() -> void:
	_next = randf_range(CALM.x * 0.5, CALM.y * 0.6)
	for i in 120:
		_streaks.append(Vector3(randf() * 520.0, randf() * 300.0, randf_range(0.5, 1.0)))


func _process(delta: float) -> void:
	if kind == "":
		return
	_t += delta
	match _phase:
		"calm":
			strength = move_toward(strength, 0.0, delta * 0.5)
			if _t >= _next:
				_phase = "warn"
				_t = 0.0
				wind = 1.0 if randf() < 0.5 else -1.0
				Fx.banner("TEMPESTADE DE CINZAS", "O VENTO VEM " + ("DO OESTE" if wind > 0.0 else "DO LESTE"))
				Sfx.play("wind", -6.0, 0.0)
		"warn":
			strength = move_toward(strength, 0.25, delta * 0.3)
			if _t >= WARN:
				_phase = "storm"
				_t = 0.0
		"storm":
			strength = move_toward(strength, 1.0, delta * 0.8)
			if _t >= STORM:
				_phase = "calm"
				_t = 0.0
				_next = randf_range(CALM.x, CALM.y)
	if is_instance_valid(player):
		player.wind = wind * 45.0 * clampf((strength - 0.3) / 0.7, 0.0, 1.0)
	Fx.visibility = visibility()
	var speed := 260.0 + 340.0 * strength
	for i in _streaks.size():
		var s: Vector3 = _streaks[i]
		s.x += wind * speed * s.z * delta
		s.y += 30.0 * s.z * delta
		s.x = fposmod(s.x, 520.0)
		s.y = fposmod(s.y, 300.0)
		_streaks[i] = s
	queue_redraw()


func visibility() -> float:
	return 1.0 - 0.55 * strength


func _draw() -> void:
	if kind == "" or strength <= 0.01:
		return
	var size := get_viewport_rect().size
	var veil := Color("8a6f58")
	veil.a = 0.32 * strength
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	var count := int(_streaks.size() * strength)
	for i in count:
		var s: Vector3 = _streaks[i]
		var c := Color("d8c4a6")
		c.a = 0.35 * s.z * strength
		draw_rect(Rect2(s.x - 20.0, s.y, 6.0 + 10.0 * s.z, 1), c)
