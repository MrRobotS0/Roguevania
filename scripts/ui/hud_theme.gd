class_name HudTheme
extends RefCounted

# As cores do HUD por domínio (o "bg" pinta as células da vida no Observatório).
# As molduras, barras, slots e fitas vêm da arte de kits: ver HudSkin.
# A cor da vida não muda nunca: vermelho é vida em qualquer lugar.
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
	"necropole": {"frame": "4a5068", "light": "c8d4e8", "dark": "0c0e16", "bg": "0e1018", "accent": "a8c0e8", "style": "plain"},
	"catedral": {"frame": "2a4a6a", "light": "8ad0f0", "dark": "08121c", "bg": "0a1622", "accent": "6ab8e8", "style": "ice"},
	"ventre": {"frame": "6a2028", "light": "e86a6a", "dark": "1a0608", "bg": "1a0a0c", "accent": "c8d040", "style": "drips"},
	"penhascos": {"frame": "5a4a7a", "light": "e0d0ff", "dark": "120e1c", "bg": "140f20", "accent": "c8a8ff", "style": "circuit"},
	"cavernas": {"frame": "3a4048", "light": "8ac8d8", "dark": "06080a", "bg": "0a0c10", "accent": "8ac8e8", "style": "rivets"},
	"bosque": {"frame": "5a4a2a", "light": "d8c890", "dark": "14100a", "bg": "12100a", "accent": "e8d070", "style": "vines"},
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
