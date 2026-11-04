class_name GearIcon
extends RefCounted

# Ícone em pixel art de uma arma ou habilidade (assets/icons/<id>.png, 32 px,
# e <id>_16.png para o HUD e o pedestal). Sem ícone, quem chama desenha à mão.

static var _cache := {}


# Ícones soltos (pão, frasco, cálice): assets/icons/<nome>_16.png
static func named(name: String) -> Texture2D:
	var path := "res://assets/icons/%s_16.png" % name
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


static func of(data: Resource, small := true) -> Texture2D:
	var path := String(data.get("icon")) if data and data.get("icon") != null else ""
	if path == "":
		return null
	if small:
		path = path.replace(".png", "_16.png")
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]
