class_name Parasite
extends Wolf

# O Ventre: aranha que mora dentro da carne. Abaixa e salta.


func _init() -> void:
	super._init()
	title = "PARASITA"
	sheet = "parasite"
	max_hp = 32
	hp = 32
	w = 22
	h = 14


static var _told := false

var _tick := 0.0


func telegraphing() -> bool:
	return state == "crouch"


# Se o bote pega, ela gruda e vai sugando até você rolar (ou bater nela).
func think(delta: float) -> void:
	if state == "latched":
		global_position = player.global_position + Vector2(-player.facing * 4.0, -6.0)
		velocity = Vector2.ZERO
		facing = player.facing
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.6
			var d := Damage.make(3.0)
			d.source = self
			d.over_time = true
			player.hurt(d)
			Fx.burst(player.center(), Color("c84a5a"), 3, 60.0, 0.3)
		if player.is_dodging() or not player.alive() or state_time > 2.6:
			velocity = Vector2(player.facing * -110.0, -170.0)
			set_state("rest")
		return
	super.think(delta)
	if state == "lunge" and _hit:
		set_state("latched")
		_tick = 0.6
		if not _told:
			_told = true
			Fx.toast("ROLE PARA SOLTAR")


func sprite_anim() -> Array:
	if state == "latched":
		return ["crouch", 0]
	return super.sprite_anim()
