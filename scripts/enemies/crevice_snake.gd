class_name CreviceSnake
extends Assassin

# Cavernas Fundas: mora na fenda do chão e sobe num bote.


func _init() -> void:
	super._init()
	title = "SERPENTE DA FENDA"
	sheet = "crevice_snake"
	max_hp = 40
	hp = 40
	w = 12
	h = 22


# Antes de voltar para a fenda, cospe veneno em arco.
func think(delta: float) -> void:
	var before := state
	super.think(delta)
	if before == "recover" and state == "exposed":
		for i in 2:
			var p := lob("orb", center() + Vector2(0, -8), player.center() + Vector2((i * 2 - 1) * 16.0, 0), 0.7, 10.0, Color("8ac84a"))
			p.damage.status = {"burn": 1.5}
		Sfx.play("thorn_shoot", -8.0)
