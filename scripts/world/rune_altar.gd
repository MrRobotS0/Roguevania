class_name RuneAltar
extends Interactable

# Runas: poderes que ficam para sempre e abrem caminhos em partidas futuras.
#   asa   Asa de Cinza (pulo duplo)        - Salões do Último Inverno
#   punho Punho do Ferreiro (quebra parede rachada) - Forja Rubra

const RUNES := {
	"asa": {"title": "Asa de Cinza", "detail": "PULO DUPLO: APERTE PULAR DE NOVO NO AR"},
	"punho": {"title": "Punho do Ferreiro", "detail": "PAREDES RACHADAS CEDEM AOS SEUS GOLPES"},
}

var rune := "asa"
var _body: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	_body = prop("rune_altar")
	_light = Glow.attach(self, Palette.ESSENCE, 60.0, 0.9, Vector2(0, -20))


func taken() -> bool:
	return Meta.has_rune(rune)


func can_interact(_p: Player) -> bool:
	return visible and not taken()


func prompt() -> String:
	return "TOCAR A RUNA"


func detail() -> String:
	return String(RUNES[rune]["title"]).to_upper() + " · PARA SEMPRE"


func interact(p: Player) -> void:
	Meta.add_rune(rune)
	Sfx.play("fragment")
	Fx.add_shake(4.0)
	Fx.burst(global_position + Vector2(0, -20), Palette.ESSENCE, 30, 160.0, 0.8, -30.0)
	Fx.banner(String(RUNES[rune]["title"]).to_upper(), RUNES[rune]["detail"])
	p.gear_changed.emit()


func _draw() -> void:
	SpriteSheet.set_region(_body, "props", "rune_altar", 1 if taken() else 0)
	_light.energy = 0.0 if taken() else 0.8 + 0.2 * sin(_t * 2.5)
