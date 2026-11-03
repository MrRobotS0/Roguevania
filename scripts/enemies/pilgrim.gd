class_name Pilgrim
extends Enemy

# Peregrino Cinzento: anda até você e se incendeia. Bater nele durante o
# aviso apaga o pavio (ele recomeça); matar no aviso faz explodir mesmo assim.

const SPEED := 40.0
const FUSE := 0.9
const RADIUS := 40.0
const DAMAGE := 22.0

const ROBE := Color("8b8577")
const ROBE_DARK := Color("5d584e")

var _exploded := false


func _init() -> void:
	title = "PEREGRINO CINZENTO"
	max_hp = 26
	hp = 26
	w = 10
	h = 20
	essence_drop = Vector2i(1, 2)


func body_color() -> Color:
	return ROBE


func telegraphing() -> bool:
	return state == "ignite"


func think(delta: float) -> void:
	var d := to_player()
	match state:
		"idle":
			if blocked(facing) or state_time > 2.5:
				facing = -facing
				state_time = 0.0
			velocity.x = facing * SPEED * 0.4
			if sees_player(190.0, 50.0):
				set_state("chase")
		"chase":
			face_player()
			if absf(d.x) < 30.0 and absf(d.y) < 30.0:
				velocity.x = 0.0
				set_state("ignite")
				Sfx.play("fuse", -6.0)
			else:
				velocity.x = 0.0 if blocked(facing) else facing * SPEED
		"ignite":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if state_time >= FUSE:
				_explode(1.0)


func _die() -> void:
	if state == "ignite" and not _exploded:
		_explode(0.7)
		return
	super._die()


func _explode(scale: float) -> void:
	_exploded = true
	var r := RADIUS * scale
	if player.alive() and player.center().distance_to(center()) <= r + 6.0:
		var dmg := Damage.make(DAMAGE * scale, 1 if player.global_position.x >= global_position.x else -1, 220.0)
		dmg.source = self
		dmg.status = {"burn": 3.0}
		dmg.unblockable = true
		player.hurt(dmg)
	Fx.burst(center(), Palette.BURN, 26, 190.0, 0.5, 200.0, 3.0, 40.0)
	Fx.burst(center(), ROBE, 12, 120.0, 0.6, 300.0, 2.0)
	Fx.add_shake(4.0)
	Sfx.play("boom")
	hp = 0
	super._die()


var _fire: PointLight2D


func draw_body() -> void:
	if _fire == null:
		_fire = Glow.attach(self, Palette.BURN, 70.0, 0.0, Vector2(0, -12))
	_fire.energy = 1.4 * clampf(state_time / FUSE, 0.0, 1.0) if state == "ignite" else 0.15
	var sway := sin(_anim * 5.0) * 1.0
	px(-5 + sway, -16, 10, 16, ROBE)
	px(-5 + sway, -4, 10, 4, ROBE_DARK)
	px(-3 + sway, -20, 7, 5, ROBE_DARK)
	px(1 + sway, -18, 2, 1, Palette.BURN.darkened(0.3))
	px(5 + sway, -14, 1, 14, Palette.WOOD)
	if state == "ignite":
		var k := state_time / FUSE
		var ember := Palette.BURN.lerp(Palette.FLASH, k)
		var size := 3.0 + k * 6.0
		px(-size * 0.5 + sway, -12 - size * 0.5, size, size, ember)
