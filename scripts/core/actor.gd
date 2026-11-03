class_name Actor
extends CharacterBody2D

# Base do herói, dos inimigos e dos chefes: vida, caixa de dano,
# efeitos de status (queimadura, atordoamento) e o desenho espelhado.

const BURN_TICK := 0.5
const BURN_DAMAGE := 3.0

var room: Room
var max_hp := 100
var hp := 100
var w := 12
var h := 22
var facing := 1
var statuses := {}

var flash := 0.0
var _burn_clock := 0.0
var _tint := Color(0, 0, 0, 0)
var _burn_light: PointLight2D


func setup_body(layer: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var holder := CollisionShape2D.new()
	holder.shape = shape
	holder.position = Vector2(0, -h * 0.5)
	add_child(holder)
	collision_layer = layer
	collision_mask = Room.WORLD_LAYER | Room.PLATFORM_LAYER


func alive() -> bool:
	return hp > 0


func center() -> Vector2:
	return global_position + Vector2(0, -h * 0.5)


func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-w * 0.5, -h), Vector2(w, h))


func has_status(name: String) -> bool:
	return statuses.get(name, 0.0) > 0.0


func add_status(name: String, seconds: float) -> void:
	statuses[name] = maxf(statuses.get(name, 0.0), seconds)


func apply_statuses(d: Damage) -> void:
	for name: String in d.status:
		add_status(name, d.status[name])


# Golpe recebido. Cada tipo de ator decide se defende, se atordoa etc.
func hurt(_d: Damage) -> bool:
	return false


func tick_statuses(delta: float) -> void:
	for name: String in statuses.keys():
		statuses[name] -= delta
		if statuses[name] <= 0.0:
			statuses.erase(name)
	if has_status("burn") != (_burn_light != null):
		if _burn_light:
			_burn_light.queue_free()
			_burn_light = null
		else:
			_burn_light = Glow.attach(self, Palette.BURN, 40.0, 0.8, Vector2(0, -h * 0.5))
	if has_status("burn") and alive():
		_burn_clock -= delta
		if _burn_clock <= 0.0:
			_burn_clock = BURN_TICK
			var d := Damage.make(BURN_DAMAGE)
			d.over_time = true
			hurt(d)
			Fx.burst(center() + Vector2(randf_range(-4, 4), -4), Palette.BURN, 3, 40.0, 0.4, -120.0)


# --- desenho ------------------------------------------------------------------
# Entre begin_tint() e end_tint() as partes do corpo não vão direto para a
# tela: são juntadas e desenhadas no fim com contorno escuro de 1 px (o
# personagem não some no cenário) e uma linha de luz em cima de cada parte.

const OUTLINE := Color("0b0910")

var outline_color := OUTLINE
var pen: CanvasItem = self      # onde px/raw desenham (o herói desenha a arma num nó da frente)
var _collect := false
var _parts: Array = []
var last_parts: Array = []     # o último corpo desenhado (vira cinza ao morrer)


func px(x: float, y: float, rw: float, rh: float, c: Color) -> void:
	if facing < 0:
		x = -x - rw
	raw(Rect2(x, y, rw, rh), c)


# Parte já em coordenadas locais, sem espelhar (ex.: cachecol com física).
func raw(r: Rect2, c: Color) -> void:
	var color := _tint if _tint.a > 0.0 else c
	if _collect:
		_parts.append([r, color])
	else:
		pen.draw_rect(r, color)


func begin_tint() -> void:
	_tint = Palette.FLASH if flash > 0.0 else Color(0, 0, 0, 0)
	_parts.clear()
	_collect = true


func end_tint() -> void:
	_collect = false
	for p in _parts:
		var c: Color = p[1]
		if c.a >= 0.99:
			pen.draw_rect((p[0] as Rect2).grow(1.0), outline_color)
	var lit := _tint.a <= 0.0
	for p in _parts:
		var r: Rect2 = p[0]
		var c: Color = p[1]
		pen.draw_rect(r, c)
		if lit and c.a >= 0.99 and r.size.y >= 3.0 and r.size.x >= 2.0:
			pen.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), c.lightened(0.2))
	last_parts = _parts.duplicate()
	_tint = Color(0, 0, 0, 0)


func draw_statuses(t: float) -> void:
	if has_status("burn"):
		for i in 3:
			var fx := -w * 0.5 + 2 + i * (w - 4) * 0.5
			var fh := 3.0 + fmod(t * 9.0 + i * 1.7, 3.0)
			pen.draw_rect(Rect2(fx - 1, -h - fh + 4, 2, fh), Palette.BURN)
	if has_status("stun"):
		for i in 3:
			var a := t * 6.0 + i * TAU / 3.0
			pen.draw_rect(Rect2(cos(a) * 6 - 1, -h - 5 + sin(a) * 2, 2, 2), Palette.DANGER)
