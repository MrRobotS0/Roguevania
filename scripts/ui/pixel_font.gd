class_name PixelFont
extends RefCounted

# Duas fontes desenhadas pixel a pixel (fontes vetoriais nessa resolução borram):
#   pequena 3x5  -> números e rótulos do HUD          draw / draw_centered / width
#   texto   5x7  -> menus, faixas, telas, inscrições  body / body_centered / body_width
# Os acentos ficam numa tabela à parte e são desenhados por cima da letra-base,
# então "FÚRIA" e "NÍVEL" saem certos nas duas.

const GLYPH_W := 3
const GLYPH_H := 5
const ADVANCE := 4

const BODY_W := 5
const BODY_H := 7
const BODY_ADVANCE := 6
const BODY_LINE := 12      # 7 da letra + espaço para acento em cima e cedilha embaixo

# Fonte do texto (Opções > FONTE). Todas usam a mesma grade 5x7 e o mesmo passo,
# então nada no layout muda: só o desenho das letras. "classica" e "negrito" são
# a tabela BODY; as outras vêm de FontTables (tools/gen_fontes.py). Letra que
# falta numa fonte sai da clássica; os acentos são sempre os do jogo.
const FACES := ["classica", "negrito", "pixelify", "silkscreen", "tiny5"]
const FACE_NAMES := {"classica": "CLÁSSICA", "negrito": "NEGRITO"}
static var face := "classica"
static var _table: Dictionary = {}
static var _bold := false


static func use_face(id: String) -> void:
	face = id if FACES.has(id) else "classica"
	_bold = face == "negrito"
	_table = FontTables.TABLES.get(face, {})


static func face_name(id: String) -> String:
	return FACE_NAMES.get(id, FontTables.NAMES.get(id, id.to_upper()))

const GLYPHS := {
	"A": "010101111101101", "B": "110101110101110", "C": "011100100100011",
	"D": "110101101101110", "E": "111100110100111", "F": "111100110100100",
	"G": "011100101101011", "H": "101101111101101", "I": "111010010010111",
	"J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
	"M": "101111111101101", "N": "110101101101101", "O": "010101101101010",
	"P": "110101110100100", "Q": "010101101110011", "R": "110101110101101",
	"S": "011100010001110", "T": "111010010010010", "U": "101101101101111",
	"V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
	"Y": "101101010010010", "Z": "111001010100111",
	"0": "111101101101111", "1": "010110010010111", "2": "111001111100111",
	"3": "111001011001111", "4": "101101111001001", "5": "111100111001111",
	"6": "111100111101111", "7": "111001001010010", "8": "111101111101111",
	"9": "111101111001111",
	"!": "010010010000010", "?": "110001010000010", ".": "000000000000010",
	":": "000010000010000", "-": "000000111000000", "+": "000010111010000",
	"/": "001001010100100", "(": "010100100100010", ")": "010001001001010",
	",": "000000000010100", "'": "010010000000000", " ": "000000000000000",
	"·": "000000010000000", ">": "100010001010100", "<": "001010100010001", "%": "101001010100101",
	"=": "000111000111000", "*": "000101010101000", "[": "110100100100110", "]": "011001001001011",
	"\"": "101101000000000", "_": "000000000000111", "|": "010010010010010",
	";": "000010000010100",
	"←": "001010111010001", "→": "100010111010100",
}

