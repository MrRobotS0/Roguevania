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
