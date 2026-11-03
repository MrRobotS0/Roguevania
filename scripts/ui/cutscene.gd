class_name Cutscene
extends Control

# Telas de história: texto que aparece letra a letra sobre o fundo escuro.
# Confirmar completa a frase ou passa a página; cancelar pula tudo.

signal finished

const SPEED := 45.0          # letras por segundo
const WIDTH := 52            # letras por linha

var _pages: PackedStringArray = []
var _page := 0
var _shown := 0.0
var _done: Callable
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return visible


func play(pages: PackedStringArray, on_done: Callable) -> void:
	_pages = pages
	_page = 0
	_shown = 0.0
	_done = on_done
	_t = 0.0
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_shown += delta * SPEED
	queue_redraw()
	if _t < 0.3:
		return
	if Input.is_action_just_pressed("cancel"):
		_finish()
	elif Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("attack1"):
		advance()


# Também usado pelos testes.
func advance() -> void:
	if not visible or _page >= _pages.size():
		return
	if _shown < _pages[_page].length():
		_shown = _pages[_page].length()
		return
	_page += 1
	_shown = 0.0
	Sfx.play("page", -10.0)
	if _page >= _pages.size():
		_finish()


func _finish() -> void:
	visible = false
	finished.emit()
	if _done.is_valid():
		_done.call()


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("07060b"))
	if _page >= _pages.size():
		return
	var text := _pages[_page].substr(0, int(_shown))
	var lines := PixelFont.wrap(text.to_upper(), WIDTH)
	var y := size.y * 0.5 - lines.size() * PixelFont.BODY_LINE * 0.5
	for line in lines:
		PixelFont.body_centered(self, line, Vector2(size.x * 0.5, y), Palette.UI_TEXT)
		y += PixelFont.BODY_LINE
	for i in _pages.size():
		var c := Palette.GOLD if i == _page else Palette.UI_FRAME
		draw_rect(Rect2(size.x * 0.5 - _pages.size() * 5 + i * 10, size.y - 30, 4, 4), c)
	var hint := "%s CONTINUAR   %s PULAR" % [Controls.hint("confirm"), Controls.hint("cancel")]
	PixelFont.draw_centered(self, hint, Vector2(size.x * 0.5, size.y - 14), Palette.UI_DIM)
