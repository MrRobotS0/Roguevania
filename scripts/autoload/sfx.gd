extends Node

# Efeitos sonoros: assets/sfx/<nome>.wav (gerados por tools/gen_sfx.py).
# Toca com uma leve variação de tom para não cansar o ouvido.

const VOICES := 12

var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)


func play(name: String, volume_db := 0.0, pitch_jitter := 0.08) -> void:
	if muted or DisplayServer.get_name() == "headless":
		return
	if not _cache.has(name):
		var path := "res://assets/sfx/%s.wav" % name
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	var stream: AudioStream = _cache[name]
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
