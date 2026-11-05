class_name Catalog
extends RefCounted

# Lista oficial do que existe no jogo. Arma ou habilidade nova: criar o
# .tres e acrescentar o caminho aqui.

const WEAPONS := [
	"res://content/weapons/espada_cerimonial.tres",
	"res://content/weapons/arco_dunas.tres",
	"res://content/weapons/lanca_peregrino.tres",
	"res://content/weapons/machado_carrasco.tres",
	"res://content/weapons/arco_brasa.tres",
	"res://content/weapons/adagas_gemeas.tres",
	"res://content/weapons/martelo_forja.tres",
	"res://content/weapons/arco_inverno.tres",
	"res://content/weapons/chicote_espinhos.tres",
	"res://content/weapons/foice_inverno.tres",
	"res://content/weapons/punhos_bronze.tres",
	"res://content/weapons/besta_carcosa.tres",
	"res://content/weapons/cetro_astronomo.tres",
	"res://content/weapons/arco_ossos.tres",
	"res://content/weapons/arco_prece.tres",
	"res://content/weapons/arco_raposa.tres",
	"res://content/weapons/arco_sonho.tres",
	"res://content/weapons/bordao_andarilho.tres",
	"res://content/weapons/cetro_nomes.tres",
	"res://content/weapons/clava_votiva.tres",
	"res://content/weapons/cutelo_glutao.tres",
	"res://content/weapons/dentes_ventre.tres",
	"res://content/weapons/espada_estrada.tres",
	"res://content/weapons/espada_rei.tres",
	"res://content/weapons/garras_parasita.tres",
	"res://content/weapons/lamina_devaneio.tres",
	"res://content/weapons/lamina_luto.tres",
	"res://content/weapons/lanca_pesadelo.tres",
	"res://content/weapons/machado_touro.tres",
	"res://content/weapons/picareta_escavador.tres",
	"res://content/weapons/punhal_cego.tres",
	"res://content/weapons/sacola_bombas.tres",
	"res://content/weapons/tridente_afogado.tres",
]

const SKILLS := [
	"res://content/skills/granada_cinzas.tres",
	"res://content/skills/egide_bronze.tres",
	"res://content/skills/lanca_vidro.tres",
	"res://content/skills/armadilha_laminas.tres",
	"res://content/skills/torreta_vidro.tres",
	"res://content/skills/espirito_cinza.tres",
	"res://content/skills/corrente_ferreiro.tres",
	"res://content/skills/sino_carcosa.tres",
	"res://content/skills/raiz_viva.tres",
	"res://content/skills/estrela_cadente.tres",
	"res://content/skills/bile_acida.tres",
	"res://content/skills/dentes_chao.tres",
	"res://content/skills/escudo_eremita.tres",
	"res://content/skills/fogo_raposa.tres",
	"res://content/skills/grito_carpideira.tres",
	"res://content/skills/laco_salteador.tres",
	"res://content/skills/lanterna_caida.tres",
	"res://content/skills/mao_cova.tres",
	"res://content/skills/olho_sonho.tres",
	"res://content/skills/onda_catedral.tres",
	"res://content/skills/pesadelo_vivo.tres",
	"res://content/skills/prece_lancada.tres",
]

# Afixos: modificadores sorteados nas armas que caem (0 a 2 por arma).
const AFFIXES := {
	"brasa": {"title": "de Brasa", "detail": "GOLPES QUEIMAM"},
	"geada": {"title": "da Geada", "detail": "25% DE ATORDOAR"},
	"vampira": {"title": "Vampira", "detail": "CADA ACERTO CURA 1"},
	"explosiva": {"title": "Explosiva", "detail": "CRÍTICO EXPLODE EM VOLTA"},
	"afiada": {"title": "Afiada", "detail": "+15% DE DANO"},
	"ligeira": {"title": "Ligeira", "detail": "GOLPES 20% MAIS RÁPIDOS"},
	"carrasca": {"title": "Carrasca", "detail": "+50% EM QUEM TEM MENOS DE 30% DE VIDA"},
	"eco": {"title": "do Eco", "detail": "20% DE ACERTAR DUAS VEZES"},
}

