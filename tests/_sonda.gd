extends Node

func _ready() -> void:
	Meta.use_path("user://sonda.save", true)
	var t0 := Time.get_ticks_msec()
	for bid in ["mar_de_cinzas", "saloes", "torre_babel", "observatorio"]:
		for s in [11, 22]:
			var b := Catalog.biome(bid)
			var gen := LevelGen.new()
			var lines := gen.generate(LevelGen.load_dir(b.rooms_dir), s * 7349, b.combat_rooms, [["cofre", "K"], "loja", "fragmento", "tesouro", "tesouro"])
			var dirs := {}
			for i in range(1, gen.main_path.size()):
				var p: LevelGen.Placed = gen.main_path[i]
				var side: String = p.t.doors[p.entry]["side"]
				dirs[side] = int(dirs.get(side, 0)) + 1
			print("%s %d: %d salas, caminho %d, entradas %s, portais %d" % [bid, s, gen.placed.size(), gen.main_path.size(), dirs, gen.portals.size()])
			var f := FileAccess.open("user://fase_%s_%d.txt" % [bid, s], FileAccess.WRITE)
			f.store_string("\n".join(lines))
	print("ms ", Time.get_ticks_msec() - t0)
	get_tree().quit()
