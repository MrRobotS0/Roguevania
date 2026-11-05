class_name Highwayman
extends Dancer

# Bosque Errante: o salteador da estrada. Gira a espada (aviso) e cruza o
# caminho num corte só. Depois fica tonto: é a hora.


func _init() -> void:
	super._init()
	title = "SALTEADOR"
	sheet = "highwayman"
	max_hp = 58
	hp = 58
	w = 12
	h = 30


var _loot := 0


# O corte leva ouro, e ele foge com o saque. Só voltando a alcançar para tomar de volta.
func think(delta: float) -> void:
	if state == "flee":
		var away := -1 if to_player().x > 0.0 else 1
		facing = away
		velocity.x = 0.0 if blocked(away) else away * 135.0
		if state_time >= 4.0:
			set_state("chase")
		return
	super.think(delta)
	if state == "dash" and _hit and _loot == 0 and player.gold > 0:
		_loot = mini(player.gold, maxi(10, player.gold / 4))
		player.gold -= _loot
		Fx.toast("O SALTEADOR LEVOU SEU OURO")
		Sfx.play("coin", -4.0)
		set_state("flee")


func overhead_text() -> String:
	return "$" if _loot > 0 else ""


func sprite_anim() -> Array:
	if state == "flee":
		return ["walk", int(_anim * 12.0)]
	return super.sprite_anim()


func _die() -> void:
	if _loot > 0 and player:
		player.add_gold(_loot)
		Fx.toast("OURO RECUPERADO")
	super._die()
