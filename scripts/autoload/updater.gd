extends Node

# Atualização sozinha. O jogo é distribuído como Moksha.exe (o motor) +
# Moksha.pck (todo o conteúdo). Ao abrir, consulta o último Release no
# GitHub; se for mais novo, baixa só o .pck para user://. Da próxima vez que
# o jogo abrir (ou na hora, se o jogador mandar), ele se reabre usando o
# pacote novo (--main-pack). Só roda no jogo exportado: editor e testes
# nunca tocam na rede.
#
# É o primeiro autoload: se já existe um pacote mais novo baixado, reabre
# antes de o resto do jogo começar.

signal ready_to_apply(version: String)

const LATEST := "https://api.github.com/repos/MrRobotS0/Roguevania/releases/latest"
const PACK_ASSET := "Moksha.pck"
const STATE := "user://update.json"

var version := ""            # versão deste pacote
var pending := ""            # versão nova já baixada, esperando reiniciar
var _http: HTTPRequest


func _ready() -> void:
	version = String(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	# na web quem atualiza é o servidor: trocou os arquivos, a próxima visita já vem nova
	if not OS.has_feature("template") or OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	var saved := _saved()
	if not saved.is_empty() and newer(String(saved["version"]), version) and FileAccess.file_exists(String(saved["path"])):
		restart_into(String(saved["path"]))
		return
	_check.call_deferred()


static func newer(a: String, b: String) -> bool:
	var x := a.trim_prefix("v").split(".")
	var y := b.trim_prefix("v").split(".")
	for i in maxi(x.size(), y.size()):
		var p := int(x[i]) if i < x.size() else 0
		var q := int(y[i]) if i < y.size() else 0
		if p != q:
			return p > q
	return false


func _saved() -> Dictionary:
	if not FileAccess.file_exists(STATE):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(STATE))
	return d if d is Dictionary else {}


func _check() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_http.request_completed.connect(_on_release)
	_http.request(LATEST, ["User-Agent: Moksha-game", "Accept: application/vnd.github+json"])


func _on_release(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http.request_completed.disconnect(_on_release)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		return
	var tag := String(data.get("tag_name", "")).trim_prefix("v")
	if not newer(tag, version):
		return
	for asset in data.get("assets", []):
		if String(asset.get("name", "")) == PACK_ASSET:
			_download(tag, String(asset["browser_download_url"]))
			return


func _download(tag: String, url: String) -> void:
	var path := "user://moksha-%s.pck" % tag
	_http.download_file = path + ".part"
	_http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".part"))
			return
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".part"), ProjectSettings.globalize_path(path))
		var f := FileAccess.open(STATE, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify({"version": tag, "path": ProjectSettings.globalize_path(path)}))
		pending = tag
		ready_to_apply.emit(tag), CONNECT_ONE_SHOT)
	_http.request(url, ["User-Agent: Moksha-game"])


# Reabre o jogo com o pacote novo e fecha este.
func restart_into(pack := "") -> void:
	if pack == "":
		pack = String(_saved().get("path", ""))
	if pack == "" or not FileAccess.file_exists(pack):
		return
	OS.create_process(OS.get_executable_path(), ["--main-pack", pack])
	get_tree().quit()
