class_name Ambience
extends Node2D

# O ar de cada domínio, por cima do fundo e por baixo do mundo: raios de luz
# que giram devagar, névoa que corre entre as camadas e partículas que brilham
# (vaga-lumes, faíscas, cinza, neve, glifos, estrelas). Tudo em pixels da
# tela (480x270), para casar com a arte.

const LOOK := {
	"mar_de_cinzas": {"rays": Color(1.0, 0.82, 0.6, 0.16), "ray_at": Vector2(0.72, -0.1), "fog": Color(0.85, 0.55, 0.5, 0.22),
		"motes": "ash", "mote": Color(1.0, 0.8, 0.5)},
	"saloes": {"rays": Color(0.7, 0.85, 1.0, 0.10), "ray_at": Vector2(0.3, -0.2), "fog": Color(0.55, 0.65, 0.95, 0.25),
		"motes": "snow", "mote": Color(0.9, 0.95, 1.0)},
	"forja_rubra": {"rays": Color(1.0, 0.45, 0.2, 0.12), "ray_at": Vector2(0.5, 1.2), "fog": Color(0.7, 0.18, 0.1, 0.28),
		"motes": "sparks", "mote": Color(1.0, 0.6, 0.2)},
	"torre_babel": {"rays": Color(1.0, 0.8, 0.6, 0.18), "ray_at": Vector2(0.85, -0.15), "fog": Color(0.6, 0.45, 0.65, 0.2),
		"motes": "glyphs", "mote": Color(1.0, 0.85, 0.45)},
	"jardim_primordial": {"rays": Color(0.75, 1.0, 0.55, 0.12), "ray_at": Vector2(0.55, -0.25), "fog": Color(0.25, 0.45, 0.3, 0.3),
		"motes": "fireflies", "mote": Color(0.85, 1.0, 0.4)},
	"carcosa": {"rays": Color(1.0, 0.9, 0.3, 0.10), "ray_at": Vector2(0.5, -0.2), "fog": Color(0.55, 0.5, 0.15, 0.3),
		"motes": "ash", "mote": Color(1.0, 0.92, 0.35)},
	"observatorio": {"rays": Color(0.7, 0.6, 1.0, 0.08), "ray_at": Vector2(0.15, -0.1), "fog": Color(0.35, 0.25, 0.55, 0.18),
		"motes": "stars", "mote": Color(0.85, 0.9, 1.0)},
	"necropole": {"rays": Color(0.75, 0.85, 1.0, 0.10), "ray_at": Vector2(0.78, -0.15), "fog": Color(0.45, 0.5, 0.65, 0.32),
		"motes": "fireflies", "mote": Color(0.75, 0.95, 1.0)},
	"catedral": {"rays": Color(0.55, 0.85, 1.0, 0.16), "ray_at": Vector2(0.5, -0.3), "fog": Color(0.2, 0.4, 0.55, 0.3),
		"motes": "snow", "mote": Color(0.65, 0.9, 1.0)},
	"ventre": {"rays": Color(1.0, 0.35, 0.35, 0.08), "ray_at": Vector2(0.5, 1.2), "fog": Color(0.55, 0.12, 0.16, 0.32),
		"motes": "sparks", "mote": Color(1.0, 0.55, 0.5)},
	"penhascos": {"rays": Color(0.95, 0.8, 1.0, 0.18), "ray_at": Vector2(0.2, -0.2), "fog": Color(0.6, 0.5, 0.8, 0.22),
		"motes": "stars", "mote": Color(0.95, 0.85, 1.0)},
	"cavernas": {"rays": Color(0.5, 0.8, 0.9, 0.06), "ray_at": Vector2(0.5, -0.4), "fog": Color(0.15, 0.2, 0.28, 0.35),
		"motes": "ash", "mote": Color(0.6, 0.85, 0.95)},
	"bosque": {"rays": Color(1.0, 0.9, 0.6, 0.16), "ray_at": Vector2(0.7, -0.2), "fog": Color(0.35, 0.45, 0.3, 0.26),
		"motes": "fireflies", "mote": Color(1.0, 0.95, 0.55)},
}

