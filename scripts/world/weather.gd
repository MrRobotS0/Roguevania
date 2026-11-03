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
	if kind != "ashstorm":
		_t += delta
		Fx.visibility = 1.0
		queue_redraw()
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
	if kind in ["embers", "snow", "dust", "spores", "shadow", "stars"]:
		_ambient()
		return
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


# Clima só de ambiente (sem efeito no jogo): brasas subindo na Forja, neve
# caindo nos Salões. Usa a mesma lista de partículas da tempestade.
func _ambient() -> void:
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var at := cam.get_screen_center_position() if cam else Vector2.ZERO
	for i in 70:
		var s: Vector3 = _streaks[i]
		if kind == "stars":
			var x := fposmod(s.x - at.x * 0.2 * s.z, size.x)
			var y := fposmod(s.y - at.y * 0.2 * s.z, size.y * 0.7)
			var c := Color(0.85, 0.92, 1.0, (0.3 + 0.7 * absf(sin(_t * (1.0 + s.z * 2.0) + i))) * s.z)
			draw_rect(Rect2(floorf(x), floorf(y), 1, 1), c)
			continue
		if kind == "dust" or kind == "spores":
			var up := -1.0 if kind == "spores" else 0.3
			var x := fposmod(s.x + sin(_t * 0.5 + i) * 14.0 - at.x * 0.5 * s.z, size.x)
			var y := fposmod(s.y + up * _t * (6.0 + 8.0 * s.z) - at.y * 0.5 * s.z, size.y)
			var c := Color("e8d070") if kind == "dust" else Color("c8e07a")
			c.a = 0.25 + 0.4 * absf(sin(_t + i))
			draw_rect(Rect2(floorf(x), floorf(y), 1, 1), c)
			continue
		if kind == "shadow":
			var x := fposmod(s.x + sin(_t * 0.6 + i) * 8.0 - at.x * 0.6 * s.z, size.x)
			var y := fposmod(s.y + _t * (10.0 + 14.0 * s.z) - at.y * 0.6 * s.z, size.y)
			var c := Color(0.25, 0.12, 0.35, 0.5 + 0.4 * s.z)
			draw_rect(Rect2(floorf(x), floorf(y), 2, 1), c)
			continue
		if kind == "snow":
			var x := fposmod(s.x + sin(_t * 0.8 + i) * 10.0 - at.x * 0.6 * s.z, size.x)
			var y := fposmod(s.y + _t * (14.0 + 20.0 * s.z) - at.y * 0.6 * s.z, size.y)
			var c := Color(0.92, 0.96, 1.0, 0.35 + 0.45 * s.z)
			draw_rect(Rect2(floorf(x), floorf(y), 2 if s.z > 0.8 else 1, 2 if s.z > 0.8 else 1), c)
		else:
			var x := fposmod(s.x + sin(_t * 1.3 + i) * 6.0 - at.x * 0.6 * s.z, size.x)
			var y := fposmod(s.y - _t * (18.0 + 30.0 * s.z) - at.y * 0.6 * s.z, size.y)
			var c := Palette.BURN if i % 3 else Palette.DANGER
			c.a = 0.4 + 0.5 * absf(sin(_t * 3.0 + i))
			draw_rect(Rect2(floorf(x), floorf(y), 1, 1 if i % 4 else 2), c)
