class_name HudTheme
extends RefCounted

# A moldura do HUD muda com o domínio: o lugar continua igual (vida em cima à
# esquerda, slots embaixo), só a pele troca. A cor da vida não muda nunca:
# vermelho é vida em qualquer lugar.
#
#   frame  borda       light  brilho do chanfro    dark  sombra do chanfro
#   bg     fundo       accent enfeite              style que enfeite desenhar

const THEMES := {
	"": {"frame": "4a3f60", "light": "8a7fa8", "dark": "07060b", "bg": "1b1726", "accent": "f2c14e", "style": "plain"},
	"mar_de_cinzas": {"frame": "8a6a3a", "light": "e0b860", "dark": "2a1c10", "bg": "1b140f", "accent": "f2c14e", "style": "sun"},
	"saloes": {"frame": "5a7a98", "light": "dff6ff", "dark": "16202c", "bg": "0e1620", "accent": "9fe8ff", "style": "ice"},
	"forja_rubra": {"frame": "4a4a52", "light": "9a9aa6", "dark": "120c0c", "bg": "160c0a", "accent": "ff8a3a", "style": "rivets"},
	"torre_babel": {"frame": "8a8270", "light": "efe6d2", "dark": "2a241a", "bg": "18140e", "accent": "e0b04a", "style": "glyphs"},
	"jardim_primordial": {"frame": "4a6a2a", "light": "9cc65a", "dark": "141c0c", "bg": "0e140a", "accent": "c8e07a", "style": "vines"},
	"carcosa": {"frame": "5a4a24", "light": "e8d070", "dark": "140e06", "bg": "120e08", "accent": "ffd84a", "style": "drips"},
	"observatorio": {"frame": "1f3a6a", "light": "9fe8ff", "dark": "04070e", "bg": "050a14", "accent": "6fe8ff", "style": "circuit"},
}


static func of(id: String) -> Dictionary:
	var t: Dictionary = THEMES.get(id, THEMES[""])
	var out := {"style": t["style"]}
	for k in ["frame", "light", "dark", "bg", "accent"]:
		out[k] = Color(t[k])
	return out


# Meio do caminho entre dois temas (troca suave ao mudar de domínio).
static func blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var out := {"style": b["style"] if k >= 0.5 else a["style"]}
	for key in ["frame", "light", "dark", "bg", "accent"]:
		out[key] = (a[key] as Color).lerp(b[key], k)
	return out


# Painel chanfrado com o enfeite do domínio. `t` é o relógio do HUD (anima
# gotas, cintilação do circuito etc.).
static func panel(ci: CanvasItem, r: Rect2, th: Dictionary, t: float, ornate := true) -> void:
	var dark: Color = th["dark"]
	var frame: Color = th["frame"]
	var light: Color = th["light"]
	var bg: Color = th["bg"]
	ci.draw_rect(r.grow(2), dark)
	ci.draw_rect(r.grow(1), frame)
	ci.draw_rect(r, bg)
	# chanfro: luz em cima, sombra embaixo
	ci.draw_rect(Rect2(r.position.x - 1, r.position.y - 1, r.size.x + 2, 1), light)
	ci.draw_rect(Rect2(r.position.x - 1, r.end.y, r.size.x + 2, 1), frame.darkened(0.35))
	if ornate:
		ornament(ci, r, th, t)


