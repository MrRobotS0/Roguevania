class_name Sparks
extends Node2D

# Partículas quadradinhas, fumaça em pixel e números de dano. Usa o delta do
# jogo, então congela junto no hitstop, que é o que dá peso ao golpe.
#   Faísca: a do golpe nasce quase branca; todas escurecem no fim, e a rápida
#   deixa um rastro de 1 pixel no caminho.
#   Fumaça: um disco de pixel que cresce em quatro tamanhos e some (poeira do
#   pouso, golpe forte). Os discos são desenhados uma vez, numa tira.

class Bit:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color
	var size: float
	var gravity: float
	var ash := false
	var hot := false       # faísca de golpe: nasce quase branca


class Puff:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color


class Number:
	var pos: Vector2
	var text: String
	var crit: bool
	var life: float
	var tint := Color(0, 0, 0, 0)    # cor própria (dano no herói: vermelho)


class Streak:
	var pos: Vector2
	var dir: float
	var color: Color
	var life: float


class Impact:
	var pos: Vector2
	var color: Color
	var big: bool
	var life: float


const IMPACT_LIFE := 0.12
const NUMBER_LIFE := 0.7
const STREAK_LIFE := 0.12
const ASH := Color("4a4038")
const HOT := 0.28              # fração da vida em que a faísca ainda está quase branca
const TRAIL_SPEED := 110.0     # px/s a partir de onde a faísca deixa rastro
const PUFF_SIZES := [3, 5, 7, 9]
const PUFF_CELL := 9
const PUFFS_MAX := 40

static var _puff_tex: ImageTexture

var _bits: Array[Bit] = []
var _puffs: Array[Puff] = []
var _numbers: Array[Number] = []
var _streaks: Array[Streak] = []
var _impacts: Array[Impact] = []


func _ready() -> void:
	z_index = 20
	Fx.sparks = self
	if _puff_tex == null:
		_puff_tex = _bake_puffs()


# Os quatro discos da fumaça numa tira (cada um centrado na sua célula de 9 px).
static func _bake_puffs() -> ImageTexture:
	var img := Image.create(PUFF_CELL * PUFF_SIZES.size(), PUFF_CELL, false, Image.FORMAT_RGBA8)
	for i in PUFF_SIZES.size():
		var r := float(PUFF_SIZES[i]) * 0.5
		var mid := Vector2(i * PUFF_CELL + PUFF_CELL * 0.5, PUFF_CELL * 0.5)
		for y in PUFF_CELL:
			for x in PUFF_CELL:
				var p := Vector2(i * PUFF_CELL + x + 0.5, y + 0.5)
				if p.distance_to(mid) <= r:
					img.set_pixel(i * PUFF_CELL + x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)


func burst(pos: Vector2, color: Color, count: int, speed: float, life: float, gravity: float, size: float, lift: float) -> void:
	for i in count:
		var b := Bit.new()
		b.pos = pos
		b.vel = Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.35, speed)
		b.vel.y -= lift
		b.max_life = life * randf_range(0.6, 1.0)
		b.life = b.max_life
		b.color = color
		b.size = size
		b.gravity = gravity
		_bits.append(b)


# Faíscas num leque para o lado do golpe (o impacto "sai" do outro lado do alvo).
func spray(pos: Vector2, dir: float, color: Color, count: int, speed: float) -> void:
	var side := dir if dir != 0.0 else 1.0
	for i in count:
		var b := Bit.new()
		b.pos = pos
		var ang := randf_range(-0.7, 0.5)
		b.vel = Vector2(cos(ang) * side, sin(ang)) * randf_range(speed * 0.45, speed)
		b.max_life = randf_range(0.14, 0.28)
		b.life = b.max_life
		b.color = color
		b.size = 2.0 if i % 3 == 0 else 1.0
		b.gravity = 380.0
		b.hot = true
		_bits.append(b)


# Fumaça: discos que sobem devagar, crescem e somem.
func puff(pos: Vector2, color: Color, count: int, spread := 6.0) -> void:
	if not Graficos.on("fumaca"):
		return
	for i in count:
		if _puffs.size() >= PUFFS_MAX:
			return
		var p := Puff.new()
		p.pos = pos + Vector2(randf_range(-spread, spread), randf_range(-2.0, 1.0))
		p.vel = Vector2(randf_range(-14.0, 14.0), randf_range(-22.0, -8.0))
		p.max_life = randf_range(0.32, 0.55)
		p.life = p.max_life
		p.color = color
		_puffs.append(p)


# Cada parte do corpo vira um punhado de cinza que sobe e escurece.
func ash(parts: Array, push := Vector2.ZERO) -> void:
	for p in parts:
		var r: Rect2 = p[0]
		var c: Color = p[1]
		if c.a < 0.5:
			continue
		var n := clampi(int(r.size.x * r.size.y / 6.0), 1, 10)
		for i in n:
			var b := Bit.new()
			b.pos = r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
			b.vel = Vector2(randf_range(-28.0, 28.0), randf_range(-70.0, -15.0)) + push * randf_range(0.4, 1.0)
			b.max_life = randf_range(0.6, 1.3)
			b.life = b.max_life
			b.color = c
			b.size = 2.0 if randf() < 0.4 else 1.0
			b.gravity = -25.0
			b.ash = true
			_bits.append(b)


func impact(pos: Vector2, color: Color, big: bool) -> void:
	var i := Impact.new()
	i.pos = pos.round()
	i.color = color
	i.big = big
	i.life = IMPACT_LIFE * (1.5 if big else 1.0)
	_impacts.append(i)
	if big:
		puff(pos, color.lerp(Palette.DUST, 0.7), 2, 5.0)


