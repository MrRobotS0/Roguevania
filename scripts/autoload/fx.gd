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


func hitstop(seconds: float) -> void:
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


func ash(parts: Array) -> void:
	if is_instance_valid(sparks):
		sparks.ash(parts)


func streak(pos: Vector2, dir: float, color: Color) -> void:
	if is_instance_valid(sparks):
		sparks.streak(pos, dir, color)


func impact(pos: Vector2, color: Color, big := false) -> void:
	if is_instance_valid(sparks):
		sparks.impact(pos, color, big)


func number(pos: Vector2, value: int, crit := false) -> void:
	if is_instance_valid(sparks) and Options.get_value("numbers"):
		sparks.number(pos, value, crit)


func toast(text: String) -> void:
	toasted.emit(text)


func banner(title: String, subtitle := "") -> void:
	bannered.emit(title, subtitle)
