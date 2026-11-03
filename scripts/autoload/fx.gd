extends Node

# "Suco" do combate: congelamento no impacto, tremor de tela e partículas.
# Os atores só pedem o efeito; quem desenha é o nó Sparks da fase atual.

var shake := 0.0
var debug := false
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
	shake = maxf(shake, amount)


func burst(pos: Vector2, color: Color, count: int, speed: float, life := 0.35, gravity := 500.0, size := 2.0, lift := 0.0) -> void:
	if is_instance_valid(sparks):
		sparks.burst(pos, color, count, speed, life, gravity, size, lift)


func dust(pos: Vector2, count := 5) -> void:
	burst(pos, Palette.DUST, count, 55.0, 0.3, 120.0, 2.0, 25.0)


func number(pos: Vector2, value: int, crit := false) -> void:
	if is_instance_valid(sparks):
		sparks.number(pos, value, crit)
