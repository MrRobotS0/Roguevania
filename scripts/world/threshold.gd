class_name Threshold
extends Interactable

# O arco no fim da Beira. Passou dele, a partida começa: mapa sorteado e
# relógio correndo. Não pede botão: atravessar já é a decisão.

var crossed := false
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	z_index = 0
	reach = 18.0
	_light = Glow.attach(self, Palette.ESSENCE, 80.0, 0.7, Vector2(0, -30))
	var s := SpriteSheet.region_sprite("beira", PackedColorArray(), "limiar")
	s.show_behind_parent = true
	add_child(s)


func prompt() -> String:
	return "ATRAVESSAR O ARCO"


func detail() -> String:
	return "DAQUI EM DIANTE O MAPA MUDA E O RELÓGIO CORRE"


func interact(_p: Player) -> void:
	cross()


func cross() -> void:
	if crossed:
		return
	crossed = true
	Sfx.play("portal")
	level.exit_used.emit("partida")


func _physics_process(_delta: float) -> void:
	var p: Player = level.player if level else null
	if p != null and p.alive() and p.global_position.x >= global_position.x:
		cross()


func _draw() -> void:
	_light.energy = 0.7 + 0.15 * sin(_t * 2.5)
	var core := Palette.ESSENCE
	core.a = 0.18 + 0.08 * sin(_t * 2.5)
	draw_rect(Rect2(-22, -62, 44, 62), core)
	for i in 6:
		var k := fposmod(_t * 0.5 + i * 0.17, 1.0)
		var mote := Palette.FLASH
		mote.a = (1.0 - k) * 0.8
		draw_rect(Rect2(-18 + i * 7, -k * 58, 1, 2), mote)
