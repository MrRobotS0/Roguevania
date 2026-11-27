class_name HeroVolume
extends RefCounted

# Volume do herói, além do relevo e da luz de contorno do domínio:
#   espessura: duas cópias escuras do desenho empilhadas atrás, 1 px para o
#     lado da sombra cada (sprite stacking de lado: vira peça, não recorte);
#   giro: ao trocar de lado, o desenho estreita e abre como uma carta virando
#     (só o visual; o controle continua virando na hora);
#   contorno: uma linha de 1 px acesa na borda do lado oposto à luz, sem
#     sombra por cima (pixel art lê melhor uma borda nítida que um degradê).

const LAYERS := 2
# a linha de contorno em pixel ficou desligada: o desenho do herói tem vãos
# largos entre a capa e o braço, e o shader acendia uma linha no meio do corpo
# (parecia defeito). O contorno vem da luz de contorno do domínio (Depth).
const RIM_ON := false
const TURN_TIME := 0.09
const BACK := [Color(0.42, 0.38, 0.46), Color(0.26, 0.23, 0.3)]

const RIM_SHADER := preload("res://shaders/contorno_heroi.gdshader")

static var _rim_shader: Shader

var body: Sprite2D
var backs: Array[Sprite2D] = []
var rim: Sprite2D
var side := 1.0            # para onde cai a sombra no domínio (+1 = direita)
var _face := 1.0           # o lado visível, girando entre -1 e 1


func attach(owner: Node2D, sprite: Sprite2D, light_side: float, rim_color: Color) -> void:
	body = sprite
	side = light_side
	for i in LAYERS:
		var b := Sprite2D.new()
		b.self_modulate = BACK[i]
		owner.add_child(b)
		owner.move_child(b, body.get_index())
		backs.append(b)
	if not RIM_ON:
		return
	rim = Sprite2D.new()
	if _rim_shader == null:
		_rim_shader = RIM_SHADER
	var m := ShaderMaterial.new()
	m.shader = _rim_shader
	m.set_shader_parameter("rim", rim_color)
	rim.material = m
	owner.add_child(rim)
	owner.move_child(rim, body.get_index() + 1)


# Chamado depois que o corpo já tem quadro, escala e textura do quadro.
func update(delta: float, facing: int, plain_texture: Texture2D) -> void:
	if body == null:
		return
	_face = move_toward(_face, float(facing), delta * 2.0 / TURN_TIME)
	var width := maxf(absf(_face), 0.12)
	var flip := _face < 0.0
	body.flip_h = flip
	body.scale.x *= width
	for i in backs.size():
		var b := backs[i]
		_copy(b, plain_texture)
		# a espessura aparece mais quando o herói está de lado (meio do giro some)
		b.position = body.position + Vector2(side * (i + 1) * width, 0).round()
	if rim == null:
		return
	_copy(rim, plain_texture)
	rim.position = body.position
	(rim.material as ShaderMaterial).set_shader_parameter("side", side * (-1.0 if flip else 1.0))


func _copy(s: Sprite2D, tex: Texture2D) -> void:
	s.texture = tex
	s.centered = body.centered
	s.offset = body.offset
	s.hframes = body.hframes
	s.vframes = body.vframes
	s.frame = body.frame
	s.flip_h = body.flip_h
	s.scale = body.scale
	s.visible = body.visible
	s.modulate = body.modulate


func remove() -> void:
	for b in backs:
		b.queue_free()
	backs.clear()
	if rim:
		rim.queue_free()
