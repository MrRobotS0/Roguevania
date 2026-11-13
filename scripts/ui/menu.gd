class_name Menu
extends Control

# Caixa de diálogo do jogo: lista de escolhas ou texto para ler.
# Pausa o jogo enquanto está aberta. ↑/↓ escolhe, J/E/Enter confirma,
# Esc volta (quando permitido).

const WIDTH := 316.0
const PAD := 10.0
const LINE := PixelFont.BODY_LINE
const ROW_H := 16.0           # uma linha por item
const DETAIL_H := 36.0        # painel da explicação do item escolhido (3 linhas)
const FOOT_H := 14.0
const MAX_ROWS := 8
# cores da caixa: painel bem escuro e texto claro, para ler sem esforço
const PANEL := Color("0e0b14")
const HEAD := Color("161120")
const FRAME := Color("5a4d74")
const PICK := Color("2c2340")
const ROW_TEXT := Color("cdc4de")
const SUB := Color("9a8fb4")
const DETAIL := Color("e6dff2")
const DISABLED := Color("625a78")
const DISABLED_PRICE := Color("8a4a52")

var _open := false
var _mode := ""
var _title := ""
var _subtitle := ""
var _options: Array[Dictionary] = []
var _on_pick: Callable
var _cancel_ok := true
var _index := 0
var _body: PackedStringArray = []
var _text_top := 0
const TEXT_ROWS := 15        # linhas de texto visíveis; o resto rola
var _opened_at := 0
var _t := 0.0
var _scroll := 0
var _hit: Array = []          # [retângulo, índice] de cada linha desenhada (mouse)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("menu")
	visible = false


func is_open() -> bool:
	return _open


func open_choice(title: String, subtitle: String, options: Array[Dictionary], on_pick: Callable, cancel_ok := true) -> void:
	_mode = "choice"
	_title = title
	_subtitle = subtitle
	_options = options
	_on_pick = on_pick
	_cancel_ok = cancel_ok
	_index = 0
	_scroll = 0
	while _index < _options.size() - 1 and _options[_index].get("disabled", false):
		_index += 1
	_show()


func open_text(title: String, body: String) -> void:
	_mode = "text"
	_on_pick = Callable()
	_text_top = 0
	_title = title
	_body = PixelFont.wrap(body.to_upper(), int((WIDTH - 24.0) / PixelFont.BODY_ADVANCE))
	_cancel_ok = true
	_show()


func _show() -> void:
	_open = true
	visible = true
	_opened_at = Engine.get_process_frames()
	Controls.lock_ui()
	get_tree().paused = true
	Sfx.play("ui_open", -8.0)


func close() -> void:
	_open = false
	visible = false
	Controls.lock_ui()
	get_tree().paused = false
	get_tree().call_group("player", "absorb_input")


func _process(delta: float) -> void:
	_t += delta
	if not _open:
		return
	queue_redraw()
	if Engine.get_process_frames() - _opened_at < 2 or not Controls.ui_ready():
		return
	if _mode == "text":
		var last := maxi(_body.size() - TEXT_ROWS, 0)
		if Input.is_action_just_pressed("down") and _text_top < last:
			_text_top = mini(_text_top + 3, last)
			Sfx.play("ui_move", -12.0)
		elif Input.is_action_just_pressed("up") and _text_top > 0:
			_text_top = maxi(_text_top - 3, 0)
			Sfx.play("ui_move", -12.0)
		elif Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("cancel") \
				or Input.is_action_just_pressed("interact"):
			close()
		return
	if Input.is_action_just_pressed("up"):
		_move(-1)
	elif Input.is_action_just_pressed("down"):
		_move(1)
	elif Input.is_action_just_pressed("confirm"):
		_confirm()
	elif Input.is_action_just_pressed("cancel") and _cancel_ok:
		close()


# Mouse: passar por cima escolhe a linha, clique confirma, roda rola.
# Teclado e controle continuam iguais; o clique não vira golpe no jogo.
static func row_at(node: CanvasItem, event: InputEvent, hits: Array) -> int:
	if not (event is InputEventMouse):
		return -1
	var p: Vector2 = (node.make_input_local(event) as InputEventMouse).position
	for h: Array in hits:
		if (h[0] as Rect2).has_point(p):
			return int(h[1])
	return -1


