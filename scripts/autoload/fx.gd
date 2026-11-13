extends Node

# "Suco" do combate: congelamento no impacto, tremor de tela e partículas.
# Os atores só pedem o efeito; quem desenha é o nó Sparks da fase atual.

signal toasted(text: String)
signal bannered(title: String, subtitle: String)

var shake := 0.0
var debug := false
var visibility := 1.0      # a tempestade encurta a visão dos inimigos
var sparks: Node2D

var _stop_token := 0
var aberration := 0.0      # pixels de aberração cromática (PostFx; some sozinha)
var light_root: Node2D     # a fase: onde nascem as luzes de impacto
signal wave_requested(world_pos: Vector2, strength: float)
var pain := 0.0            # 0..1: borda vermelha da tela quando o herói apanha (Vignette)


# Golpes seguidos (arma rápida, vários inimigos) não viram câmera lenta: um
# congelamento que começa logo depois de outro dura metade.
const STOP_CHAIN := 0.12
var _stop_chain_until := 0.0

func hitstop(seconds: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _stop_chain_until and seconds < 0.15:    # o golpe final do chefe pesa sempre
		seconds *= 0.5
	_stop_chain_until = now + seconds + STOP_CHAIN
	_stop_token += 1
	var token := _stop_token
	Engine.time_scale = 0.02
	await get_tree().create_timer(seconds, true, false, true).timeout
	if token == _stop_token:
		Engine.time_scale = 1.0


func add_shake(amount: float) -> void:
	shake = maxf(shake, amount * Options.shake_scale())
	if amount >= 4.0:
		Options.rumble(0.3, 0.5 * minf(amount / 8.0, 1.0), 0.15)


func burst(pos: Vector2, color: Color, count: int, speed: float, life := 0.35, gravity := 500.0, size := 2.0, lift := 0.0) -> void:
	if is_instance_valid(sparks):
		sparks.burst(pos, color, count, speed, life, gravity, size, lift)


func dust(pos: Vector2, count := 5) -> void:
	burst(pos, Palette.DUST, count, 55.0, 0.3, 120.0, 2.0, 25.0)


func ash(parts: Array, push := Vector2.ZERO) -> void:
	if is_instance_valid(sparks):
		sparks.ash(parts, push)


func spray(pos: Vector2, dir: float, color: Color, count := 8, speed := 200.0) -> void:
	if is_instance_valid(sparks):
		sparks.spray(pos, dir, color, count, speed)


func streak(pos: Vector2, dir: float, color: Color) -> void:
	if is_instance_valid(sparks):
		sparks.streak(pos, dir, color)


func impact(pos: Vector2, color: Color, big := false) -> void:
	if is_instance_valid(sparks):
		sparks.impact(pos, color, big)
	flash_light(pos, color, 70.0 if big else 44.0, 1.4 if big else 0.9)
	if big:
		kick(2.0)


# Clarão: uma luz de verdade que acende o cenário em volta do golpe e apaga
# rápido (paredes, chão e inimigos perto ficam iluminados por um instante).
const FLASH_LIGHTS := 8
var _flashes: Array = []

func flash_light(pos: Vector2, color: Color, radius: float, energy: float, life := 0.16) -> void:
	if not is_instance_valid(light_root) or not light_root.is_inside_tree() or not Options.get_value("postfx"):
		return
	_flashes = _flashes.filter(func(l: Variant) -> bool: return is_instance_valid(l))
	if _flashes.size() >= FLASH_LIGHTS:
		return
	var light := PointLight2D.new()
	light.texture = Glow.texture()
	light.texture_scale = radius * 2.0 / 128.0
	light.color = color.lerp(Color.WHITE, 0.25)
	light.energy = energy
	light.global_position = pos
	light_root.add_child(light)
	_flashes.append(light)
	var tw := light.create_tween()
	tw.tween_property(light, "energy", 0.0, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(light.queue_free)


# Aberração cromática: as cores se separam um instante nas bordas da tela.
func kick(amount: float) -> void:
	if Options.flashes():
		aberration = maxf(aberration, amount)


# Onda de choque: a tela ondula num anel a partir do ponto (mundo).
func wave(world_pos: Vector2, strength := 1.0) -> void:
	if Options.flashes():
		wave_requested.emit(world_pos, strength)


func number(pos: Vector2, value: int, crit := false, tint := Color(0, 0, 0, 0)) -> void:
	if is_instance_valid(sparks) and Options.get_value("numbers"):
		sparks.number(pos, value, crit, tint)


# Herói ferido: borda vermelha proporcional ao golpe (some sozinha).
func hurt_flash(strength: float) -> void:
	if Options.flashes():
		pain = maxf(pain, clampf(strength, 0.25, 1.0))


func toast(text: String) -> void:
	toasted.emit(text)


func banner(title: String, subtitle := "") -> void:
	bannered.emit(title, subtitle)