const SKINS := [
	"res://content/skins/andarilho.tres",
	"res://content/skins/manto_cinza.tres",
	"res://content/skins/desperto.tres",
	"res://content/skins/herdeiro_vesper.tres",
	"res://content/skins/casca_vidro.tres",
	"res://content/skins/olhos_fechados.tres",
	"res://content/skins/saco_penitente.tres",
	"res://content/skins/asa_dragao.tres",
	"res://content/skins/capa_estrada.tres",
	"res://content/skins/cinza_pura.tres",
	"res://content/skins/couro_fenda.tres",
	"res://content/skins/escama_serpe.tres",
	"res://content/skins/manto_sonho.tres",
	"res://content/skins/mortalha.tres",
	"res://content/skins/nove_caudas.tres",
	"res://content/skins/pele_ventre.tres",
	"res://content/skins/rei_esquecido.tres",
	"res://content/skins/tentaculo.tres",
	"res://content/skins/vestes_afogadas.tres",
]

const BIOMES := {
	"mar_de_cinzas": "res://content/biomes/mar_de_cinzas/biome.tres",
	"saloes": "res://content/biomes/saloes/biome.tres",
	"forja_rubra": "res://content/biomes/forja_rubra/biome.tres",
	"torre_babel": "res://content/biomes/torre_babel/biome.tres",
	"jardim_primordial": "res://content/biomes/jardim_primordial/biome.tres",
	"carcosa": "res://content/biomes/carcosa/biome.tres",
	"observatorio": "res://content/biomes/observatorio/biome.tres",
	"necropole": "res://content/biomes/necropole/biome.tres",
	"catedral": "res://content/biomes/catedral/biome.tres",
	"ventre": "res://content/biomes/ventre/biome.tres",
	"penhascos": "res://content/biomes/penhascos/biome.tres",
	"cavernas": "res://content/biomes/cavernas/biome.tres",
	"bosque": "res://content/biomes/bosque/biome.tres",
}

const STAGE_NAMES := {
	"beira": "A Beira",
	"ondas": "Modo Waves",
	"sala_dos_treze": "A Sala dos Treze",
	"mar_de_cinzas": "O Mar de Cinzas",
	"saloes": "Os Salões do Último Inverno",
	"forja_rubra": "A Forja Rubra",
	"lobo": "A Toca do Lobo da Longa Noite",
	"colosso": "A Bigorna do Colosso",
	"torre_babel": "A Torre de Babel",
	"jardim_primordial": "O Jardim Primordial",
	"arquiteto": "O Topo da Torre",
	"mae_raiz": "O Coração do Jardim",
	"carcosa": "Carcosa",
	"observatorio": "O Observatório Celeste",
	"rei_sem_rosto": "O Salão do Rei sem Rosto",
	"astronomo": "A Cúpula do Último Astrônomo",
	"necropole": "A Necrópole",
	"rei_esquecido": "A Cripta do Rei Esquecido",
	"catedral": "A Catedral Submersa",
	"o_que_responde": "O Altar do Que Responde",
	"ventre": "O Ventre",
	"insaciavel": "A Goela do Insaciável",
	"penhascos": "Os Penhascos do Sonho",
	"dragao_sonhado": "O Ninho do Dragão Sonhado",
	"cavernas": "As Cavernas Fundas",
	"serpe": "O Fundo da Serpe",
	"bosque": "O Bosque Errante",
	"raposa": "A Clareira da Raposa",
	"trono": "O Trono do Imperador Cego",
}

const STAGE_HINTS := {
	"saloes": "GELO E LOBOS · MAIS CALMO",
	"forja_rubra": "FOGO E FERRO · MAIS PERIGOSO, PAGA MELHOR",
	"torre_babel": "GÁRGULAS E ESCRIBAS · VERTICAL",
	"jardim_primordial": "FERAS E ESPINHOS · TUDO CRESCE",
	"carcosa": "MÁSCARAS QUE SOMEM · O MAIS ESTRANHO",
	"observatorio": "AUTÔMATOS E ESTRELAS · O MAIS ABERTO",
	"necropole": "MORTOS QUE LEMBRAM · O MAIS SOMBRIO",
	"catedral": "ÁGUA E PRECES · CHEIO DE ATIRADORES",
	"ventre": "CARNE VIVA · O MAIS BRUTO",
	"penhascos": "SONHO E VENTO · MUITOS VÃOS",
	"cavernas": "ESCURO E FENDAS · O MAIS FECHADO",
	"bosque": "ESTRADA SEM FIM · O MAIS RÁPIDO",
	"trono": "O FIM DA JORNADA",
}