func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventMouse):
		return
	if Engine.get_process_frames() - _opened_at < 2 or not Controls.ui_ready():
		return
	var i := row_at(self, event, _hit)
	if event is InputEventMouseMotion:
		if i >= 0 and i != _index:
			_index = i
			Sfx.play("ui_move", -12.0)
		return
	var b := event as InputEventMouseButton
	if b == null or not b.pressed:
		return
	get_viewport().set_input_as_handled()
	if _mode == "text":
		if b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_text_top = mini(_text_top + 3, maxi(_body.size() - TEXT_ROWS, 0))
		elif b.button_index == MOUSE_BUTTON_WHEEL_UP:
			_text_top = maxi(_text_top - 3, 0)
		elif b.button_index == MOUSE_BUTTON_LEFT:
			close()
		return
	match b.button_index:
		MOUSE_BUTTON_WHEEL_DOWN:
			_move(1)
		MOUSE_BUTTON_WHEEL_UP:
			_move(-1)
		MOUSE_BUTTON_LEFT:
			if i >= 0:
				_index = i
				_confirm()
		MOUSE_BUTTON_RIGHT:
			if _cancel_ok:
				close()


func _confirm() -> void:
	if _options[_index].get("disabled", false):
		Sfx.play("block", -8.0)
		return
	var picked := _index
	var cb := _on_pick
	close()
	Sfx.play("ui_ok", -6.0)
	cb.call(picked)


func _move(step: int) -> void:
	_index = wrapi(_index + step, 0, _options.size())
	_follow()
	Sfx.play("ui_move", -12.0)


func select(i: int) -> void:
	if i >= 0 and i < _options.size():
		_index = i
		_follow()


func _follow() -> void:
	if _index < _scroll:
		_scroll = _index
	elif _index >= _scroll + MAX_ROWS:
		_scroll = _index - MAX_ROWS + 1


func choose(i: int) -> void:
	# Usado pelos testes: escolhe sem teclado.
	_index = i
	_follow()
	var cb := _on_pick
	close()
	if _mode == "choice" and cb.is_valid():
		cb.call(i)


func _fit(text: String, room_px: float) -> String:
	var limit := int(room_px / PixelFont.BODY_ADVANCE)
	if text.length() <= limit:
		return text
	return text.substr(0, limit - 3).strip_edges() + "..."