func streak(pos: Vector2, dir: float, color: Color) -> void:
	var s := Streak.new()
	s.pos = pos
	s.dir = dir if dir != 0.0 else 1.0
	s.color = color
	s.life = STREAK_LIFE
	_streaks.append(s)


func number(pos: Vector2, value: int, crit: bool, tint := Color(0, 0, 0, 0)) -> void:
	var n := Number.new()
	n.tint = tint
	n.pos = pos + Vector2(randf_range(-4, 4), 0)
	n.text = str(value)
	n.crit = crit
	n.life = NUMBER_LIFE
	_numbers.append(n)


# As listas são compactadas no lugar: filtrar com função criava quatro listas novas
# por quadro, com centenas de partículas num golpe forte.
func _process(delta: float) -> void:
	var keep := 0
	for b in _bits:
		b.vel.y += b.gravity * delta
		b.pos += b.vel * delta
		b.life -= delta
		if b.life > 0.0:
			_bits[keep] = b
			keep += 1
	_bits.resize(keep)
	keep = 0
	for p in _puffs:
		p.vel *= 1.0 - minf(delta * 2.5, 1.0)
		p.pos += p.vel * delta
		p.life -= delta
		if p.life > 0.0:
			_puffs[keep] = p
			keep += 1
	_puffs.resize(keep)
	keep = 0
	for n in _numbers:
		n.pos.y -= 28.0 * delta * (n.life / NUMBER_LIFE + 0.2)
		n.life -= delta
		if n.life > 0.0:
			_numbers[keep] = n
			keep += 1
	_numbers.resize(keep)
	keep = 0
	for i in _impacts:
		i.life -= delta
		if i.life > 0.0:
			_impacts[keep] = i
			keep += 1
	_impacts.resize(keep)
	keep = 0
	for s in _streaks:
		s.life -= delta
		if s.life > 0.0:
			_streaks[keep] = s
			keep += 1
	_streaks.resize(keep)
	queue_redraw()


func _draw() -> void:
	for p in _puffs:
		# atrás das faíscas: cresce pelos quatro discos e vai sumindo
		var age := 1.0 - p.life / p.max_life
		var step := mini(int(age * PUFF_SIZES.size()), PUFF_SIZES.size() - 1)
		var c := p.color
		c.a = (1.0 - age) * 0.55
		draw_texture_rect_region(_puff_tex, Rect2(p.pos.floor() - Vector2(4, 4), Vector2(PUFF_CELL, PUFF_CELL)),
			Rect2(step * PUFF_CELL, 0, PUFF_CELL, PUFF_CELL), c)
	for i in _impacts:
		# estrela de quatro pontas que abre e some em poucos quadros
		var full := IMPACT_LIFE * (1.5 if i.big else 1.0)
		var t := 1.0 - i.life / full
		var reach := (6.0 if not i.big else 11.0) * (0.4 + t)
		var c := i.color
		c.a = 1.0 - t * 0.6
		draw_rect(Rect2(i.pos.x - reach, i.pos.y, reach * 2.0 + 1.0, 1), c)
		draw_rect(Rect2(i.pos.x, i.pos.y - reach, 1, reach * 2.0 + 1.0), c)
		var d := reach * 0.45
		for k in range(1, int(d) + 1):
			draw_rect(Rect2(i.pos + Vector2(k, k), Vector2.ONE), c)
			draw_rect(Rect2(i.pos + Vector2(-k, k), Vector2.ONE), c)
			draw_rect(Rect2(i.pos + Vector2(k, -k), Vector2.ONE), c)
			draw_rect(Rect2(i.pos + Vector2(-k, -k), Vector2.ONE), c)
		if t < 0.4 and Options.flashes():
			var core := Palette.FLASH
			core.a = 1.0
			draw_rect(Rect2(i.pos - Vector2(1, 1), Vector2(3, 3)), core)
	for s in _streaks:
		var k := s.life / STREAK_LIFE
		var length := 26.0 * k
		var c := s.color
		c.a = k
		var x0 := s.pos.x - s.dir * 10.0
		draw_rect(Rect2(minf(x0, x0 + s.dir * length), s.pos.y - 1, length, 2 if k > 0.5 else 1), c)
	for b in _bits:
		var left := b.life / b.max_life
		var c := b.color
		if b.ash:
			c = c.lerp(ASH, 1.0 - left)
		elif b.hot and left > 1.0 - HOT:
			# recém-nascida: quase branca (é o que passa do limiar do brilho)
			c = c.lerp(Color.WHITE, 0.7 * (left - (1.0 - HOT)) / HOT)
		elif left < 0.4:
			c = c.darkened(0.45 * (1.0 - left / 0.4))
		c.a = clampf(left * 1.6, 0.0, 1.0)
		var at := b.pos.floor()
		if not b.ash and b.vel.length_squared() > TRAIL_SPEED * TRAIL_SPEED:
			# rastro: 1 pixel onde ela estava um quadro atrás
			var back := (b.pos - b.vel * 0.02).floor()
			if back != at:
				draw_rect(Rect2(back, Vector2.ONE), Color(c.r, c.g, c.b, c.a * 0.45))
		draw_rect(Rect2(at, Vector2(b.size, b.size)), c)
	for n in _numbers:
		var c := Palette.UI_CRIT if n.crit else Palette.UI_TEXT
		if n.tint.a > 0.0:
			c = n.tint
		c.a = clampf(n.life / NUMBER_LIFE * 2.5, 0.0, 1.0)
		var shadow := Palette.UI_SHADOW
		shadow.a = c.a
		PixelFont.draw_centered(self, n.text, n.pos.round(), c, 2 if n.crit else 1, shadow)
