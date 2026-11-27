class_name HeroVolume
extends RefCounted

# Volume do herói, além do relevo e da luz do domínio:
#   espessura: duas cópias escuras do desenho empilhadas atrás, 1 px para o
#     lado da sombra cada (sprite stacking de lado: vira peça, não recorte);
#   giro: ao trocar de lado, o desenho estreita e abre como uma carta virando
#     (só o visual; o controle continua virando na hora).
# A linha de luz no contorno é do material do corpo (Depth.body_material).

const LAYERS := 2
const TURN_TIME := 0.09
const BACK := [Color(0.42, 0.38, 0.46), Color(0.26, 0.23, 0.3)]

var body: Sprite2D
var backs: Array[Sprite2D] = []
var side := 1.0            # para onde cai a sombra no domínio (+1 = direita)
var _face := 1.0           # o lado visível, girando entre -1 e 1


func attach(owner: Node2D, sprite: Sprite2D, light_side: float) -> void:
	body = sprite
	side = light_side
	for i in LAYERS:
		var b := Sprite2D.new()
		b.self_modulate = BACK[i]
		b.light_mask = sprite.light_mask
		owner.add_child(b)
		owner.move_child(b, body.get_index())
		backs.append(b)


# Chamado depois que o corpo já tem quadro, escala e textura do quadro.
func update(delta: float, facing: int, plain_texture: Texture2D) -> void:
	if body == null:
		return
	_face = move_toward(_face, float(facing), delta * 2.0 / TURN_TIME)
	var width := maxf(absf(_face), 0.12)
	body.flip_h = _face < 0.0
	body.scale.x *= width
	for i in backs.size():
		var b := backs[i]
		_copy(b, plain_texture)
		# a espessura aparece mais quando o herói está de lado (meio do giro some)
		b.position = body.position + Vector2(side * (i + 1) * width, 0).round()


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