func _draw() -> void:
	if not _open:
		return
	var size := get_viewport_rect().size
	# o jogo some atrás: a caixa é a única coisa a ler
	var veil := Palette.UI_SHADOW
	veil.a = 0.82
	draw_rect(Rect2(Vector2.ZERO, size), veil)

	# "TÍTULO  ·  SALDO": o saldo vai pequeno no canto direito do cabeçalho
	var title := _title
	var info := ""
	if "  ·  " in _title:
		title = _title.get_slice("  ·  ", 0)
		info = _title.get_slice("  ·  ", 1)
	var info_w := float(PixelFont.body_width(info)) + 10.0 if info != "" else 0.0
	var title_scale := 2 if PixelFont.body_width(title, 2) <= WIDTH - PAD * 2 - info_w else 1
	var title_h := 7.0 * title_scale + 8.0
	var sub_lines := PackedStringArray()
	if _subtitle != "":
		sub_lines = PixelFont.wrap(_subtitle.to_upper(), int((WIDTH - PAD * 2) / PixelFont.BODY_ADVANCE))
		sub_lines = sub_lines.slice(0, 2)
	var rows := mini(_options.size(), MAX_ROWS)
	var has_detail := _mode == "choice" and _options.any(func(o: Dictionary) -> bool: return String(o.get("detail", "")) != "")
	var body_h := 0.0
	if _mode == "text":
		body_h = mini(_body.size(), TEXT_ROWS) * LINE + 4.0
	else:
		body_h = rows * ROW_H + (DETAIL_H + 9.0 if has_detail else 0.0)
	var head_h := PAD + title_h + (sub_lines.size() * LINE + 2.0 if sub_lines.size() > 0 else 0.0) + 6.0
	var box_h := head_h + body_h + 8.0 + FOOT_H
	var box := Rect2(roundf((size.x - WIDTH) * 0.5), roundf((size.y - box_h) * 0.5), WIDTH, roundf(box_h))

	# moldura: sombra, borda clara de 1 px e painel sólido
	draw_rect(box.grow(3), Palette.UI_SHADOW)
	draw_rect(box.grow(1), FRAME)
	draw_rect(box, PANEL)
	draw_rect(Rect2(box.position, Vector2(WIDTH, head_h - 4.0)), HEAD)
	draw_rect(Rect2(box.position + Vector2(0, head_h - 4.0), Vector2(WIDTH, 1)), FRAME)

	var x := box.position.x + PAD
	var y := box.position.y + PAD
	PixelFont.body(self, title, Vector2(x, y), Palette.GOLD, title_scale)
	if info != "":
		PixelFont.body(self, info, Vector2(box.end.x - PAD - info_w + 10.0, y + (7 * title_scale - 7) * 0.5), Palette.ESSENCE)
	y += title_h
	for line in sub_lines:
		PixelFont.body(self, line, Vector2(x, y), SUB)
		y += LINE
	y = box.position.y + head_h + 4.0

	if _mode == "text":
		_hit.clear()
		for line in _body.slice(_text_top, _text_top + TEXT_ROWS):
			PixelFont.body(self, line, Vector2(x, y), Palette.UI_TEXT)
			y += LINE
		var hint := "%s CONTINUAR" % Controls.hint("confirm")
		if _body.size() > TEXT_ROWS:
			hint = "%s ROLAR %d/%d   " % [Controls.hint("move"), mini(_text_top + TEXT_ROWS, _body.size()), _body.size()] + hint
		_footer(box, hint)
		return

	# lista: uma linha por item (ícone, nome e preço à direita); a explicação
	# fica só no painel de baixo, e só do item escolhido
	var with_icons := _options.any(func(o: Dictionary) -> bool: return o.get("icon") != null or o.has("figure"))
	var text_x := x + (20.0 if with_icons else 4.0)
	_hit.clear()
	for i in range(_scroll, _scroll + rows):
		var o := _options[i]
		var disabled: bool = o.get("disabled", false)
		var selected := i == _index
		var row := Rect2(box.position.x + 4, y, WIDTH - 8, ROW_H - 1)
		_hit.append([row, i])
		if selected:
			draw_rect(row, PICK)
			draw_rect(Rect2(row.position, Vector2(2, row.size.y)), Palette.GOLD)
		var label_color := ROW_TEXT
		if selected:
			label_color = Palette.UI_TEXT
		if disabled:
			label_color = DISABLED
		var custom: Variant = o.get("color")
		if custom != null and not disabled and o.has("price") == false:
			label_color = custom
		var ty := y + roundf((ROW_H - 1 - 7) * 0.5) - 2.0
		if o.get("icon") != null:
			draw_texture(o["icon"], Vector2(x, y - 1).round(), Color(1, 1, 1, 0.4) if disabled else Color.WHITE)
		var price := String(o.get("price", ""))
		var price_w := float(PixelFont.body_width(price)) if price != "" else 0.0
		var room := box.end.x - PAD - text_x - (price_w + 8.0 if price != "" else 0.0)
		PixelFont.body(self, _fit(String(o["label"]).to_upper(), room), Vector2(text_x, ty), label_color)
		if price != "":
			var pc: Color = o.get("price_color", Palette.GOLD)
			PixelFont.body(self, price, Vector2(box.end.x - PAD - price_w, ty), DISABLED_PRICE if disabled else pc)
		y += ROW_H
	if _scroll > 0:
		PixelFont.body(self, "↑", Vector2(box.end.x - 9, box.position.y + head_h - 2), SUB)
	if _scroll + rows < _options.size():
		PixelFont.body(self, "↓", Vector2(box.end.x - 9, y - 10), SUB)

	if has_detail:
		y += 4.0
		draw_rect(Rect2(box.position.x + PAD, y, WIDTH - PAD * 2, 1), FRAME)
		y += 5.0
		var o := _options[_index]
		var room := WIDTH - PAD * 2 - (30.0 if o.has("figure") else 0.0)
		var lines := PixelFont.wrap(String(o.get("detail", "")).to_upper(), int(room / PixelFont.BODY_ADVANCE))
		var dy := y
		for line in lines.slice(0, 3):
			PixelFont.body(self, line, Vector2(x, dy), DETAIL)
			dy += LINE
		if o.has("figure"):
			HeroLook.draw_figure(self, Vector2(box.end.x - PAD - 14, y + DETAIL_H - 6), o["figure"], o.get("disabled", false))

	var hint := "%s ESCOLHER   %s OK" % [Controls.hint("move"), Controls.hint("confirm")]
	if _cancel_ok:
		hint += "   %s SAIR" % Controls.hint("cancel")
	_footer(box, hint)


# Rodapé: as teclas numa faixa própria, em letra pequena, sem disputar com a lista.
func _footer(box: Rect2, hint: String) -> void:
	var top := box.end.y - FOOT_H
	draw_rect(Rect2(box.position.x, top, WIDTH, 1), FRAME)
	draw_rect(Rect2(box.position.x, top + 1, WIDTH, FOOT_H - 1), HEAD)
	PixelFont.body(self, hint, Vector2(box.position.x + PAD, top + 1), SUB)
