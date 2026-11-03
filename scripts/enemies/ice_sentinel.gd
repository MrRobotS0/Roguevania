class_name IceSentinel
extends Archer

# Sentinela de Gelo: o atirador dos Salões. Solta três lascas em leque; a do
# meio vai onde você estava quando a mira travou.

const SPREAD := 0.22


func _init() -> void:
	super._init()
	title = "SENTINELA DE GELO"
	look = "archer_ice"
	max_hp = 40
	hp = 40


func _shoot() -> void:
	var base := (_target - bow()).angle()
	for k in [-1, 0, 1]:
		var p := Projectile.new()
		p.room = room
		p.team = "enemy"
		p.style = "shard"
		p.source = self
		p.position = bow()
		p.velocity = Vector2.from_angle(base + k * SPREAD) * ARROW_SPEED * 0.9
		p.damage = Damage.make(DAMAGE * 0.8, facing, 100.0)
		p.damage.source = self
		get_parent().add_child(p)
	Sfx.play("bow", -8.0)
