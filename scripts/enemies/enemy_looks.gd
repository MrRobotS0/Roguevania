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
