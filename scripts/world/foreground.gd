class_name Foreground
extends Node2D

# Silhuetas que passam NA FRENTE da câmera, mais rápido que o mundo
# (paralaxe > 1): pedra pendurada no alto, o que o domínio pendura do teto
# (ou pano rasgado), entulho embaixo.
# Dão profundidade sem tapar o jogo: ficam nas bordas e bem espaçadas.
# São feitas da pedra do próprio domínio (o atlas da parede de fundo, com a
# beira quebrada) quase sem luz: o que está perto de quem olha é escuro, mas
# tem matéria. Domínio sem esse atlas cai nos blocos chapados de antes, com a
# borda de cima pegando um fio da luz do céu.
# Coordenadas de tela (CanvasLayer): nenhuma luz do mundo chega aqui.

const SPEED := 1.45
const SPACING := 380.0
const RIM := 0.18          # quanto a borda de cima clareia (blocos chapados)
const TILE := 16
const DARK := 0.3          # quanto da cor da pedra sobra na silhueta

var style := ""
var ink := Color("0e0b0d")
var biome_id := "":
	set(v):
		if v == biome_id:
			return
		biome_id = v
		var path := "res://assets/sprites/parede_%s.png" % v
		_stone = load(path) if v != "" and ResourceLoader.exists(path) else null
		_hanging = Room.prop_names(v, "banner") + Room.prop_names(v, "chain")

var _stone: Texture2D
var _hanging: Array = []


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if style == "" or style == "columns":
		return
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var textured := _stone != null and Graficos.on("primeiro_plano")
	var scroll := cam.get_screen_center_position().x * SPEED
	var first := floori(scroll / SPACING) - 1
	for i in range(first, first + int(size.x / SPACING) + 3):
		var x := floorf(i * SPACING - scroll)
		var seed := absi(i * 7919)
		match seed % 3:
			0:
				if textured:
					_stone_overhang(x, seed)
				else:
					_overhang(x, seed)
			1:
				if textured and not _hanging.is_empty():
					_hangers(x, seed)
				else:
					_drapes(x, seed)
			_:
				if textured:
					_stone_rubble(x, size.y, seed)
				else:
					_rubble(x, size.y, seed)


func _tint() -> Color:
	return Color(DARK, DARK, DARK * 1.12).lerp(ink, 0.25)


# Um bloco do atlas da parede: a linha é a máscara dos lados abertos (1 em cima,
# 2 à direita, 4 embaixo, 8 à esquerda), onde a beira vem quebrada.
func _block(x: float, y: float, mask: int, seed: int) -> void:
	draw_texture_rect_region(_stone, Rect2(x, y, TILE, TILE), Rect2((seed & 3) * TILE, mask * TILE, TILE, TILE), _tint())


# Pedra pendurada do alto: colunas de blocos, mais compridas no meio.
func _stone_overhang(x: float, seed: int) -> void:
	var cols := 6 + seed % 3
	var hang: Array[int] = []
	for c in cols:
		var t := (c + 0.5) / cols
		hang.append(1 + int(sin(t * PI) * 1.7 + float((seed >> (c % 6)) & 1) * 0.6))
	for c in cols:
		for r in hang[c]:
			var mask := (4 if r == hang[c] - 1 else 0) \
				| (8 if c == 0 or hang[c - 1] <= r else 0) \
				| (2 if c == cols - 1 or hang[c + 1] <= r else 0)
			_block(x + c * TILE, -6.0 + r * TILE, mask, seed + c * 3 + r)


# Entulho no canto de baixo: montes de um ou dois blocos.
func _stone_rubble(x: float, bottom: float, seed: int) -> void:
	var cols := 5 + seed % 3
	var tall: Array[int] = []
	for c in cols:
		tall.append(1 + ((seed >> (c % 5)) & 1))
	for c in cols:
		for r in tall[c]:
			var mask := (1 if r == tall[c] - 1 else 0) \
				| (8 if c == 0 or tall[c - 1] <= r else 0) \
				| (2 if c == cols - 1 or tall[c + 1] <= r else 0)
			_block(x + c * TILE, bottom + 5.0 - (r + 1) * TILE, mask, seed + c * 5 + r)


# O que o domínio pendura do teto (estalactite, raiz, presa, lanterna), em fila.
func _hangers(x: float, seed: int) -> void:
	var tex := Room.props_texture()
	if tex == null:
		return
	for k in 3:
		var art := Room.prop_item(String(_hanging[(seed + k) % _hanging.size()]))
		if art.is_empty():
			continue
		var size := Vector2(float(art["w"]), float(art["h"]))
		var at := Vector2(x + k * 34.0 + float((seed >> k) % 9), -2.0 - float((seed >> (k + 2)) % 5))
		draw_texture_rect_region(tex, Rect2(at, size), Rect2(Vector2(float(art["x"]), float(art["y"])), size), _tint())


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
