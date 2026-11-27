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

const SHADER := preload("res://shaders/camada_fundo.gdshader")

var tex: Texture2D
var scroll := 0.0      # fração do andar da câmera
var lift := 0.0        # fração da subida da câmera
var drift := 0.0       # px/s andando sozinha (nuvens)
var bob := 0.0         # px de "respiração" vertical
var bob_phase := 0.0
var foot := Color.BLACK
var _drift_x := 0.0


func _init() -> void:
	material = ShaderMaterial.new()
	(material as ShaderMaterial).shader = SHADER
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
