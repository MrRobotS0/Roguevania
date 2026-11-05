class_name Drowned
extends Grunt

# Catedral Submersa: rezou embaixo d'água até a água responder. Pancada lenta e avisada.


func _init() -> void:
	super._init()
	title = "AFOGADO"
	sheet = "drowned"
	max_hp = 60
	hp = 60
	w = 12
	h = 28


# A pancada no chão faz a água subir um pouco adiante: longe dele também não é seguro.
func think(delta: float) -> void:
	var before := state
	super.think(delta)
	if before == "windup" and state == "attack":
		var x := global_position.x + facing * 56.0
		if not room.is_solid_at(Vector2(x, global_position.y - 8.0)):
			make_hazard("water", x, 0.4, 14.0, 20.0, 48.0)
