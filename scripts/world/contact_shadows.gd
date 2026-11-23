class_name ContactShadows
extends Node2D

# A sombra de cada personagem no chão logo abaixo dele: uma elipse em pixel
# que encolhe e clareia com a altura. Prende o herói e os inimigos ao chão
# (sem ela tudo parece colado no cenário) e, no pulo, mostra onde vai cair.
# Fica por cima dos blocos e por baixo dos personagens (ordem na árvore).

const REACH := 12          # blocos procurando o chão para baixo
const FADE := 140.0        # px de altura em que a sombra some

var room: Room


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if room == null:
		return
	var cam := get_viewport().get_camera_2d()
	var view := Rect2(cam.get_screen_center_position() - Vector2(400, 260), Vector2(800, 520)) if cam else Rect2()
	for group in ["player", "enemies"]:
		for n in get_tree().get_nodes_in_group(group):
			var a := n as Actor
			if a == null or not a.alive() or not a.visible or a.get("ghost"):
				continue
			if cam and not view.has_point(a.global_position):
				continue
			_shadow(a)


func _shadow(a: Actor) -> void:
	var feet := a.global_position
	var cx := floori(feet.x / Room.TILE)
	var cy := floori((feet.y - 1.0) / Room.TILE)
	var ground := INF
	for i in REACH:
		var y := cy + i
		if room._blocky(cx, y) and not room._blocky(cx, y - 1):
			ground = y * Room.TILE
			break
	if ground == INF:
		return
	var height := ground - feet.y
	if height < -4.0:
		return
	var k := clampf(1.0 - height / FADE, 0.0, 1.0)
	if k <= 0.05:
		return
	var half := roundf(maxf(a.w, 8.0) * (0.55 + 0.45 * k) + 2.0)
	var alpha := 0.62 * k
	var at := Vector2(roundf(feet.x), ground - 1.0)
	# elipse em degraus de pixel: miolo escuro, borda mais clara
	draw_rect(Rect2(at.x - half, at.y - 1, half * 2.0, 2), Color(0, 0, 0, alpha * 0.55))
	draw_rect(Rect2(at.x - half + 2, at.y - 2, half * 2.0 - 4, 4), Color(0, 0, 0, alpha * 0.6))
	draw_rect(Rect2(at.x - half * 0.6, at.y - 2, half * 1.2, 3), Color(0, 0, 0, alpha * 0.7))