const BODY := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", ".#.#."],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
	"!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	".": [".....", ".....", ".....", ".....", ".....", ".....", "..#.."],
	",": [".....", ".....", ".....", ".....", ".....", "..#..", ".#..."],
	":": [".....", "..#..", ".....", ".....", ".....", "..#..", "....."],
	";": [".....", "..#..", ".....", ".....", ".....", "..#..", ".#..."],
	"-": [".....", ".....", ".....", ".###.", ".....", ".....", "....."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"=": [".....", ".....", "#####", ".....", "#####", ".....", "....."],
	"/": ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."],
	"(": ["...#.", "..#..", ".#...", ".#...", ".#...", "..#..", "...#."],
	")": [".#...", "..#..", "...#.", "...#.", "...#.", "..#..", ".#..."],
	"[": [".###.", ".#...", ".#...", ".#...", ".#...", ".#...", ".###."],
	"]": [".###.", "...#.", "...#.", "...#.", "...#.", "...#.", ".###."],
	"'": ["..#..", "..#..", ".....", ".....", ".....", ".....", "....."],
	"\"": [".#.#.", ".#.#.", ".....", ".....", ".....", ".....", "....."],
	"·": [".....", ".....", ".....", "..#..", ".....", ".....", "....."],
	">": [".#...", "..#..", "...#.", "....#", "...#.", "..#..", ".#..."],
	"<": ["...#.", "..#..", ".#...", "#....", ".#...", "..#..", "...#."],
	"%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
	"*": [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."],
	"_": [".....", ".....", ".....", ".....", ".....", ".....", "#####"],
	"|": ["..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	" ": [".....", ".....", ".....", ".....", ".....", ".....", "....."],
	"↑": ["..#..", ".###.", "#.#.#", "..#..", "..#..", "..#..", "....."],
	"←": [".....", "..#..", ".#...", "#####", ".#...", "..#..", "....."],
	"→": [".....", "..#..", "...#.", "#####", "...#.", "..#..", "....."],
	"↓": [".....", "..#..", "..#..", "..#..", "#.#.#", ".###.", "..#.."],
}

# letra acentuada -> [letra-base, marca]
const ACCENTS := {
	"Á": ["A", "acute"], "À": ["A", "grave"], "Â": ["A", "circ"], "Ã": ["A", "tilde"],
	"É": ["E", "acute"], "Ê": ["E", "circ"], "Í": ["I", "acute"],
	"Ó": ["O", "acute"], "Ô": ["O", "circ"], "Õ": ["O", "tilde"],
	"Ú": ["U", "acute"], "Ü": ["U", "diaeresis"], "Ç": ["C", "cedilla"],
}

# Pixels de cada marca, relativos ao canto de cima da letra. Linha -1 fica
# vazia para a marca não grudar na letra.
const MARKS_SMALL := {
	"acute": [Vector2i(2, -3), Vector2i(1, -2)],
	"grave": [Vector2i(0, -3), Vector2i(1, -2)],
	"circ": [Vector2i(1, -3), Vector2i(0, -2), Vector2i(2, -2)],
	"tilde": [Vector2i(1, -3), Vector2i(2, -3), Vector2i(0, -2), Vector2i(1, -2)],
	"diaeresis": [Vector2i(0, -2), Vector2i(2, -2)],
	"cedilla": [Vector2i(1, 5), Vector2i(0, 6)],
}

const MARKS_BODY := {
	"acute": [Vector2i(3, -3), Vector2i(2, -2)],
	"grave": [Vector2i(1, -3), Vector2i(2, -2)],
	"circ": [Vector2i(2, -3), Vector2i(1, -2), Vector2i(3, -2)],
	"tilde": [Vector2i(1, -2), Vector2i(2, -3), Vector2i(3, -2), Vector2i(4, -3)],
	"diaeresis": [Vector2i(1, -2), Vector2i(3, -2)],
	"cedilla": [Vector2i(2, 7), Vector2i(3, 8), Vector2i(2, 8)],
}


# --- fonte pequena ---------------------------------------------------------------

static func width(text: String, scale := 1) -> int:
	text = Lang.t(text)
	return maxi(text.length() * ADVANCE - 1, 0) * scale


static func draw(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale := 1, shadow := Palette.UI_SHADOW) -> void:
	text = Lang.t(text)
	# A sombra de 1 px dá contraste sobre qualquer fundo do cenário.
	if shadow.a > 0.0:
		_small_run(ci, text, pos + Vector2(scale, scale), shadow, scale)
	_small_run(ci, text, pos, color, scale)


static func draw_centered(ci: CanvasItem, text: String, center: Vector2, color: Color, scale := 1, shadow := Palette.UI_SHADOW) -> void:
	var origin := Vector2(round(center.x - width(text, scale) * 0.5), round(center.y - GLYPH_H * scale * 0.5))
	draw(ci, text, origin, color, scale, shadow)


static func _small_run(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale: int) -> void:
	var x := pos.x
	for ch in text.to_upper():
		var base := ch
		var mark := ""
		if ACCENTS.has(ch):
			base = ACCENTS[ch][0]
			mark = ACCENTS[ch][1]
		var bits: String = GLYPHS.get(base, GLYPHS["?"])
		for i in bits.length():
			if bits[i] == "1":
				ci.draw_rect(Rect2(x + (i % GLYPH_W) * scale, pos.y + (i / GLYPH_W) * scale, scale, scale), color)
		if mark != "":
			for p: Vector2i in MARKS_SMALL[mark]:
				ci.draw_rect(Rect2(x + p.x * scale, pos.y + p.y * scale, scale, scale), color)
		x += ADVANCE * scale


# --- fonte de texto ----------------------------------------------------------------

static func body_width(text: String, scale := 1) -> int:
	text = Lang.t(text)
	return maxi(text.length() * BODY_ADVANCE - 1, 0) * scale


static func body(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale := 1, shadow := Palette.UI_SHADOW) -> void:
	text = Lang.t(text)
	if shadow.a > 0.0:
		_body_run(ci, text, pos + Vector2(scale, scale), shadow, scale)
	_body_run(ci, text, pos, color, scale)


static func body_centered(ci: CanvasItem, text: String, center: Vector2, color: Color, scale := 1, shadow := Palette.UI_SHADOW) -> void:
	var origin := Vector2(round(center.x - body_width(text, scale) * 0.5), round(center.y - BODY_H * scale * 0.5))
	body(ci, text, origin, color, scale, shadow)


static func _body_run(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale: int) -> void:
	var x := pos.x
	for ch in text.to_upper():
		var base := ch
		var mark := ""
		if ACCENTS.has(ch):
			base = ACCENTS[ch][0]
			mark = ACCENTS[ch][1]
		var rows: Array = _table.get(base, BODY.get(base, BODY["?"]))
		for r in BODY_H:
			var row: String = rows[r]
			var c := 0
			while c < BODY_W:
				# trechos seguidos viram um retângulo só (negrito: um pixel a mais)
				if row[c] == "#":
					var start := c
					while c < BODY_W and row[c] == "#":
						c += 1
					var run := c - start + (1 if _bold and c < BODY_W else 0)
					ci.draw_rect(Rect2(x + start * scale, pos.y + r * scale, run * scale, scale), color)
				else:
					c += 1
		if mark != "":
			for p: Vector2i in MARKS_BODY[mark]:
				ci.draw_rect(Rect2(x + p.x * scale, pos.y + p.y * scale, scale, scale), color)
		x += BODY_ADVANCE * scale


# Quebra o texto em linhas de até `limit` caracteres, sem cortar palavras.
static func wrap(text: String, limit: int) -> PackedStringArray:
	text = Lang.t(text)
	var out := PackedStringArray()
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" ", false):
			if line == "":
				line = word
			elif line.length() + 1 + word.length() <= limit:
				line += " " + word
			else:
				out.append(line)
				line = word
		out.append(line)
	return out
