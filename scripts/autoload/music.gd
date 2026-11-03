extends Node

# Trilha sonora: assets/music/<faixa>.wav (geradas por tools/gen_music.py),
# tocando em loop no barramento "Music". Trocar de faixa é um cruzamento
# suave entre dois tocadores.

const FADE := 1.2

var current := ""
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _player()
	_b = _player()


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = -80.0
	add_child(p)
	return p


func _stream(track: String) -> AudioStream:
	if not _cache.has(track):
		var path := "res://assets/music/%s.wav" % track
		var s: AudioStreamWAV = load(path) if ResourceLoader.exists(path) else null
		if s:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		_cache[track] = s
	return _cache[track]


func play(track: String) -> void:
	if track == current:
		return
	current = track
	if DisplayServer.get_name() == "headless":
		return
	var stream := _stream(track)
	var old := _a
	var fresh := _b
	_a = fresh
	_b = old
	if stream:
		fresh.stream = stream
		fresh.volume_db = -40.0
		fresh.play()
		create_tween().tween_property(fresh, "volume_db", 0.0, FADE)
	if old.playing:
		var t := create_tween()
		t.tween_property(old, "volume_db", -60.0, FADE)
		t.tween_callback(old.stop)


func stop() -> void:
	play("")
