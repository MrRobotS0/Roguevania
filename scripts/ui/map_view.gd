class_name MapView
extends Control

# Mapa do andar (segura M / Tab, ou Select no controle): só o que o herói já
# viu. Pontos: você (pisca), saídas, Vigia, baús, altares, mercador.

var level: Level
var _t := 0.0


func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	_t += delta
	visible = Input.is_action_pressed("map") and is_instance_valid(level) and level.room != null
	if visible:
		queue_redraw()


func _draw() -> void:
	if not is_instance_valid(level) or level.room == null:
		return
	var room := level.room
	var size := get_viewport_rect().size
	var area := Vector2(size.x - 40, size.y - 60)
	var scale := maxi(1, int(floor(minf(area.x / room.cols, area.y / room.rows))))
	var full := Vector2(room.cols, room.rows) * scale
	var origin := ((size - full) * 0.5).floor()
	var me := level.player.center() / Room.TILE if is_instance_valid(level.player) else Vector2.ZERO
	if full.x > area.x or full.y > area.y:
		origin = (size * 0.5 - me * scale).floor()
	var veil := Palette.UI_SHADOW
	veil.a = 0.82
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	var rock := Color("4a3f60")
	var air := Color("1b1726")
	var edge := Color("8a7fa0")
	for y in room.rows:
		for x in room.cols:
			if not level.seen(x, y):
				continue
			var solid := room._solidish(x, y)
			if solid:
				var open := not room._solidish(x + 1, y) or not room._solidish(x - 1, y) \
					or not room._solidish(x, y + 1) or not room._solidish(x, y - 1)
				if open:
					draw_rect(Rect2(origin + Vector2(x, y) * scale, Vector2(scale, scale)), edge)
			else:
				draw_rect(Rect2(origin + Vector2(x, y) * scale, Vector2(scale, scale)), air if room.cell(x, y) != Room.PLATFORM else rock)
	for n in level.get_children():
		var c := Color(0, 0, 0, 0)
		if n is ExitGate and n.visible:
			c = Palette.ESSENCE
		elif n is Keeper and n.visible:
			c = Palette.GLASS
		elif n is Chest and not n.opened:
			c = Palette.GOLD
		elif n is Merchant:
			c = Palette.GOLD.lightened(0.3)
		elif n is Altar or n is MutationAltar or n is RuneAltar:
			c = Color("b8f06a")
		if c.a > 0.0:
			var cell := (n as Node2D).global_position / Room.TILE
			if level.seen(int(cell.x), int(cell.y) - 1):
				draw_rect(Rect2(origin + cell * scale - Vector2(2, 3), Vector2(4, 4)), c)
	if int(_t * 4.0) % 2 == 0:
		draw_rect(Rect2(origin + me * scale - Vector2(2, 2), Vector2(4, 4)), Palette.HURT)
	var title: String = Catalog.STAGE_NAMES.get(Run.stage_id, "") if level.kind != "passagem" else "A Passagem"
	PixelFont.body_centered(self, String(title).to_upper(), Vector2(size.x * 0.5, 14), Palette.GOLD)
	PixelFont.draw_centered(self, "VOCÊ   SAÍDA   VIGIA   BAÚ   ALTAR", Vector2(size.x * 0.5, size.y - 12), Palette.UI_DIM)
