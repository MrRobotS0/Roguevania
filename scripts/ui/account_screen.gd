class_name AccountScreen
extends Control

# Conta de moksha.com.br na versão Windows (EXTRAS > CONTA). Dois campos
# desenhados com a fonte do jogo: usuário (ou e-mail) e senha. Tab ou ↑/↓
# troca de campo, Enter entra, Esc volta. Logado, mostra quem é e deixa sair.

const WIDTH := 330.0
const MAX_LEN := 64
const ERRORS := {
	"login_invalido": "USUÁRIO/E-MAIL OU SENHA ERRADOS",
	"muitas_tentativas": "MUITAS TENTATIVAS. ESPERE ALGUNS MINUTOS",
	"sem_personagem": "CRIE SEU PERSONAGEM EM MOKSHA.COM.BR PRIMEIRO",
	"rede": "SEM CONEXÃO COM MOKSHA.COM.BR",
	"outro": "ALGO DEU ERRADO. TENTE DE NOVO",
}

signal closed

var _fields := ["", ""]
var _index := 0
var _busy := false
var _msg := ""
var _msg_color := Palette.UI_DIM
var _was_paused := false
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	_fields = [Meta.desk_user, ""]
	_index = 0 if Meta.desk_user == "" else 1
	_msg = ""
	_busy = false
	_was_paused = get_tree().paused
	get_tree().paused = true
	visible = true
	Controls.lock_ui()
	Sfx.play("ui_open", -8.0)


func close() -> void:
	visible = false
	Controls.lock_ui()
	get_tree().paused = _was_paused
	closed.emit()


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or _busy or not Controls.ui_ready():
		return
	get_viewport().set_input_as_handled()
	if Meta.desk_logged_in():
		# logado: confirmar sai da conta, voltar fecha
		if event.is_action_pressed("cancel"):
			close()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
			Meta.desktop_logout()
			Sfx.play("ui_ok", -8.0)
			_msg = "VOCÊ SAIU DA CONTA. O PROGRESSO SEGUE NESTE PC"
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				close()
			KEY_TAB, KEY_DOWN, KEY_UP:
				_index = 1 - _index
				Sfx.play("ui_move", -10.0)
			KEY_BACKSPACE:
				_fields[_index] = String(_fields[_index]).left(-1)
			KEY_ENTER, KEY_KP_ENTER:
				if _index == 0:
					_index = 1
				else:
					_submit()
			_:
				var ch := char(event.unicode) if event.unicode >= 32 else ""
				if ch != "" and String(_fields[_index]).length() < MAX_LEN:
					_fields[_index] = String(_fields[_index]) + ch
	elif event is InputEventJoypadButton and event.pressed and event.is_action_pressed("cancel"):
		close()


func _submit() -> void:
	if String(_fields[0]).strip_edges() == "" or String(_fields[1]) == "":
		_msg = "PREENCHA USUÁRIO (OU E-MAIL) E SENHA"
		_msg_color = Palette.DANGER
		return
	_busy = true
	_msg = "ENTRANDO..."
	_msg_color = Palette.UI_DIM
	var err: String = await Meta.desktop_login(String(_fields[0]).strip_edges(), String(_fields[1]))
	_busy = false
	_fields[1] = ""
	if err == "":
		Sfx.play("unlock", -6.0)
		_msg = ""
		Fx.toast("CONTA CONECTADA: %s" % Meta.player_name.to_upper())
		close()
	else:
		Sfx.play("ui_move", -6.0)
		_msg = ERRORS.get(err, ERRORS["outro"])
		_msg_color = Palette.DANGER


func _draw() -> void:
	if not visible:
		return
	var size := get_viewport_rect().size
	var veil := Palette.UI_SHADOW
	veil.a = 0.82
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	var head := 30.0
	var box_h := 164.0
	var box := Rect2(roundf((size.x - WIDTH) * 0.5), roundf((size.y - box_h) * 0.5), WIDTH, box_h)
	draw_rect(box.grow(3), Palette.UI_SHADOW)
	draw_rect(box.grow(1), Menu.FRAME)
	draw_rect(box, Menu.PANEL)
	draw_rect(Rect2(box.position, Vector2(WIDTH, head)), Menu.HEAD)
	draw_rect(Rect2(box.position + Vector2(0, head), Vector2(WIDTH, 1)), Menu.FRAME)
	var x := box.position.x + 12.0
	PixelFont.body(self, "CONTA", Vector2(x, box.position.y + 8.0), Palette.GOLD, 2)
	var y := box.position.y + head + 10.0
	if Meta.desk_logged_in():
		PixelFont.body(self, "CONECTADO COMO", Vector2(x, y), Palette.UI_DIM)
		PixelFont.body(self, Meta.player_name.to_upper(), Vector2(x, y + 14), Palette.GOLD, 2)
		PixelFont.body(self, "O PROGRESSO DESTE PC E DO SITE É O MESMO", Vector2(x, y + 40), Palette.UI_TEXT)
		if _msg != "":
			PixelFont.body(self, _msg, Vector2(x, y + 58), Palette.UI_DIM)
		PixelFont.body(self, "ENTER SAIR DA CONTA   ESC VOLTAR", Vector2(x, box.end.y - 14), Palette.UI_DIM)
		return
	PixelFont.body(self, "ENTRE COM SUA CONTA DE MOKSHA.COM.BR", Vector2(x, y), Palette.UI_TEXT)
	y += 18.0
	var labels := ["USUÁRIO OU E-MAIL", "SENHA"]
	for i in 2:
		var selected := i == _index
		PixelFont.body(self, labels[i], Vector2(x, y), Palette.GOLD if selected else Palette.UI_DIM)
		var field := Rect2(x, y + 9, WIDTH - 24, 14)
		draw_rect(field, Palette.UI_SHADOW)
		draw_rect(field, Palette.GOLD if selected else Menu.FRAME, false, 1.0)
		var shown := String(_fields[i]) if i == 0 else "*".repeat(String(_fields[i]).length())
		# só o fim do texto cabe no campo
		while PixelFont.body_width(shown) > field.size.x - 14 and shown.length() > 0:
			shown = shown.substr(1)
		if selected and int(_t * 2.0) % 2 == 0 and not _busy:
			shown += "_"
		PixelFont.body(self, shown, Vector2(field.position.x + 4, field.position.y + 3), Palette.UI_TEXT)
		y += 28.0
	if _msg != "":
		PixelFont.body(self, _msg, Vector2(x, y), _msg_color)
	PixelFont.body(self, "TAB TROCA   ENTER ENTRAR   ESC VOLTAR", Vector2(x, box.end.y - 14), Palette.UI_DIM)
	PixelFont.body(self, "SEM CONTA? CRIE EM MOKSHA.COM.BR", Vector2(x, box.end.y - 28), Palette.UI_DIM)
