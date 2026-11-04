class_name FallenStar
extends Enemy

# Estrela Caída (Observatório) / alma do Arauto (Carcosa): flutua até você,
# pisca (aviso) e explode. Matar antes também explode, mas longe de você.

const SPEED := 75.0
const FUSE := 0.8


func _init() -> void:
	title = "ESTRELA CAÍDA"
	sheet = "star"
	max_hp = 16
	hp = 16
	w = 10
	h = 12
	uses_gravity = false
	essence_drop = Vector2i(1, 1)


func _ready() -> void:
	super._ready()
	collision_mask = Room.WORLD_LAYER
	Glow.attach(self, Color("c08fff") if look == "wisp" else Palette.GLASS, 30.0, 0.6, Vector2(0, -8))


func telegraphing() -> bool:
	return state == "fuse"


func think(delta: float) -> void:
	match state:
		"idle", "chase":
			var to := player.center() - center()
			velocity = velocity.lerp(to.normalized() * SPEED, 1.0 - exp(-2.0 * delta))
			if to.length() < 26.0:
				set_state("fuse")
		"fuse":
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			if state_time >= FUSE:
				_boom()
		"stun":
			velocity = Vector2.ZERO


func _boom() -> void:
	if player.alive() and player.center().distance_to(center()) < 30.0:
		var d := Damage.make(16, 1 if player.global_position.x >= global_position.x else -1, 180.0)
		d.source = self
		d.unblockable = true
		player.hurt(d)
	Fx.burst(center(), Color("c08fff") if look == "wisp" else Palette.GLASS, 18, 150.0, 0.4, 100.0)
	Sfx.play("star_pop", -4.0)
	hp = 0
	super._die()


func sprite_anim() -> Array:
	if state == "fuse":
		return ["windup", int(state_time * 12.0)]
	return ["idle", int(_anim * 6.0)]
