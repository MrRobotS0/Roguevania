class_name Menu
extends Control

# Caixa de diálogo do jogo: lista de escolhas ou texto para ler.
# Pausa o jogo enquanto está aberta. ↑/↓ escolhe, J/E/Enter confirma,
# Esc volta (quando permitido).

const WIDTH := 360.0
const LINE := 9.0

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
	while _index < _options.size() - 1 and _options[_index].get("disabled", false):
		_index += 1
	_show()


func open_text(title: String, body: String) -> void:
	_mode = "text"
	_title = title
	_body = PixelFont.wrap(body.to_upper(), int((WIDTH - 24.0) / PixelFont.ADVANCE))
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
	Sfx.play("ui_move", -12.0)


func choose(i: int) -> void:
	# Usado pelos testes: escolhe sem teclado.
	_index = i
	var cb := _on_pick
	close()
	cb.call(i)


func _draw() -> void:
	if not _open:
		return
	var size := get_viewport_rect().size
	var veil := Palette.UI_SHADOW
	veil.a = 0.6
	draw_rect(Rect2(Vector2.ZERO, size), veil)

	var lines := 0
	if _mode == "text":
		lines = _body.size() + 2
	else:
		lines = _options.size() * 2 + 3
	var box_h := 34.0 + lines * LINE
	var box := Rect2((size.x - WIDTH) * 0.5, (size.y - box_h) * 0.5, WIDTH, box_h)
	draw_rect(box.grow(2), Palette.UI_SHADOW)
	draw_rect(box.grow(1), Palette.UI_FRAME)
	draw_rect(box, Palette.UI_BAR_BG)
	var x := box.position.x + 12.0
	var y := box.position.y + 10.0
	PixelFont.draw(self, _title, Vector2(x, y), Palette.GOLD, 2)
	y += 16.0

	if _mode == "text":
		for line in _body:
			PixelFont.draw(self, line, Vector2(x, y), Palette.UI_TEXT)
			y += LINE
		y += LINE
		PixelFont.draw(self, "J / E  CONTINUAR", Vector2(x, y), Palette.UI_DIM)
		return

	if _subtitle != "":
		for line in PixelFont.wrap(_subtitle.to_upper(), int((WIDTH - 24.0) / PixelFont.ADVANCE)):
			PixelFont.draw(self, line, Vector2(x, y), Palette.UI_DIM)
			y += LINE
	y += 4.0
	for i in _options.size():
		var o := _options[i]
		var disabled: bool = o.get("disabled", false)
		var selected := i == _index
		var color: Color = o.get("color", Palette.UI_TEXT)
		if disabled:
			color = Palette.UI_FRAME.lightened(0.2)
		if selected:
			var hl := Palette.UI_FRAME
			hl.a = 0.6
			draw_rect(Rect2(box.position.x + 4, y - 2, WIDTH - 8, LINE * 2 + 1), hl)
			var bob := 1.0 if int(_t * 4.0) % 2 == 0 else 0.0
			PixelFont.draw(self, ">", Vector2(x - 6 + bob, y), Palette.GOLD)
		PixelFont.draw(self, String(o["label"]).to_upper(), Vector2(x + 2, y), color)
		if o.has("detail"):
			PixelFont.draw(self, String(o["detail"]).to_upper(), Vector2(x + 2, y + LINE), Palette.UI_DIM if not disabled else color)
		y += LINE * 2 + 1
	y += 2.0
	var hint := "W/S ESCOLHER   J/E CONFIRMAR" + ("   ESC VOLTAR" if _cancel_ok else "")
	PixelFont.draw(self, hint, Vector2(x, y), Palette.UI_DIM)
