class_name Screen
extends Control

# Telas cheias: título, morte e vitória. Desenha por cima de tudo e espera
# o jogador confirmar.

signal confirmed

var mode := ""
var lines: Array = []       # [[texto, cor]]
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_title() -> void:
	mode = "title"
	var stats: Dictionary = Meta.data
	lines = []
	if int(stats["runs"]) > 0:
		lines = [["PARTIDAS %d   ·   VITÓRIAS %d   ·   MAIS ABATES %d" % [stats["runs"], stats["wins"], stats["best_kills"]], Palette.UI_DIM]]
	_open()


func show_death(p: Player, place: String) -> void:
	mode = "death"
	lines = [
		["CAÍDO EM " + place.to_upper(), Palette.UI_DIM],
		["%d INIMIGOS DERROTADOS   ·   %s" % [p.kills, _clock(Run.time)], Palette.UI_TEXT],
		["%d DE ESSÊNCIA SE PERDEU NA CINZA" % p.essence, Palette.ESSENCE],
	]
	_open()


func show_victory(p: Player) -> void:
	mode = "victory"
	lines = [
		["O IMPERADOR CEGO CAIU EM " + _clock(Run.time), Palette.UI_TEXT],
		["%d INIMIGOS DERROTADOS" % p.kills, Palette.UI_DIM],
		["A FORJA RUBRA E OS SALÕES DO ÚLTIMO INVERNO AINDA ESTÃO SELADOS.", Palette.GOLD],
		["O QUE ACONTECEU COM OS DEUSES CONTINUA SEM RESPOSTA.", Palette.UI_DIM],
	]
	_open()


func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _open() -> void:
	_t = 0.0
	visible = true


func close() -> void:
	visible = false
	mode = ""


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()
	if _t > 0.6 and (Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("attack1")):
		confirmed.emit()


func _draw() -> void:
	var size := get_viewport_rect().size
	var veil := Palette.UI_SHADOW
	veil.a = 0.92 if mode != "title" else 0.55
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	var mid := size.x * 0.5
	match mode:
		"title":
			PixelFont.draw_centered(self, "O LEGADO", Vector2(mid, 70), Palette.UI_TEXT, 4)
			PixelFont.draw_centered(self, "DOS DEUSES", Vector2(mid, 96), Palette.GOLD, 4)
			PixelFont.draw_centered(self, "OS DEUSES SUMIRAM. SEUS DOMÍNIOS FICARAM.", Vector2(mid, 124), Palette.UI_DIM)
		"death":
			PixelFont.draw_centered(self, "VOCÊ MORREU", Vector2(mid, 80), Palette.HURT, 4)
		"victory":
			PixelFont.draw_centered(self, "FIM DA DEMONSTRAÇÃO", Vector2(mid, 74), Palette.GOLD, 3)
	var y := 140.0 if mode == "title" else 112.0
	for l in lines:
		PixelFont.draw_centered(self, l[0], Vector2(mid, y), l[1])
		y += 12.0
	if _t > 0.6 and int(_t * 2.0) % 2 == 0:
		var call := "J / ENTER  COMEÇAR" if mode == "title" else "J / ENTER  NOVA PARTIDA"
		PixelFont.draw_centered(self, call, Vector2(mid, size.y - 40), Palette.UI_TEXT)
	if mode == "title":
		PixelFont.draw_centered(self, "NOME, ARTE E SONS PROVISÓRIOS", Vector2(mid, size.y - 14), Palette.UI_FRAME.lightened(0.3))
