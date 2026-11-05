class_name Station
extends Interactable

# Um lugar da Beira: o herói chega perto, usa, e o menu abre (main.gd cuida
# dos menus). O texto embaixo do nome mostra o que está escolhido agora.

const GLOWS := {
	"mantos": Color("e0705a"),
	"poco": Color("b8f06a"),
	"carroca": Color("f2c14e"),
	"marcas": Color("d9a93f"),
	"braseiro": Color(1.0, 0.62, 0.3),
}
const TITLES := {
	"mantos": "OS MANTOS",
	"poco": "O POÇO",
	"carroca": "A CARROÇA",
	"marcas": "AS MARCAS",
	"braseiro": "O BRASEIRO",
}
const REACH := {"mantos": 14.0, "poco": 24.0, "carroca": 36.0, "marcas": 30.0, "braseiro": 6.0}

var kind := "mantos"
var _light: PointLight2D


func _ready() -> void:
	super._ready()
	# os desenhos são largos: o herói passa na frente deles
	z_index = 0
	reach = REACH.get(kind, 0.0)
	_light = Glow.attach(self, GLOWS.get(kind, Palette.GOLD), 72.0, 0.6, Vector2(0, -24))
	if kind == "braseiro":
		prop("brazier")
	else:
		var s := SpriteSheet.region_sprite("beira", PackedColorArray(), anim_of(kind))
		s.show_behind_parent = true
		add_child(s)


static func anim_of(k: String) -> String:
	return k


func prompt() -> String:
	return TITLES.get(kind, "")


func detail() -> String:
	match kind:
		"mantos":
			return "EM USO: " + Meta.current_skin().title.to_upper()
		"poco":
			if Run.start_mutation == "":
				return "NENHUMA MUTAÇÃO ESCOLHIDA"
			return "VOCÊ COMEÇA COM: " + String(Catalog.mutation(Run.start_mutation).get("title", "")).to_upper()
		"carroca":
			if Run.advantage == "":
				return "NENHUMA VANTAGEM ESCOLHIDA"
			return "VOCÊ LEVA: " + String(Catalog.advantage(Run.advantage).get("title", "")).to_upper()
		"marcas":
			return "%d DE %d CONQUISTAS" % [Meta.feats_done(), Catalog.FEATS.size()]
		"braseiro":
			return "CICLO %d" % Run.plus if Run.plus > 0 else ("SEM BRASA" if Run.heat == 0 else "%d DE 4 BRASAS" % Run.heat)
	return ""


func interact(_p: Player) -> void:
	Sfx.play("ui_ok", -6.0)
	level.station_used.emit(kind)


func _process(delta: float) -> void:
	super._process(delta)
	var base := 0.55
	if kind == "braseiro":
		base = 0.6 + 0.12 * (Run.heat + Run.plus)
	_light.energy = base + 0.08 * sin(_t * 3.0)


func _draw() -> void:
	match kind:
		"poco":
			# o que sobe do fundo: verde, devagar
			for i in 4:
				var k := fposmod(_t * 0.5 + i * 0.25, 1.0)
				var c := Color("b8f06a")
				c.a = 1.0 - k
				draw_rect(Rect2(-9 + i * 6, -22 - k * 20, 1, 2), c)
		"braseiro":
			# a chama cresce com a dificuldade escolhida
			var size := 1.0 + 0.3 * (Run.heat + Run.plus)
			for i in 4:
				var k := fposmod(_t * 2.2 + i * 0.27, 1.0)
				var x := -3.0 + i * 2.0 + sin(_t * 7.0 + i)
				var tall := (3.0 + (1.0 - k) * 6.0 + (i % 2) * 2.0) * size
				draw_rect(Rect2(x, -14 - tall, 2, tall), Palette.BURN)
				draw_rect(Rect2(x, -14 - tall * 0.5, 2, tall * 0.5), Palette.DANGER)
