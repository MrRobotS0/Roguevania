class_name MapCache
extends RefCounted

# O pedaço do andar que o herói já viu, guardado numa imagem (2 px por bloco).
#
# O minimapa era redesenhado célula por célula a cada quadro: 1.400 células em
# GDScript, mais da metade do processador gasto num andar gerado. Aqui cada
# célula é pintada uma vez, quando é vista (Level.fresh), e o HUD desenha só um
# recorte da textura. Parede rachada quebrada ou parede falsa revelada mudam o
# desenho da célula: aí o mapa visto é repintado (Room.version).

const S := 2

var level: Level
var texture: ImageTexture
var _image: Image
var _painted := 0
var _version := -1
var _ground := Color.WHITE
var _edge := Color.WHITE
var _rock := Color.WHITE
var _rock_dot := Color.WHITE
var _air := Color.WHITE
var _plank := Color.WHITE


func bind(lv: Level, theme: Dictionary) -> void:
	level = lv
	var room := lv.room
	_image = Image.create(maxi(room.cols * S, 1), maxi(room.rows * S, 1), false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(_image)
	_painted = 0
	_version = room.version
	var light: Color = theme["light"]
	var frame: Color = theme["frame"]
	_air = Color(theme["bg"], 1.0).lerp(light, 0.4)
	_air.a = 0.85
	_rock = Color(theme["dark"], 0.95)
	# o que antes era desenhado por cima (o ponto da rocha, a linha da plataforma) já entra misturado
	_rock_dot = _rock.blend(Color(frame.darkened(0.3), 0.9))
	_edge = light.lerp(frame, 0.45)
	_ground = light.lerp(frame, 0.1)
	_plank = _air.blend(Color(light, 0.8))


# Pinta o que foi visto desde a última vez. Barato quando nada mudou.
func sync() -> void:
	if level == null or not is_instance_valid(level) or level.room == null:
		return
	var room := level.room
	if room.version != _version:
		_version = room.version
		_image.fill(Color(0, 0, 0, 0))
		_painted = 0
	var n := level.fresh.size()
	if _painted == n:
		return
	for i in range(_painted, n):
		var idx := level.fresh[i]
		_paint(room, idx % room.cols, idx / room.cols)
	_painted = n
	texture.update(_image)


func _paint(room: Room, x: int, y: int) -> void:
	var at := Rect2i(x * S, y * S, S, S)
	if room._solidish(x, y):
		if not room._solidish(x, y - 1):
			_image.fill_rect(at, _ground)
		elif not room._solidish(x + 1, y) or not room._solidish(x - 1, y) or not room._solidish(x, y + 1):
			_image.fill_rect(at, _edge)
		else:
			_image.fill_rect(at, _rock)
			if (x + y) % 3 == 0:
				_image.set_pixel(at.position.x, at.position.y, _rock_dot)
		return
	_image.fill_rect(at, _air)
	if room.cell(x, y) == Room.PLATFORM:
		_image.fill_rect(Rect2i(at.position, Vector2i(S, 1)), _plank)