const RAYS_SHADER := preload("res://shaders/raios.gdshader")

const FOG_SHADER := preload("res://shaders/nevoa.gdshader")

var biome := ""
var _rays: ColorRect
var _fog: ColorRect
var _motes: Array = []
var _t := 0.0
var _look := {}


func _ready() -> void:
	_rays = _layer(RAYS_SHADER)
	_fog = _layer(FOG_SHADER)


func _layer(shader: Shader) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(480, 270)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = shader
	r.material = m
	add_child(r)
	return r


func use(id: String) -> void:
	biome = id
	_look = LOOK.get(id, {})
	visible = not _look.is_empty()
	if _look.is_empty():
		return
	(_rays.material as ShaderMaterial).set_shader_parameter("tint", _look["rays"])
	(_rays.material as ShaderMaterial).set_shader_parameter("origin", _look["ray_at"])
	(_fog.material as ShaderMaterial).set_shader_parameter("tint", _look["fog"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	_motes.clear()
	for i in int(Graficos.num("ar")):
		# posição em fração da tela: com a visão ampla ela pode passar de 480x270
		_motes.append([Vector2(rng.randf(), rng.randf()), rng.randf(), rng.randf_range(0.5, 1.5)])


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var vp := get_viewport_rect().size
	_rays.size = vp
	_fog.size = vp
	(_rays.material as ShaderMaterial).set_shader_parameter("screen", vp)
	(_fog.material as ShaderMaterial).set_shader_parameter("screen", vp)
	queue_redraw()


# Partículas desenhadas à mão: um ponto aceso com um halo fraco em volta.
func _draw() -> void:
	if _look.is_empty():
		return
	var kind: String = _look["motes"]
	var base: Color = _look["mote"]
	var vp := get_viewport_rect().size
	for m in _motes:
		var p: Vector2 = m[0] * vp
		var s: float = m[1]
		var sp: float = m[2]
		var pos := p
		var a := 1.0
		match kind:
			"fireflies":
				pos += Vector2(sin(_t * 0.7 * sp + s * 20.0) * 18.0, cos(_t * 0.5 * sp + s * 9.0) * 10.0)
				a = clampf(sin(_t * 2.0 * sp + s * 40.0) * 0.5 + 0.5, 0.0, 1.0)
			"sparks":
				pos.y = fposmod(p.y - _t * 40.0 * sp, vp.y)
				pos.x += sin(_t * 3.0 + s * 12.0) * 6.0
				a = 1.0 - pos.y / vp.y * 0.6
			"snow":
				pos.y = fposmod(p.y + _t * 14.0 * sp, vp.y)
				pos.x = fposmod(p.x + sin(_t * 0.8 + s * 10.0) * 12.0 - _t * 6.0, vp.x)
				a = 0.7
			"ash":
				pos.y = fposmod(p.y + _t * 6.0 * sp, vp.y)
				pos.x = fposmod(p.x - _t * 18.0 * sp, vp.x)
				a = 0.45 + 0.35 * sin(_t * 1.5 + s * 30.0)
			"glyphs":
				pos.y = fposmod(p.y - _t * 8.0 * sp, vp.y)
				a = clampf(sin(_t * 1.2 * sp + s * 25.0), 0.0, 1.0)
			"stars":
				a = clampf(sin(_t * 2.5 * sp + s * 50.0) * 0.7 + 0.3, 0.0, 1.0)
		pos = pos.round()
		var halo := base
		halo.a = a * 0.18
		var core := base.lightened(0.3)
		core.a = a * 0.9
		if kind == "glyphs":
			# um pedacinho de letra: barra e ponto
			draw_rect(Rect2(pos, Vector2(1, 3)), core)
			draw_rect(Rect2(pos + Vector2(2, 0), Vector2(1, 1)), core)
			continue
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(3, 3)), halo)
		draw_rect(Rect2(pos, Vector2(1, 1)), core)
		if kind == "stars" and a > 0.85:
			draw_rect(Rect2(pos - Vector2(2, 0), Vector2(5, 1)), halo)
			draw_rect(Rect2(pos - Vector2(0, 2), Vector2(1, 5)), halo)
