class_name Guide
extends Control

# Dicas da primeira partida: só a tecla de cada comando, uma vez na vida, na
# hora em que faz falta (o primeiro inimigo, o primeiro aviso de golpe), e
# somem quando o jogador faz o que ela mostra. Desliga em OPÇÕES > DICAS.
#
# No texto, {acao} vira a tecla daquela ação no aparelho em uso.

const HOLD := 7.0
const MIN_SHOW := 1.6
const SLIDE := 0.2
const FADE := 0.3

const HINTS := {
	"andar": "{walk} ANDAR   {jump} PULAR",
	"atacar": "{attack1} {attack2} ATACAR",
	"rolar": "{roll} ESQUIVAR",
	"curar": "{heal} CURAR",
	"mergulho": "NO AR: {down} + {attack1}",
}

var level: Level
var _id := ""
var _t := 0.0
var _done := false
var _flasks_at := 0
var _queue: Array[String] = []
var _banner_clock := 99.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# o nome do lugar ocupa o meio da tela por uns 3 s: a dica espera
	Fx.bannered.connect(func(_a: String, _b: String) -> void: _banner_clock = 0.0)


func bind(lv: Level) -> void:
	level = lv
	_id = ""
	_queue.clear()


func seen(id: String) -> bool:
	return Meta.data.get("hints", []).has(id)


func _mark(id: String) -> void:
	var list: Array = Meta.data.get("hints", [])
	if not list.has(id):
		list.append(id)
		Meta.data["hints"] = list
		Meta.save()


func showing() -> String:
	return _id


func _process(delta: float) -> void:
	queue_redraw()
	_banner_clock += delta
	if not Options.get_value("hints") or level == null or not is_instance_valid(level):
		_id = ""
		return
	var p := level.player
	if p == null or not is_instance_valid(p) or not p.alive():
		return
	if _id == "":
		_watch(p)
		if not _queue.is_empty() and _banner_clock > 3.3:
			_start(_queue.pop_front(), p)
		return
	_t += delta
	if not _done and _t >= MIN_SHOW and _learned(_id, p):
		_done = true
		_t = maxf(_t, HOLD - FADE)
	if _t >= HOLD:
		_id = ""


func _start(id: String, p: Player) -> void:
	_id = id
	_t = 0.0
	_done = false
	_flasks_at = p.flasks
	_mark(id)


func _want(id: String) -> void:
	if not seen(id) and not _queue.has(id) and _id != id:
		_queue.append(id)


# Quando cada dica merece aparecer.
func _watch(p: Player) -> void:
	if level.kind == "gerada" and Run.stage_time > 0.6:
		_want("andar")
	for e: Enemy in level.enemies():
		if not e.alive():
			continue
		var d := e.center().distance_to(p.center())
		if d < 170.0:
			_want("atacar")
		if d < 120.0 and e.telegraphing() and seen("atacar"):
			_want("rolar")
	if p.hp < p.max_hp * 0.45 and p.flasks > 0:
		_want("curar")
	if p.kills >= 4:
		_want("mergulho")


# A dica sai mais cedo quando o jogador já fez o que ela pede.
func _learned(id: String, p: Player) -> bool:
	match id:
		"andar":
			return not p.is_on_floor() and p.velocity.y < 0.0
		"atacar":
			return p.state in [Player.State.ATTACK, Player.State.SHOOT]
		"rolar":
			return p.state == Player.State.ROLL
		"curar":
			return p.flasks < _flasks_at
		"mergulho":
			return p.state == Player.State.DIVE
	return false


func _draw() -> void:
	if _id == "" or not Options.get_value("hints"):
		return
	var lines := String(HINTS[_id]).split("\n")
	var enter := clampf(_t / SLIDE, 0.0, 1.0)
	var slide := 1.0 - pow(1.0 - enter, 3.0)
	var a := clampf((HOLD - _t) / FADE, 0.0, 1.0)
	var w := 0.0
	for line in lines:
		w = maxf(w, _line_width(line))
	w += 16.0
	var h := 14.0 + lines.size() * PixelFont.BODY_LINE
	var at := Vector2(roundf(lerpf(-w, 6.0, slide)), 44.0)
	var bg := Palette.UI_SHADOW
	bg.a = 0.82 * a
	draw_rect(Rect2(at, Vector2(w, h)), bg)
	var edge := Palette.GOLD
	edge.a = a
	draw_rect(Rect2(at, Vector2(2, h)), edge)
	var label := Palette.GOLD
	label.a = 0.9 * a
	PixelFont.draw(self, "DICA", at + Vector2(8, 4), label)
	var y := at.y + 13.0
	for line in lines:
		_draw_line(line, Vector2(at.x + 8.0, y), a)
		y += PixelFont.BODY_LINE


# Texto com {acao}: a tecla vira uma plaquinha, como no aviso de "usar".
func _parts(line: String) -> Array:
	var out: Array = []
	var rest := line
	while true:
		var i := rest.find("{")
		var j := rest.find("}", i)
		if i < 0 or j < 0:
			out.append([rest, false])
			break
		out.append([rest.substr(0, i), false])
		out.append([Controls.hint(rest.substr(i + 1, j - i - 1)), true])
		rest = rest.substr(j + 1)
	return out


func _line_width(line: String) -> float:
	var w := 0.0
	for part in _parts(line):
		w += PixelFont.body_width(part[0]) + (6.0 if part[1] else 0.0)
	return w


func _draw_line(line: String, pos: Vector2, a: float) -> void:
	var x := pos.x
	for part in _parts(line):
		var text: String = part[0]
		if part[1]:
			var frame := Palette.UI_FRAME
			frame.a = a
			var kw := PixelFont.body_width(text) + 4.0
			draw_rect(Rect2(x - 1, pos.y - 2, kw, 11), frame)
			var gold := Palette.GOLD
			gold.a = a
			PixelFont.body(self, text, Vector2(x + 1, pos.y), gold)
			x += kw + 2.0
		else:
			var c := Palette.UI_TEXT
			c.a = a
			PixelFont.body(self, text, Vector2(x, pos.y), c)
			x += PixelFont.body_width(text)
