class_name PixelFont
extends RefCounted

# Fonte 3x5 desenhada pixel a pixel. Fontes vetoriais nessa resolução
# (480x270) borram; esta fica nítida em qualquer escala inteira.

const GLYPH_W := 3
const GLYPH_H := 5
const ADVANCE := 4

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
}

const ACCENTS := {
	"Á": "A", "À": "A", "Â": "A", "Ã": "A", "É": "E", "Ê": "E", "Í": "I",
	"Ó": "O", "Ô": "O", "Õ": "O", "Ú": "U", "Ç": "C",
}


static func width(text: String, scale := 1) -> int:
	return maxi(text.length() * ADVANCE - 1, 0) * scale


static func draw(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale := 1, shadow := Palette.UI_SHADOW) -> void:
	# A sombra de 1 px dá contraste sobre qualquer fundo do cenário.
	if shadow.a > 0.0:
		_draw_run(ci, text, pos + Vector2(scale, scale), shadow, scale)
	_draw_run(ci, text, pos, color, scale)


static func draw_centered(ci: CanvasItem, text: String, center: Vector2, color: Color, scale := 1, shadow := Palette.UI_SHADOW) -> void:
	var origin := Vector2(round(center.x - width(text, scale) * 0.5), round(center.y - GLYPH_H * scale * 0.5))
	draw(ci, text, origin, color, scale, shadow)


static func _draw_run(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale: int) -> void:
	var x := pos.x
	for ch in text.to_upper():
		var bits: String = GLYPHS.get(ACCENTS.get(ch, ch), GLYPHS["?"])
		for i in bits.length():
			if bits[i] == "1":
				var px := x + (i % GLYPH_W) * scale
				var py := pos.y + (i / GLYPH_W) * scale
				ci.draw_rect(Rect2(px, py, scale, scale), color)
		x += ADVANCE * scale


# Quebra o texto em linhas de até `limit` caracteres, sem cortar palavras.
static func wrap(text: String, limit: int) -> PackedStringArray:
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
