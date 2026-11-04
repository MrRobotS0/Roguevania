extends Node

# Idioma do jogo. O texto é escrito em português no código e no conteúdo;
# na hora de desenhar, a PixelFont pede aqui a versão no idioma escolhido.
# A tabela fica em content/lang/en.txt (PORTUGUÊS = ENGLISH). Textos com
# número no meio ("12 INIMIGOS DERROTADOS") casam com a chave que tem %D,
# e no inglês %1, %2... recebem esses pedaços na ordem do português.
# O nome do jogo (MOKSHA) não passa por aqui.

const LANGS := ["pt", "en"]
const NAMES := {"pt": "PORTUGUÊS", "en": "ENGLISH"}
const HOLE := "%[0-9.]*[DSF]"

var lang := "pt"
var _exact := {}
var _templates: Array = []     # [RegEx, inglês, literais] do mais específico ao mais geral
var _english := {}             # o que já é inglês passa direto
var _cache := {}
var _hole := RegEx.create_from_string(HOLE)


func _ready() -> void:
	_load("res://content/lang/en.txt")
	use(String(Options.get_value("lang")))


func use(code: String) -> void:
	lang = code if LANGS.has(code) else "pt"
	_cache.clear()


func _load(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if line.begins_with(";") or not line.contains(" = "):
			continue
		var cut := line.find(" = ")
		var key := line.substr(0, cut)
		var en := line.substr(cut + 3)
		_english[en.to_upper()] = true
		if _hole.search(key) == null:
			_exact[key] = en
			# "ENTRAR: " também vale como "ENTRAR" (texto montado com separador)
			var bare := key.strip_edges().trim_suffix(":")
			if bare != key and not _exact.has(bare):
				_exact[bare] = en.strip_edges().trim_suffix(":")
			continue
		var pattern := "^"
		var at := 0
		var literal := 0
		for m in _hole.search_all(key):
			var piece := key.substr(at, m.get_start() - at)
			pattern += _escape(piece)
			literal += piece.length()
			pattern += "(.+?)" if m.get_string().ends_with("S") else "(-?[0-9][0-9.:]*)"
			at = m.get_end()
		pattern += _escape(key.substr(at)) + "$"
		literal += key.length() - at
		_templates.append([RegEx.create_from_string(pattern), en, literal])
	_templates.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])


static func _escape(s: String) -> String:
	var out := ""
	for ch in s:
		out += ("\\" + ch) if "\\^$.|?*+()[]{}".contains(ch) else ch
	return out


func t(text: String) -> String:
	if lang == "pt" or text.is_empty():
		return text
	if _cache.has(text):
		return _cache[text]
	var out := _translate(text)
	_cache[text] = out
	return out


func _translate(text: String) -> String:
	if text.contains("\n"):
		return "\n".join(PackedStringArray(Array(text.split("\n")).map(func(l: String) -> String: return t(l))))
	var key := text.to_upper()
	if _exact.has(key):
		return _exact[key]
	if _english.has(key):
		return text
	for tpl in _templates:
		var m: RegExMatch = (tpl[0] as RegEx).search(key)
		if m == null:
			continue
		var en: String = tpl[1]
		for i in range(m.get_group_count(), 0, -1):
			var part := m.get_string(i)
			en = en.replace("%" + str(i), part if part.is_valid_float() or part.contains(":") else t(part))
		return en
	# pedaços montados com separador: traduz cada um
	for sep in ["   ·   ", "  ·  ", " · ", ": "]:
		if key.contains(sep):
			var parts := text.split(sep)
			return sep.join(PackedStringArray(Array(parts).map(func(p: String) -> String: return t(p))))
	return text
