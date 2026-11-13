extends Node

# Opções do jogador (som, tela, conforto, teclas). Ficam no save do Meta,
# em "options", e são aplicadas na hora em que mudam.

const DEFAULTS := {
	"master": 0.8, "music": 0.7, "sfx": 0.8,
	"fullscreen": false,
	"shake": 1.0,            # 0 .. 1: quanto a tela treme
	"flashes": true,         # false = sem piscar branco forte
	"vibration": true,
	"timer": false,          # cronômetro de speedrun na tela
	"hints": true,           # dicas da primeira partida
	"numbers": true,         # números de dano subindo dos inimigos
	"minimap": true,         # minimapa no canto (andares gerados)
	"colorblind": false,     # avisos dos inimigos em azul e branco
	"easy_dodge": false,     # rolagem invencível por mais tempo
	"lang": "pt",            # pt | en (o nome do jogo fica igual)
	"font": "classica",      # PixelFont.FACES: desenho das letras do texto
	"keys": {},              # ação -> [physical keycode]
}

var data := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	reload()


func reload() -> void:
	data = DEFAULTS.duplicate(true)
	var saved: Dictionary = Meta.data.get("options", {})
	for k in saved:
		data[k] = saved[k]
	apply()


func get_value(key: String) -> Variant:
	return data.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	data[key] = value
	Meta.data["options"] = data.duplicate(true)
	Meta.save()
	apply()


func apply() -> void:
	_volume("Master", float(data["master"]))
	_volume("Music", float(data["music"]))
	_volume("SFX", float(data["sfx"]))
	# no navegador quem cuida da tela cheia é a página (web/shell.html)
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if data["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	Controls.apply_bindings(data["keys"])
	Palette.use_colorblind(bool(data.get("colorblind", false)))
	PixelFont.use_face(String(data.get("font", "classica")))


func shake_scale() -> float:
	return float(data["shake"])


func flashes() -> bool:
	return bool(data["flashes"])


# Vibração curta no controle (dano, golpe forte).
func rumble(weak: float, strong: float, seconds: float) -> void:
	if not data["vibration"]:
		return
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, weak, strong, seconds)


func _ensure_buses() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")


func _volume(bus: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(i, linear <= 0.001)
