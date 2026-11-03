class_name SkinData
extends Resource

# Aparência do herói. Só muda cor e detalhe: nenhuma skin mexe em vida, dano
# ou velocidade. Como se ganha:
#   "starter"  já vem liberada
#   "essence"  compra com a Vigia (cost)
#   "feat"     feito na conta inteira (feat: "boss" = derrotar o Imperador Cego,
#              "deaths10" = morrer 10 vezes); feat_text explica na tela

@export var id := ""
@export var title := ""
@export var lore := ""
@export var cloak := Color("2e5d8a")
@export var cloak_dark := Color("1f3f60")
@export var hood := Color("1a2a45")
@export var eye := Color("8ff7e8")
@export var scarf := Color("e8a33d")
@export var closed_eyes := false
@export var unlock := "starter"
@export var cost := 0
@export var feat := ""
@export var feat_text := ""


func colors() -> Dictionary:
	return {"cloak": cloak, "cloak_dark": cloak_dark, "hood": hood, "eye": eye,
		"scarf": scarf, "closed_eyes": closed_eyes}


func how_to_get() -> String:
	match unlock:
		"essence":
			return "COMPRE COM A VIGIA · %d DE ESSÊNCIA" % cost
		"feat":
			return feat_text.to_upper()
	return ""
