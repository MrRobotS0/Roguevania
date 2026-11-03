class_name Sparks
extends Node2D

# Partículas quadradinhas e números de dano. Usa o delta do jogo, então
# congela junto no hitstop, que é o que dá peso ao golpe.

class Bit:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color
	var size: float
	var gravity: float
	var ash := false


class Number:
	var pos: Vector2
	var text: String
	var crit: bool
	var life: float


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

var _bits: Array = []
var _numbers: Array = []
var _streaks: Array = []
var _impacts: Array = []


func _ready() -> void:
	z_index = 20
	Fx.sparks = self


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


# Cada parte do corpo vira um punhado de cinza que sobe e escurece.
func ash(parts: Array) -> void:
	for p in parts:
		var r: Rect2 = p[0]
		var c: Color = p[1]
		if c.a < 0.5:
			continue
		var n := clampi(int(r.size.x * r.size.y / 6.0), 1, 10)
		for i in n:
			var b := Bit.new()
			b.pos = r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
			b.vel = Vector2(randf_range(-28.0, 28.0), randf_range(-70.0, -15.0))
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


func streak(pos: Vector2, dir: float, color: Color) -> void:
	var s := Streak.new()
	s.pos = pos
	s.dir = dir if dir != 0.0 else 1.0
	s.color = color
	s.life = STREAK_LIFE
	_streaks.append(s)


func number(pos: Vector2, value: int, crit: bool) -> void:
	var n := Number.new()
	n.pos = pos + Vector2(randf_range(-4, 4), 0)
	n.text = str(value)
	n.crit = crit
	n.life = NUMBER_LIFE
	_numbers.append(n)


func _process(delta: float) -> void:
	for b: Bit in _bits:
		b.vel.y += b.gravity * delta
		b.pos += b.vel * delta
		b.life -= delta
	_bits = _bits.filter(func(b: Bit) -> bool: return b.life > 0.0)
	for n: Number in _numbers:
		n.pos.y -= 28.0 * delta * (n.life / NUMBER_LIFE + 0.2)
		n.life -= delta
	_numbers = _numbers.filter(func(n: Number) -> bool: return n.life > 0.0)
	for i: Impact in _impacts:
		i.life -= delta
	_impacts = _impacts.filter(func(i: Impact) -> bool: return i.life > 0.0)
	for s: Streak in _streaks:
		s.life -= delta
	_streaks = _streaks.filter(func(s: Streak) -> bool: return s.life > 0.0)
	queue_redraw()


func _draw() -> void:
	for i: Impact in _impacts:
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
	for s: Streak in _streaks:
		var k := s.life / STREAK_LIFE
		var length := 26.0 * k
		var c := s.color
		c.a = k
		var x0 := s.pos.x - s.dir * 10.0
		draw_rect(Rect2(minf(x0, x0 + s.dir * length), s.pos.y - 1, length, 2 if k > 0.5 else 1), c)
	for b: Bit in _bits:
		var c := b.color
		if b.ash:
			c = c.lerp(ASH, 1.0 - b.life / b.max_life)
		c.a = clampf(b.life / b.max_life * 1.6, 0.0, 1.0)
		draw_rect(Rect2(b.pos.floor(), Vector2(b.size, b.size)), c)
	for n: Number in _numbers:
		var c := Palette.UI_CRIT if n.crit else Palette.UI_TEXT
		c.a = clampf(n.life / NUMBER_LIFE * 2.5, 0.0, 1.0)
		var shadow := Palette.UI_SHADOW
		shadow.a = c.a
		PixelFont.draw_centered(self, n.text, n.pos.round(), c, 2 if n.crit else 1, shadow)