# Mutações: bônus de uma partida só, escolhidos nas passagens (até 3).
const MUTATIONS := [
	{"id": "sangue_quente", "title": "Sangue Quente", "detail": "CADA ABATE CURA 3% DA VIDA"},
	{"id": "pes_leves", "title": "Pés Leves", "detail": "ROLA DE NOVO SEM ESPERAR"},
	{"id": "polvora", "title": "Pólvora Seca", "detail": "HABILIDADES RECARREGAM 35% MAIS RÁPIDO"},
	{"id": "vinganca", "title": "Vingança", "detail": "+40% DE DANO POR 3 S DEPOIS DE APANHAR"},
	{"id": "frieza", "title": "Frieza", "detail": "CRÍTICOS CAUSAM +25% DE DANO"},
	{"id": "lamina_plena", "title": "Lâmina Plena", "detail": "+20% DE DANO COM A VIDA ACIMA DE 80%"},
	{"id": "colecionador", "title": "Colecionador", "detail": "+50% DE ESSÊNCIA E OURO DOS INIMIGOS"},
	{"id": "folego", "title": "Fôlego", "detail": "+1 FRASCO DE CURA NESTA PARTIDA"},
	{"id": "couraca", "title": "Couraça de Escória", "detail": "AO APANHAR, ESTILHAÇOS ACERTAM QUEM ESTIVER COLADO"},
	{"id": "ultimo_folego", "title": "Teimosia", "detail": "UMA VEZ POR ANDAR, FICA COM 1 DE VIDA EM VEZ DE MORRER"},
	{"id": "sede", "title": "Sede de Batalha", "detail": "CADA ABATE ADIANTA AS HABILIDADES EM 1 S"},
	{"id": "passo_ligeiro", "title": "Passo do Lobo", "detail": "ROLAR ATRAVÉS DE UM GOLPE: O PRÓXIMO ATAQUE É CRÍTICO"},
	{"id": "barganha", "title": "Língua de Mercador", "detail": "TUDO NO MERCADOR CUSTA 30% MENOS"},
	{"id": "rastro_brasa", "title": "Rastro de Brasa", "detail": "ROLAR ATRAVÉS DE UM INIMIGO O INCENDEIA"},
	{"id": "luto", "title": "Luto", "detail": "CADA ABATE DÁ +1 DE VIDA MÁXIMA (ATÉ +25)"},
	{"id": "prece_atendida", "title": "Prece Atendida", "detail": "O FRASCO CURA 30% A MAIS"},
	{"id": "fome_sem_fim", "title": "Fome sem Fim", "detail": "+2% DE DANO POR ABATE NA PARTIDA (ATÉ +30%)"},
	{"id": "sono_leve", "title": "Sono Leve", "detail": "+30% DE DANO NO AR"},
	{"id": "pele_de_pedra", "title": "Pele de Pedra", "detail": "-15% DE DANO RECEBIDO"},
	{"id": "ultima_prece", "title": "Última Prece", "detail": "+35% DE DANO COM MENOS DE 30% DE VIDA"},
]
const MAX_MUTATIONS := 3
const STARTER_MUTATIONS := ["sangue_quente", "pes_leves", "prece_atendida"]

