class_name Sleepwalker
extends Archer

# Penhascos do Sonho: atira dormindo. A mira trava um instante antes da flecha.


func _init() -> void:
	super._init()
	title = "SONÂMBULA"
	sheet = "sleepwalker"
	max_hp = 44
	hp = 44
	w = 12
	h = 28


var _burst := 0
var _burst_t := 0.0
var _in_burst := false


# Não para de andar enquanto mira, e solta três flechas em vez de uma.
func think(delta: float) -> void:
	super.think(delta)
	if state == "aim":
		velocity.x = 0.0 if blocked(facing) else facing * 18.0
	if _burst > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_burst -= 1
			_burst_t = 0.14
			_target = player.center()
			_in_burst = true
			_shoot()
			_in_burst = false


func _shoot() -> void:
	super._shoot()
	if not _in_burst:
		_burst = 2
		_burst_t = 0.14
