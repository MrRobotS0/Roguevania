class_name AshThief
extends Enemy

# Evento de andar: o Ladrão de Cinzas. Aparece às vezes num andar (level.gd),
# carregando ouro e Essência. Não ataca: quando vê o herói, foge. Alcançado,
# solta o saque; se demorar, some com ele.

const SPEED := 118.0          # um pouco mais lento que o herói correndo: dá para alcançar
const ESCAPE_TIME := 13.0     # quanto tempo foge antes de sumir
const NOTICE := 230.0

var _alerted := false
var _escape := 0.0
var _turn := 0.0


func _init() -> void:
	title = "LADRÃO DE CINZAS"
	sheet = "pilgrim"
	look = ""
	max_hp = 30
	hp = 30
	w = 10
	h = 20
	poise = 0.0
	essence_drop = Vector2i(8, 12)


func _ready() -> void:
	super._ready()
	Glow.attach(self, Palette.GOLD, 44.0, 0.7, Vector2(0, -h * 0.5))


func body_color() -> Color:
	return Palette.GOLD


func think(delta: float) -> void:
	if not _alerted:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if sees_player(NOTICE, 120.0):
			_alerted = true
			set_state("flee")
			Fx.toast("UM LADRÃO DE CINZAS! ALCANCE-O")
			Sfx.play("coin", -4.0)
		return
	_escape += delta
	if _escape >= ESCAPE_TIME:
		_vanish()
		return
	# foge para o lado oposto ao herói; encurralado, vira e passa por baixo dele
	_turn -= delta
	var away := -1 if to_player().x > 0.0 else 1
	if _turn > 0.0:
		away = facing
	elif blocked(away):
		away = -away
		_turn = 0.8
	facing = away
	velocity.x = away * SPEED
	# deixa um rastro de moedas caindo do saco
	if int(state_time * 6.0) != int((state_time - delta) * 6.0):
		Fx.burst(center(), Palette.GOLD, 1, 30.0, 0.5, 300.0, 1.0)


func _vanish() -> void:
	Fx.burst(center(), Palette.GOLD, 16, 140.0, 0.5, -80.0)
	Fx.toast("O LADRÃO SUMIU COM O SAQUE")
	Sfx.play("teleport", -6.0)
	remove_from_group("enemies")
	queue_free()


func sprite_anim() -> Array:
	return ["walk", int(_anim * (8.0 if absf(velocity.x) > 5.0 else 2.0))]
