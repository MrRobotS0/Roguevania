class_name Enemy
extends CharacterBody2D

# Base dos inimigos. Regra do gênero: todo ataque é AVISADO antes (o corpo
# muda de cor e aparece um "!"), e acertar um inimigo durante o aviso
# interrompe o golpe dele.

signal killed(enemy: Enemy)

const GRAVITY := 1300.0
const MAX_FALL := 450.0

var room: Room
var player: Player
var max_hp := 40
var hp := 40
var w := 12
var h := 22
var facing := -1
var state := "idle"
var state_time := 0.0

var _flash := 0.0
var _stun := 0.0
var _shown_hp := 0.0
var _hp_visible := 0.0
var _anim := 0.0


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var holder := CollisionShape2D.new()
	holder.shape = shape
	holder.position = Vector2(0, -h * 0.5)
	add_child(holder)
	collision_layer = 4
	collision_mask = Room.WORLD_LAYER | Room.PLATFORM_LAYER
	_shown_hp = hp
	z_index = 4
	add_to_group("enemies")


func alive() -> bool:
	return hp > 0


func center() -> Vector2:
	return global_position + Vector2(0, -h * 0.5)


func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-w * 0.5, -h), Vector2(w, h))


func set_state(next: String) -> void:
	state = next
	state_time = 0.0


func take_hit(damage: int, dir: int, knock: float, crit: bool) -> void:
	if not alive():
		return
	hp -= damage
	_flash = 0.1
	_hp_visible = 2.5
	velocity.x = dir * knock
	if crit:
		velocity.y = -90.0
	Fx.number(center() + Vector2(0, -h * 0.5 - 4), damage, crit)
	Fx.burst(center(), Palette.HIT, 6 if not crit else 12, 120.0 if not crit else 180.0)
	if hp <= 0:
		_die(dir)
		return
	_stun = 0.28 if not crit else 0.45
	set_state("stun")


func _die(dir: int) -> void:
	Fx.burst(center(), body_color(), 18, 170.0, 0.6, 500.0, 3.0, 40.0)
	Fx.burst(center(), Palette.HIT, 10, 220.0, 0.45)
	Fx.add_shake(3.0)
	killed.emit(self)
	remove_from_group("enemies")
	queue_free()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	state_time += delta
	_flash -= delta
	_hp_visible -= delta
	_anim += delta
	_shown_hp = move_toward(_shown_hp, hp, 60.0 * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if state == "stun":
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if state_time >= _stun:
			set_state("chase")
	else:
		think(delta)
	move_and_slide()
	queue_redraw()


func think(_delta: float) -> void:
	pass


func body_color() -> Color:
	return Palette.GRUNT


# --- sentidos ------------------------------------------------------------------

func eye() -> Vector2:
	return global_position + Vector2(facing * 3, -h + 6)


func to_player() -> Vector2:
	return player.global_position - global_position


func sees_player(range_x: float, range_y: float) -> bool:
	if not player.alive():
		return false
	var d := to_player()
	if absf(d.x) > range_x or absf(d.y) > range_y:
		return false
	return room.clear_line(eye(), player.center())


# Parede ou buraco à frente: não anda para lá.
func blocked(dir: int) -> bool:
	var front := global_position.x + dir * (w * 0.5 + 2.0)
	var wall := room.is_solid_at(Vector2(front, global_position.y - 4.0))
	var floor_ahead := room.is_ground_at(Vector2(front, global_position.y + 4.0))
	return wall or not floor_ahead


# --- desenho ---------------------------------------------------------------------

var _tint := Color(0, 0, 0, 0)


func px(x: float, y: float, rw: float, rh: float, c: Color) -> void:
	if facing < 0:
		x = -x - rw
	draw_rect(Rect2(x, y, rw, rh), _tint if _tint.a > 0.0 else c)


func telegraphing() -> bool:
	return false


func _draw() -> void:
	_tint = Palette.FLASH if _flash > 0.0 else Color(0, 0, 0, 0)
	draw_body()
	_tint = Color(0, 0, 0, 0)
	if telegraphing() and int(state_time * 12.0) % 2 == 0:
		PixelFont.draw_centered(self, "!", Vector2(0, -h - 9), Palette.DANGER, 2)
	if _hp_visible > 0.0 and alive():
		var bw := 16.0
		var y := -h - 5.0
		draw_rect(Rect2(-bw * 0.5 - 1, y - 1, bw + 2, 4), Palette.UI_SHADOW)
		draw_rect(Rect2(-bw * 0.5, y, bw * _shown_hp / max_hp, 2), Palette.UI_HP_GHOST)
		draw_rect(Rect2(-bw * 0.5, y, bw * float(hp) / max_hp, 2), Palette.UI_HP)
	if Fx.debug:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 0.8, 0.2, 0.8), false)
		PixelFont.draw(self, state, Vector2(-10, -h - 18), Palette.UI_TEXT)


func draw_body() -> void:
	pass