# O que se leva da carroça da Beira: uma por partida. As com "needs" saem de uma conquista.
const ADVANTAGES := [
	{"id": "saco_moedas", "title": "Saco de Moedas", "detail": "COMEÇA COM +80 DE OURO"},
	{"id": "frasco_reserva", "title": "Frasco de Reserva", "detail": "+1 FRASCO DE CURA"},
	{"id": "olho_coletor", "title": "Olho de Coletor", "detail": "+25% DE ESSÊNCIA", "needs": "cinza_na_boca"},
	{"id": "cinza_dura", "title": "Cinza Dura", "detail": "+20% DE VIDA MÁXIMA", "needs": "mao_pesada"},
	{"id": "lamina_afiada", "title": "Lâmina Afiada", "detail": "AS ARMAS INICIAIS VÊM UM NÍVEL ACIMA", "needs": "caiu_o_primeiro"},
	{"id": "bolso_fundo", "title": "Bolso Fundo", "detail": "COMEÇA COM UMA SEGUNDA HABILIDADE AO ACASO", "needs": "longe_de_casa"},
	{"id": "cinza_que_volta", "title": "Cinza que Volta", "detail": "UMA VEZ POR PARTIDA, VOLTA COM METADE DA VIDA EM VEZ DE MORRER", "needs": "trono_vazio"},
]

const GUARDIANS := ["O LOBO DA LONGA NOITE", "O COLOSSO DA BIGORNA", "O REI ESQUECIDO", "O ARQUITETO MUDO", "A MÃE-RAIZ", "O QUE RESPONDE",
	"O REI SEM ROSTO", "O ÚLTIMO ASTRÔNOMO", "O INSACIÁVEL", "O DRAGÃO SONHADO", "A SERPE DO FUNDO", "A RAPOSA DE NOVE CAUDAS", "O IMPERADOR CEGO"]

# Conquistas: what = o que medir (Meta.feat_value), n = quanto. "secret" esconde até sair.
const FEATS := [
	{"id": "cinza_na_boca", "title": "Cinza na Boca", "detail": "MORRA PELA PRIMEIRA VEZ", "what": "deaths", "n": 1},
	{"id": "outro_igual", "title": "Outro Igual a Você", "detail": "MORRA 10 VEZES", "what": "deaths", "n": 10},
	{"id": "cinquenta_cinzas", "title": "Cinquenta Cinzas", "detail": "MORRA 50 VEZES", "what": "deaths", "n": 50},
	{"id": "mao_pesada", "title": "Mão Pesada", "detail": "DERROTE 100 INIMIGOS", "what": "kills", "n": 100},
	{"id": "carrasco", "title": "Carrasco", "detail": "DERROTE 1000 INIMIGOS", "what": "kills", "n": 1000},
	{"id": "caiu_o_primeiro", "title": "Caiu o Primeiro", "detail": "DERROTE UM GUARDIÃO", "what": "guardians", "n": 1},
	{"id": "cinco_portas", "title": "Cinco Portas", "detail": "DERROTE 5 GUARDIÕES DIFERENTES", "what": "guardians", "n": 5},
	{"id": "todas_as_portas", "title": "Todas as Portas", "detail": "DERROTE OS 13 GUARDIÕES", "what": "guardians", "n": 13},
	{"id": "longe_de_casa", "title": "Longe de Casa", "detail": "CHEGUE AO QUINTO ANDAR", "what": "deepest", "n": 5},
	{"id": "trono_vazio", "title": "O Trono Vazio", "detail": "VENÇA O IMPERADOR CEGO", "what": "wins", "n": 1},
	{"id": "antes_do_sino", "title": "Antes do Sino", "detail": "VENÇA EM MENOS DE 30 MINUTOS", "what": "quick", "n": 1},
	{"id": "brasa_viva", "title": "Brasa Viva", "detail": "VENÇA COM 2 BRASAS", "what": "embers", "n": 3},
	{"id": "quem_le_pedra", "title": "Quem Lê Pedra", "detail": "LEIA 10 INSCRIÇÕES", "what": "lore", "n": 10},
	{"id": "bestiario", "title": "Bestiário", "detail": "DERROTE 30 CRIATURAS DIFERENTES", "what": "creatures", "n": 30},
	{"id": "mao_de_ferreiro", "title": "Mão de Ferreiro", "detail": "ENTREGUE 10 PLANTAS À VIGIA", "what": "blueprints", "n": 10},
	{"id": "o_que_fica", "title": "O Que Fica", "detail": "CONSIGA UMA RUNA", "what": "runes", "n": 1},
	{"id": "calice_cheio", "title": "Cálice Cheio", "detail": "BEBA 10 MUTAÇÕES DIFERENTES", "what": "mutations", "n": 10},
	{"id": "guarda_roupa", "title": "Guarda-Roupa", "detail": "TENHA 5 APARÊNCIAS", "what": "skins", "n": 5},
	{"id": "soltar", "title": "Soltar", "detail": "COMPLETE O FINAL VERDADEIRO", "what": "awake", "n": 1, "secret": true},
	{"id": "outra_volta", "title": "Outra Volta", "detail": "VENÇA UM CICLO DO NOVO JOGO+", "what": "plus", "n": 2, "secret": true},
	{"id": "cinco_voltas", "title": "Cinco Voltas", "detail": "CHEGUE AO ÚLTIMO CICLO", "what": "plus", "n": 5, "secret": true},
]

