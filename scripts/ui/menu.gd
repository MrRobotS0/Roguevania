class_name Menu
extends Control

# Caixa de diálogo do jogo: lista de escolhas ou texto para ler.
# Pausa o jogo enquanto está aberta. ↑/↓ escolhe, J/E/Enter confirma,
# Esc volta (quando permitido).

const WIDTH := 384.0
const LINE := PixelFont.BODY_LINE
const ROW := LINE * 2 + 3
const MAX_ROWS := 6

var _open := false
var _mode := ""
var _title := ""
var _subtitle := ""
var _options: Array[Dictionary] = []
var _on_pick: Callable
var _cancel_ok := true
var _index := 0
var _body: PackedStringArray = []
var _opened_at := 0
var _t := 0.0
var _scroll := 0


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
	_title = title
	_body = PixelFont.wrap(body.to_upper(), int((WIDTH - 24.0) / PixelFont.BODY_ADVANCE))
	_cancel_ok = true
	_show()


func _show() -> void:
	_open = true
	visible = true
	_opened_at = Engine.get_process_frames()
	get_tree().paused = true
	Sfx.play("ui_open", -8.0)


func close() -> void:
	_open = false
	visible = false
	get_tree().paused = false
	get_tree().call_group("player", "absorb_input")


func _process(delta: float) -> void:
	_t += delta
	if not _open:
		return
	queue_redraw()
	if Engine.get_process_frames() - _opened_at < 2:
		return
	if _mode == "text":
		if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("cancel") \
				or Input.is_action_just_pressed("interact"):
			close()
		return
	if Input.is_action_just_pressed("up"):
		_move(-1)
	elif Input.is_action_just_pressed("down"):
		_move(1)
	elif Input.is_action_just_pressed("confirm"):
		if _options[_index].get("disabled", false):
			Sfx.play("block", -8.0)
			return
		var picked := _index
		var cb := _on_pick
		close()
		Sfx.play("ui_ok", -6.0)
		cb.call(picked)
	elif Input.is_action_just_pressed("cancel") and _cancel_ok:
		close()


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
	var veil := Palette.UI_SHADOW
	veil.a = 0.6
	draw_rect(Rect2(Vector2.ZERO, size), veil)

	var sub_lines := PackedStringArray()
	if _subtitle != "":
		sub_lines = PixelFont.wrap(_subtitle.to_upper(), int((WIDTH - 24.0) / PixelFont.BODY_ADVANCE))
	var rows := mini(_options.size(), MAX_ROWS)
	var box_h := 0.0
	if _mode == "text":
		box_h = 34.0 + (_body.size() + 2) * LINE
	else:
		box_h = 34.0 + sub_lines.size() * LINE + 6.0 + rows * ROW + LINE + 4.0
	var box := Rect2(roundf((size.x - WIDTH) * 0.5), roundf((size.y - box_h) * 0.5), WIDTH, roundf(box_h))
	draw_rect(box.grow(2), Palette.UI_SHADOW)
	draw_rect(box.grow(1), Palette.UI_FRAME)
	draw_rect(box, Palette.UI_BAR_BG)
	draw_rect(Rect2(box.position, Vector2(WIDTH, 1)), Palette.UI_FRAME.lightened(0.25))
	var x := box.position.x + 12.0
	var y := box.position.y + 11.0
	PixelFont.body(self, _title, Vector2(x, y), Palette.GOLD, 2)
	y += 23.0

	if _mode == "text":
		for line in _body:
			PixelFont.body(self, line, Vector2(x, y), Palette.UI_TEXT)
			y += LINE
		y += LINE * 0.5
		PixelFont.body(self, "%s  CONTINUAR" % Controls.hint("confirm"), Vector2(x, y), Palette.UI_DIM)
		return

	for line in sub_lines:
		PixelFont.body(self, line, Vector2(x, y), Palette.UI_DIM)
		y += LINE
	y += 6.0
	if _scroll > 0:
		PixelFont.body(self, "↑", Vector2(box.end.x - 14, y - 9), Palette.UI_DIM)
	for i in range(_scroll, _scroll + rows):
		var o := _options[i]
		var disabled: bool = o.get("disabled", false)
		var selected := i == _index
		var color: Color = o.get("color", Palette.UI_TEXT)
		if disabled:
			color = Palette.UI_FRAME.lightened(0.3)
		if selected:
			var hl := Palette.UI_FRAME
			hl.a = 0.6
			draw_rect(Rect2(box.position.x + 4, y - 4, WIDTH - 8, ROW - 1), hl)
			draw_rect(Rect2(box.position.x + 4, y - 4, 2, ROW - 1), Palette.GOLD)
			var bob := 1.0 if int(_t * 4.0) % 2 == 0 else 0.0
			PixelFont.body(self, ">", Vector2(x - 4 + bob, y), Palette.GOLD)
		var room_px := WIDTH - 30.0 - (28.0 if o.has("figure") else 0.0)
		PixelFont.body(self, _fit(String(o["label"]).to_upper(), room_px), Vector2(x + 6, y), color)
		if o.has("detail"):
			var detail_color := Palette.UI_DIM if not disabled else color
			PixelFont.body(self, _fit(String(o["detail"]).to_upper(), room_px), Vector2(x + 6, y + LINE), detail_color)
		if o.has("figure"):
			HeroLook.draw_figure(self, Vector2(box.end.x - 18, y + ROW - 6), o["figure"], disabled)
		y += ROW
	if _scroll + rows < _options.size():
		PixelFont.body(self, "↓", Vector2(box.end.x - 14, y - 6), Palette.UI_DIM)
	y += 2.0
	var hint := "%s ESCOLHER   %s CONFIRMAR" % [Controls.hint("move"), Controls.hint("confirm")]
	if _cancel_ok:
		hint += "   %s VOLTAR" % Controls.hint("cancel")
	PixelFont.body(self, hint, Vector2(x, y), Palette.UI_DIM)
