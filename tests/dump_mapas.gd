extends Node

# Grava mapas montados pelo gerador, para tools/validar_mapas.py conferir com o
# alcance do herói: python tools/validar_mapas.py

func _ready() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var seeds := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = int(a.substr(8))
	var f := FileAccess.open(out, FileAccess.WRITE)
	for id: String in Catalog.BIOMES.keys():
		var path := "res://content/biomes/%s/biome.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var b: BiomeData = load(path)
		var pool := LevelGen.load_dir(b.rooms_dir)
		if pool.is_empty():
			continue
		for s in seeds:
			var branches: Array = [["cofre", "K"], "loja", "fragmento", "tesouro", "tesouro"]
			if b.rune != "":
				branches.insert(0, "runa")
			var gen := LevelGen.new()
			var lines := gen.generate(pool, 1000 + s * 131, b.combat_rooms, branches)
			if lines.is_empty():
				continue
			f.store_line("@%s %d" % [id, s])
			for l in lines:
				f.store_line(l)
			# de onde veio cada pedaço, para achar a sala culpada
			var box := Rect2i(gen.placed[0].rect())
			for p in gen.placed:
				box = box.merge(p.rect())
			box = box.grow(LevelGen.MARGIN)
			for p in gen.placed:
				f.store_line("!%s %d %d %d %d" % [p.t.name, p.pos.x - box.position.x, p.pos.y - box.position.y, p.t.width, p.t.height])
	f.close()
	get_tree().quit()