static func ornament(ci: CanvasItem, r: Rect2, th: Dictionary, t: float) -> void:
	var a: Color = th["accent"]
	var light: Color = th["light"]
	var dark: Color = th["dark"]
	var x0 := r.position.x - 2
	var x1 := r.end.x + 1
	var y0 := r.position.y - 2
	var y1 := r.end.y + 1
	match String(th["style"]):
		"sun":
			# raios de sol nos cantos: o império que adorava o deus que ardeu
			for c in [Vector2(x0, y0), Vector2(x1, y0)]:
				ci.draw_rect(Rect2(c - Vector2(1, 1), Vector2(3, 3)), a)
				ci.draw_rect(Rect2(c + Vector2(0, -3), Vector2(1, 2)), a.darkened(0.2))
				ci.draw_rect(Rect2(c + Vector2(-3 if c.x == x0 else 2, 0), Vector2(2, 1)), a.darkened(0.2))
		"ice":
			# pingentes pendurados embaixo, de tamanhos diferentes
			var i := 0
			var x := r.position.x + 3
			while x < r.end.x - 2:
				var tall := 1 + (i * 7) % 3
				ci.draw_rect(Rect2(x, y1 + 1, 1, tall), light if i % 2 == 0 else a)
				x += 5 + (i % 3)
				i += 1
		"rivets":
			# rebites de ferro e uma costura de brasa que pulsa
			for c in [Vector2(x0 + 1, y0 + 1), Vector2(x1 - 1, y0 + 1), Vector2(x0 + 1, y1 - 1), Vector2(x1 - 1, y1 - 1)]:
				ci.draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), light)
			var glow := a
			glow.a = 0.55 + 0.35 * sin(t * 3.0)
			ci.draw_rect(Rect2(r.position.x + 2, y1 + 1, r.size.x - 4, 1), glow)
		"glyphs":
			# letras de mil línguas gravadas na borda de cima
			var x := r.position.x + 2
			var i := 0
			while x < r.end.x - 2:
				var h := 1 + (i * 5) % 2
				ci.draw_rect(Rect2(x, y0 - h, 1, h), a if i % 3 else light)
				x += 3
				i += 1
		"vines":
			# cipó com folhas enroscando a borda
			var x := r.position.x
			var i := 0
			while x < r.end.x:
				var up := (i % 2) == 0
				ci.draw_rect(Rect2(x, y1 + (1 if up else 2), 2, 1), a.darkened(0.3))
				if i % 3 == 0:
					ci.draw_rect(Rect2(x + 1, y1 + (2 if up else 3), 2, 2), a)
				x += 4
				i += 1
			ci.draw_rect(Rect2(x0 - 1, y0 - 1, 3, 2), a)
		"drips":
			# o amarelo escorre devagar
			for i in 4:
				var x := r.position.x + 4 + i * (r.size.x - 8) / 3.0
				var drop := 1.0 + fposmod(t * 0.6 + i * 0.37, 1.0) * 4.0
				var c := a.darkened(0.15 * (i % 2))
				ci.draw_rect(Rect2(roundf(x), y1 + 1, 1, roundf(drop)), c)
				ci.draw_rect(Rect2(roundf(x) - (1 if drop > 3.5 else 0), y1 + roundf(drop), 1 + (1 if drop > 3.5 else 0), 1), c)
		"circuit":
			# cantoneiras de vidro e latão, e uma linha de varredura correndo
			for c in [Vector2(x0, y0), Vector2(x1, y0), Vector2(x0, y1), Vector2(x1, y1)]:
				var sx := 1.0 if c.x == x0 else -1.0
				var sy := 1.0 if c.y == y0 else -1.0
				ci.draw_rect(Rect2(c.x - (0.0 if sx > 0 else 3.0), c.y, 4, 1), a)
				ci.draw_rect(Rect2(c.x, c.y - (0.0 if sy > 0 else 3.0), 1, 4), a)
			var scan := fposmod(t * 40.0, r.size.x + 20.0) - 10.0
			if scan > 0.0 and scan < r.size.x:
				var s := a
				s.a = 0.6
				ci.draw_rect(Rect2(r.position.x + scan, y0, 2, 1), s)
				ci.draw_rect(Rect2(r.position.x + r.size.x - scan, y1, 2, 1), s)
			var blink := dark.lerp(a, 0.5 + 0.5 * sin(t * 5.0))
			ci.draw_rect(Rect2(x1 + 2, y0 + 1, 1, 1), blink)
