class_name Foreground
extends Node2D

# Silhuetas que passam NA FRENTE da câmera, mais rápido que o mundo
# (paralaxe > 1): pedra pendurada no alto, pano rasgado, entulho embaixo.
# Dão profundidade sem tapar o jogo: ficam nas bordas e bem espaçadas.
# A borda de cima pega um fio da luz do céu, senão viram borrão.
# Coordenadas de tela (CanvasLayer).

const SPEED := 1.45
const SPACING := 380.0
const RIM := 0.18          # quanto a borda de cima clareia

var style := ""
var ink := Color("0e0b0d")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if style == "" or style == "columns":
		return
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var scroll := cam.get_screen_center_position().x * SPEED
	var first := floori(scroll / SPACING) - 1
	for i in range(first, first + int(size.x / SPACING) + 3):
		var x := floorf(i * SPACING - scroll)
		var seed := absi(i * 7919)
		match seed % 3:
			0:
				_overhang(x, seed)
			1:
				_drapes(x, seed)
			_:
				_rubble(x, size.y, seed)



# Rocha pendurada do alto, com a ponta irregular.
func _overhang(x: float, seed: int) -> void:
	var wide := 90 + seed % 50
	var col := 0
	while col < wide:
		var step := 6
		var t := float(col) / wide
		var hang := 10.0 + sin(t * PI) * (26.0 + seed % 14) + float((seed >> (col % 7)) % 5)
		draw_rect(Rect2(x + col, -2, step, hang), ink)
		draw_rect(Rect2(x + col, hang - 3, step, 1), ink.lightened(RIM))
		col += step


# Dois panos rasgados pendurados de uma viga.
func _drapes(x: float, seed: int) -> void:
	draw_rect(Rect2(x - 6, 6, 70, 5), ink)
	draw_rect(Rect2(x - 6, 6, 70, 1), ink.lightened(RIM))
	for k in 2:
		var px := x + 6 + k * 30
		var long := 34 + (seed >> k) % 20
		draw_rect(Rect2(px, 11, 14, long), ink.lerp(Color("5a1a20"), 0.25))
		draw_rect(Rect2(px, 11, 1, long), ink.lerp(Color("5a1a20"), 0.45))
		draw_rect(Rect2(px, 11 + long, 5, 4), ink.lerp(Color("5a1a20"), 0.25))
		draw_rect(Rect2(px + 8, 11 + long, 6, 7), ink.lerp(Color("5a1a20"), 0.25))


# Entulho e uma coluna caída no canto de baixo.
func _rubble(x: float, bottom: float, seed: int) -> void:
	var base := bottom + 2.0
	var blocks := [[0, 14, 30], [22, 22, 24], [40, 12, 34], [58, 18, 20], [72, 10, 26]]
	for b in blocks:
		var h: int = b[1] + seed % 6
		draw_rect(Rect2(x + b[0], base - h, b[2], h), ink)
		draw_rect(Rect2(x + b[0], base - h, b[2], 1), ink.lightened(RIM))
	draw_rect(Rect2(x + 10, base - 30, 54, 9), ink)
	draw_rect(Rect2(x + 10, base - 30, 54, 1), ink.lightened(RIM))
