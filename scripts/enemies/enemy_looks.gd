class_name EnemyLooks
extends RefCounted

# Paletas das folhas de inimigo (mesma tabela de tools/gen_enemies.py):
# roupa, segunda peça, olho, detalhe, rosto, madeira, metal.

const TABLE := {
	"penitent": ["6b5a3a", "8a7752", "ff5a4a", "7a3b2b", "1a1210", "5b3f2c", "c9c2b0"],
	"guard": ["8a2e2e", "4a2a24", "ff5a4a", "c8964a", "120c0c", "6b4a32", "d9e2ec"],
	"pilgrim": ["8b8577", "6e6a60", "ff9a3c", "ff9a3c", "16120f", "5b3f2c", "c9c2b0"],
	"archer": ["5e4a72", "3d3049", "ff5a4a", "7a5a3a", "120e16", "8a6242", "bfe6ea"],
	"assassin": ["3a3046", "c9b38a", "ff5a4a", "8a6242", "0e0b12", "5b3f2c", "d9e2ec"],
	"inquisitor": ["e2d6b8", "9d3b3b", "8ff7e8", "d9a93f", "1a1410", "5b3f2c", "e8e2d0"],
	"emperor": ["3b2550", "efe6d2", "8ff7e8", "e0b04a", "2a2028", "5b3f2c", "8ff7e8"],
	"smith": ["8a5a48", "4a3428", "ff8a3a", "5a5a62", "1a1210", "3a2a22", "c9c2b0"],
	"slag": ["3a2a2a", "2a1e1e", "ffe08a", "ff8a3a", "120c0c", "3a2a22", "ffd84a"],
	"wolf": ["c8d4e0", "e8f2fa", "9fe8ff", "8aa0b8", "1a2230", "5b3f2c", "ffffff"],
	"archer_ice": ["5a7aa0", "2a3a5a", "9fe8ff", "8aa0b8", "0c1220", "6a7a8a", "dff6ff"],
	"penitent_ice": ["6a7a8a", "9aa8b8", "9fe8ff", "3a4a6a", "10161e", "4a3a30", "dff6ff"],
	"guard_forge": ["3a3a42", "2a2a30", "ff8a3a", "b86a3a", "0c0c10", "4a2a1e", "e8c09a"],
	"scribe": ["c8b48a", "3a3a6a", "ffd84a", "d9a93f", "14101a", "5b3f2c", "e8e2d0"],
	"gargoyle": ["7a7468", "5a544a", "ff5a4a", "9a9488", "1a1612", "4a3a30", "c9c2b0"],
	"thorn": ["7a3a5a", "3a6a3a", "ffd84a", "c8e07a", "140c10", "4a3a20", "e8f0c0"],
	"moss_beast": ["4a5a3a", "6a8a4a", "ffd84a", "8aa05a", "141810", "4a3a20", "d9e2c0"],
	"masked": ["2a2232", "14101a", "ffd84a", "e8d070", "100c14", "4a3a30", "d9e2ec"],
	"herald": ["d8d0a0", "4a3a5a", "ffd84a", "c8a040", "14101a", "4a3a30", "e8e2d0"],
	"automaton": ["8a6a3a", "4a3a2a", "9fe8ff", "c8a050", "0c1018", "3a2a1a", "dff6ff"],
	"star": ["e8f0ff", "9ab0d8", "ffffff", "ffd84a", "1a2030", "3a2a1a", "ffffff"],
	"wolf_king": ["dfe8f0", "f4fbff", "9fe8ff", "6a8ab0", "1a2230", "5b3f2c", "bfe6ea"],
	"colossus": ["7a4a38", "4a2a20", "ff8a3a", "4a4a52", "140c0c", "3a2a22", "ffb050"],
	"architect": ["d8c890", "3a3a7a", "ffd84a", "e0b04a", "1a1420", "5b3f2c", "e8e2d0"],
	"mother_root": ["5a3a4a", "4a7a3a", "ffd84a", "c84a6a", "140810", "3a2a18", "e8f0c0"],
	"faceless_king": ["3a2a1a", "d8c050", "ffd84a", "f0e8c0", "0c0a08", "4a3a20", "e8e2d0"],
	"wisp": ["c08fff", "6a4a9a", "ffffff", "e8d070", "1a1020", "3a2a1a", "ffffff"],
	"astronomer": ["2a3a6a", "14203a", "9fe8ff", "d8b060", "0a0e18", "5b3f2c", "ffffff"],
	"elite_hunter": ["9ab0c8", "e8f2fa", "9fe8ff", "5a6a8a", "141a24", "4a3a30", "dff6ff"],
	"elite_forgemaster": ["3a2a2a", "7a3a20", "ff8a3a", "5a5a62", "0c0808", "3a2a22", "ffb050"],
	"elite_librarian": ["4a3a7a", "d8c890", "ffd84a", "c09a4a", "100c18", "4a3a28", "e8e2d0"],
	"elite_thornkeeper": ["3a5a2a", "7a2a4a", "ffd84a", "c84a6a", "0c1008", "4a3a20", "e8f0c0"],
	"elite_duelist": ["c8a830", "2a2010", "ffffff", "f0e070", "0c0a06", "3a2a1a", "ffffff"],
	"elite_brass": ["b88a3a", "5a4020", "9fe8ff", "e0b860", "100c08", "3a2a1a", "dff6ff"],
	"mason": ["6a5642", "a8583a", "ff9a3c", "9a968a", "1a1612", "4a3a30", "c9c2b0"],
	"seed_pod": ["8a6a3a", "4a6a2a", "ff6a4a", "c8e07a", "2a0c10", "4a3a20", "e8f0c0"],
	"dancer": ["d8b830", "5a1a2a", "ffffff", "f0e070", "0c0a06", "3a2a1a", "ffffff"],
	"lens": ["b88a3a", "1a2a4a", "9fe8ff", "e0b860", "dff6ff", "3a2a1a", "ffffff"],
}


# `look` é a linha da tabela (uma folha pode ter várias pinturas: o Penitente
# do gelo usa a folha do Penitente com a paleta "penitent_ice").
static func palette(look: String, warn := false) -> PackedColorArray:
	var t: Array = TABLE[look]
	var main := Color(t[0])
	var sec := Color(t[1])
	var acc := Color(t[3])
	var wood := Color(t[5])
	if warn:
		# aviso de golpe: a roupa esquenta para o laranja
		main = main.lerp(Palette.TELEGRAPH, 0.55)
		sec = sec.lerp(Palette.TELEGRAPH, 0.35)
	return PackedColorArray([
		Color(0, 0, 0, 0), Color("0b0910"),
		main.lightened(0.22), main, main.darkened(0.38),
		sec.lightened(0.22), sec, sec.darkened(0.38),
		Color(t[2]),
		acc.lightened(0.3), acc, acc.darkened(0.35),
		Color(t[4]),
		wood.darkened(0.35), wood, Color(t[6]),
	])