# Melhorias permanentes compradas com Essência na Vigia (além das armas).
const BLESSINGS := [
	{"id": "calice_1", "title": "Cálice Extra", "cost": 50, "detail": "+1 FRASCO DE CURA EM TODA PARTIDA"},
	{"id": "bencao_vigia", "title": "Bênção da Vigia", "cost": 40, "detail": "COMEÇA COM +1 NUM ATRIBUTO AO ACASO"},
	{"id": "calice_2", "title": "Segundo Cálice", "cost": 110, "detail": "+1 FRASCO DE CURA (REQUER O PRIMEIRO)", "needs": "calice_1"},
	{"id": "bolsa_inicial", "title": "Bolsa de Viagem", "cost": 45, "detail": "COMEÇA A PARTIDA COM 60 DE OURO"},
]


static func advantage(id: String) -> Dictionary:
	for a: Dictionary in ADVANTAGES:
		if a["id"] == id:
			return a
	return {}


static func feat(id: String) -> Dictionary:
	for f: Dictionary in FEATS:
		if f["id"] == id:
			return f
	return {}


static func all_gear() -> Array[Resource]:
	var out: Array[Resource] = []
	for p in WEAPONS + SKILLS:
		out.append(load(p))
	return out


static func find(id: String) -> Resource:
	for r in all_gear():
		if r.id == id:
			return r
	return null


static func unlocked_pool() -> Array[Resource]:
	var out: Array[Resource] = []
	for r in all_gear():
		if Meta.has_gear(r):
			out.append(r)
	return out


static func random_gear(rng: RandomNumberGenerator, tier: int, exclude: Array = []) -> Gear:
	var pool := unlocked_pool()
	var options: Array[Resource] = []
	for r in pool:
		if not exclude.has(r.id):
			options.append(r)
	if options.is_empty():
		options = pool
	var pick: Resource = options[rng.randi_range(0, options.size() - 1)]
	var bump := 1 if rng.randf() < 0.3 else 0
	var g := Gear.of(pick, tier + bump)
	if g.is_weapon():
		var roll := rng.randf() - 0.08 * tier
		var count := 0 if roll > 0.45 else (1 if roll > 0.08 else 2)
		var keys := AFFIXES.keys()
		for i in count:
			var a: String = keys[rng.randi_range(0, keys.size() - 1)]
			if not g.affixes.has(a):
				g.affixes.append(a)
	return g


static func biome(id: String) -> BiomeData:
	return load(BIOMES[id])


static func skins() -> Array[SkinData]:
	var out: Array[SkinData] = []
	for p in SKINS:
		out.append(load(p))
	return out


static func skin(id: String) -> SkinData:
	for s in skins():
		if s.id == id:
			return s
	return load(SKINS[0])


# Itens trancados cuja planta ainda não foi achada (o que pode cair dos inimigos).
static func unknown_blueprints(carrying: Array = []) -> Array[Resource]:
	var out: Array[Resource] = []
	for r in all_gear():
		if r.starter or Meta.is_unlocked(r.id) or Meta.knows(r.id) or carrying.has(r.id):
			continue
		out.append(r)
	return out


static func mutation(id: String) -> Dictionary:
	for m: Dictionary in MUTATIONS:
		if m["id"] == id:
			return m
	return {}
