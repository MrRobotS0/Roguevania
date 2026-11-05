class_name EnemyBar
extends Node2D

# Vida, aviso e texto de um inimigo: nó próprio, sempre por cima do desenho de
# todo mundo, e acima da parte mais alta do sprite (não da caixa de colisão).

const GAP := 5.0

static var _heights := {}

var enemy: Enemy


func _ready() -> void:
	z_index = 40


func _process(_delta: float) -> void:
	queue_redraw()


# Altura do desenho parado acima dos pés. Os quadros têm folga transparente,
# então mede os pixels de verdade (uma vez por folha).
static func sprite_height(tex: Texture2D, sheet: String, frame: Vector2i, draw_scale: float) -> float:
	if not _heights.has(sheet):
		_heights[sheet] = _measure(tex, sheet, frame)
	return float(_heights[sheet]) * draw_scale


static func _measure(tex: Texture2D, sheet: String, frame: Vector2i) -> int:
	var image := tex.get_image()
	if image == null:
		return frame.y
	var anims: Dictionary = SpriteSheet.meta(sheet).get("anims", {})
	var names: Array = ["idle", "walk", "fly", "run"].filter(func(n: String) -> bool: return anims.has(n))
	if names.is_empty():
		names = anims.keys().slice(0, 1)
	var tallest := 0
	for n: String in names:
		var a: Dictionary = anims[n]
		for i in int(a["frames"]):
			var cut := image.get_region(Rect2i(i * frame.x, int(a["row"]) * frame.y, frame.x, frame.y))
			var used := cut.get_used_rect()
			if used.size.y > 0:
				tallest = maxi(tallest, frame.y - 2 - used.position.y)
	return tallest if tallest > 0 else frame.y


func _draw() -> void:
	if not is_instance_valid(enemy) or not enemy.alive():
		return
	var y := -maxf(float(enemy.h), enemy.sprite_top()) - GAP
	if enemy.sink_px > 0.0:
		y = minf(-8.0, y + enemy.sink_px)
	if enemy.hp_bar_visible():
		var bw := clampf(float(enemy.w) * 1.1, 18.0, 44.0)
		if enemy.elite:
			bw = maxf(bw, 30.0)
		var x := -roundf(bw * 0.5)
		draw_rect(Rect2(x - 1, y - 1, bw + 2, 5), Palette.UI_SHADOW)
		draw_rect(Rect2(x, y, bw * enemy.shown_hp() / enemy.max_hp, 3), Palette.UI_HP_GHOST)
		draw_rect(Rect2(x, y, bw * float(enemy.hp) / enemy.max_hp, 3), Palette.UI_HP)
		y -= 2.0
	var text := enemy.overhead_text()
	if text != "":
		PixelFont.draw_centered(self, text, Vector2(0, y - 8), Palette.DANGER)
		y -= 9.0
	if enemy.telegraphing() and int(enemy.state_time * 12.0) % 2 == 0:
		PixelFont.draw_centered(self, "!", Vector2(0, y - 15), Palette.DANGER, 2)
