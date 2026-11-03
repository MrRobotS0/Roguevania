class_name Hud
extends Control

# Vida (com a "sombra" amarela do dano recente), frascos de cura,
# dica de comandos e o aviso de morte. Tudo em pixel, na resolução interna.

const HINT_1 := "A/D MOVER   ESPAÇO PULAR   J ATACAR   SHIFT ROLAR"
const HINT_2 := "S+J NO AR MERGULHO   Q CURAR   S+ESPAÇO DESCE   F5 REINICIA   F1 DEBUG"
const BAR := Vector2(96, 7)

var player: Player
var _ghost := 1.0
var _ghost_wait := 0.0
var _death := -1.0


func bind(who: Player) -> void:
	player = who
	_ghost = 1.0
	_death = -1.0
	who.health_changed.connect(_on_health)
	who.died.connect(func() -> void: _death = 0.0)


func _on_health(_hp: int, _max: int) -> void:
	_ghost_wait = 0.45


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var ratio := float(player.hp) / player.max_hp
	if ratio > _ghost:
		_ghost = ratio
	_ghost_wait -= delta
	if _ghost_wait <= 0.0:
		_ghost = move_toward(_ghost, ratio, delta * 0.8)
	if _death >= 0.0:
		_death += delta
	queue_redraw()


func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var size := get_viewport_rect().size
	_draw_health(Vector2(8, 8))
	_draw_flasks(Vector2(8, 20))

	var hint := Palette.UI_DIM
	hint.a = 0.85
	PixelFont.draw(self, HINT_1, Vector2(8, size.y - 18), hint)
	PixelFont.draw(self, HINT_2, Vector2(8, size.y - 10), hint)

	if _death >= 0.0:
		var k := clampf(_death / 0.25, 0.0, 1.0)
		var veil := Palette.UI_SHADOW
		veil.a = 0.55 * k
		draw_rect(Rect2(Vector2.ZERO, size), veil)
		var title := Palette.HURT
		title.a = k
		PixelFont.draw_centered(self, "VOCÊ MORREU", size * 0.5 + Vector2(0, -6), title, 3)


func _draw_health(at: Vector2) -> void:
	var ratio := float(player.hp) / player.max_hp
	draw_rect(Rect2(at - Vector2(2, 2), BAR + Vector2(4, 4)), Palette.UI_SHADOW)
	draw_rect(Rect2(at - Vector2(1, 1), BAR + Vector2(2, 2)), Palette.UI_FRAME)
	draw_rect(Rect2(at, BAR), Palette.UI_BAR_BG)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * _ghost), BAR.y)), Palette.UI_HP_GHOST)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * ratio), BAR.y)), Palette.UI_HP)
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * ratio), 1)), Palette.UI_HP.lightened(0.35))
	PixelFont.draw(self, "%d/%d" % [player.hp, player.max_hp], at + Vector2(BAR.x + 6, 1), Palette.UI_TEXT)


func _draw_flasks(at: Vector2) -> void:
	for i in Player.MAX_FLASKS:
		var p := at + Vector2(i * 9, 0)
		var full := i < player.flasks
		var glass := Palette.UI_DIM if full else Palette.UI_FRAME
		draw_rect(Rect2(p + Vector2(2, 0), Vector2(3, 2)), glass)
		draw_rect(Rect2(p + Vector2(1, 2), Vector2(5, 6)), glass)
		draw_rect(Rect2(p + Vector2(2, 4), Vector2(3, 3)), Palette.UI_HP if full else Palette.UI_BAR_BG)
