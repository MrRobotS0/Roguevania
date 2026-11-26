class_name BackLayer
extends Node2D

# Uma camada do fundo pintado, com vida própria: balança com o vento (o alto
# mais que a base), tremula no calor, ondula debaixo d'água e ganha a névoa
# da distância. O deslocamento anda de pixel inteiro em pixel inteiro, para
# a pixel art continuar nítida. Quem diz o quanto de cada coisa é o Backdrop.
#
# Movimento em fração de pixel, com amostragem suave: o jogo desenha a 480x270
# e amplia, e preso a pixel inteiro uma camada lenta (a de longe anda menos de
# 1 px por segundo) avançava aos saltos — parecia rodar a 10 quadros por
# segundo. Parada, a camada continua nítida (cai no centro dos pixels).

const SHADER := """
shader_type canvas_item;
uniform vec2 tex_size = vec2(480.0, 270.0);
uniform float sway = 0.0;        // px no alto da camada
uniform float sway_speed = 0.6;
uniform float heat = 0.0;        // px de tremor perto do chão
uniform float wave = 0.0;        // px da ondulação de água
uniform vec4 fog : source_color = vec4(0.0);
uniform float fog_amount = 0.0;
uniform float glow = 0.0;        // a camada inteira acende e apaga (pulso)
uniform float glow_speed = 0.5;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 uv = UV;
	float y = uv.y;
	float top = 1.0 - y;
	float off = sin(TIME * sway_speed + y * 7.0 + uv.x * 9.0) * sway * top * top;
	off += sin(TIME * 2.7 + y * 140.0) * heat * y * y;
	off += sin(TIME * 1.1 + y * 18.0 + uv.x * 3.0) * wave;
	float lift = sin(TIME * 0.9 + uv.x * 14.0) * wave * 0.6;
	uv.x += off / tex_size.x;
	uv.y += lift / tex_size.y;
	vec4 c = texture(TEXTURE, uv);
	c.rgb = mix(c.rgb, fog.rgb, fog_amount * mix(0.55, 1.0, y));
	c.rgb *= 1.0 + glow * (0.5 + 0.5 * sin(TIME * glow_speed + uv.x * 4.0));
	COLOR = c * tint;
}
"""

static var _shader: Shader

var tex: Texture2D
var scroll := 0.0      # fração do andar da câmera
var lift := 0.0        # fração da subida da câmera
var drift := 0.0       # px/s andando sozinha (nuvens)
var bob := 0.0         # px de "respiração" vertical
var bob_phase := 0.0
var foot := Color.BLACK
var _drift_x := 0.0


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	return _shader


func _init() -> void:
	material = ShaderMaterial.new()
	(material as ShaderMaterial).shader = shader()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func set_param(name: String, value: Variant) -> void:
	(material as ShaderMaterial).set_shader_parameter(name, value)


var _at := Vector2.ZERO
var _size := Vector2(480, 270)
var _t := 0.0
var _still := false


func place(delta: float, at: Vector2, size: Vector2, t: float, still: bool) -> void:
	_drift_x += drift * delta
	# na câmera lisa (tela na resolução real) a fração de pixel já anda
	# sozinha: o pixel do fundo volta a ser nítido. Em pixel do jogo, o filtro
	# suave é o que impede a camada lenta de avançar aos trancos.
	var want := CanvasItem.TEXTURE_FILTER_NEAREST if get_tree().root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS else CanvasItem.TEXTURE_FILTER_LINEAR
	if texture_filter != want:
		texture_filter = want
	if tex:
		set_param("tex_size", Vector2(tex.get_size()))
	_at = at
	_size = size
	_t = t
	_still = still
	queue_redraw()


func _draw() -> void:
	if tex == null:
		return
	if _still:
		# o céu fica parado (só pode respirar)
		draw_texture(tex, Vector2(0, sin(_t * 0.25 + bob_phase) * bob))
		return
	var lw := float(tex.get_width())
	var x0 := -fposmod(_at.x * scroll + _drift_x, lw)
	var y0 := clampf(-(_at.y - 400.0) * lift, -30.0, 30.0)
	y0 += sin(_t * 0.35 + bob_phase) * bob
	var x := x0
	while x < _size.x:
		draw_texture(tex, Vector2(x, y0))
		x += lw
	if y0 < 0.0:
		# o pé da camada não pode deixar buraco embaixo
		draw_rect(Rect2(0, _size.y + y0 - 1, _size.x, -y0 + 1), foot)
