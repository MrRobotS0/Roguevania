class_name SkillData
extends Resource

# Habilidade dos slots de habilidade.
# kind: "bomb" (arremesso que explode), "javelin" (projétil que atravessa),
#       "shield" (segurar para defender; apertar na hora certa = aparo),
#       "trap" (lâminas no chão), "turret" (atira sozinha), "spirit" (aliado
#       que persegue), "hook" (corrente que puxa), "bell" (atordoa tudo em
#       volta), "roots" (raiz que corre rente ao chão), "meteor" (estrela
#       que cai no inimigo mais perto)

@export var id := ""
@export var title := ""
@export var kind := "bomb"
@export var stat := "astucia"
@export var cooldown := 6.0
@export var damage := 20.0
@export var params: Dictionary = {}
@export var color := Color("e8a33d")
@export var starter := false
@export var unlock_cost := 0
@export_multiline var lore := ""
@export var icon := ""          # pixel art do item (assets/icons); vazio = desenho por código


func describe() -> String:
	match kind:
		"bomb": return "EXPLODE E QUEIMA · RECARGA %ds" % cooldown
		"javelin": return "ATRAVESSA INIMIGOS · CRÍTICO EM ATORDOADO"
		"shield": return "SEGURE PARA DEFENDER · NA HORA CERTA, APARA"
		"trap": return "LÂMINAS NO CHÃO POR %ds" % int(params.get("life", 8))
		"turret": return "ATIRA SOZINHA POR %ds" % int(params.get("life", 12))
		"spirit": return "UM ALIADO DE CINZA POR %ds" % int(params.get("life", 10))
		"hook": return "PUXA O INIMIGO E ATORDOA"
		"bell": return "ATORDOA TUDO EM VOLTA POR %.1fs" % float(params.get("stun", 1.4))
		"roots": return "CORRE PELO CHÃO, ATRAVESSA E PRENDE"
		"meteor": return "CAI NO INIMIGO MAIS PERTO E QUEIMA"
	return ""
