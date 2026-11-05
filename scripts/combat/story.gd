class_name Story
extends RefCounted

# Textos da história: abertura, final e o bestiário do Códice.

const INTRO := [
	"Houve um tempo em que treze deuses dividiam o mundo. Cada um tinha um domínio, e cada domínio tinha a cara do seu deus.",
	"Numa noite sem nome, todos sumiram. Ao mesmo tempo. Ninguém viu para onde foram.",
	"Os domínios ficaram. Sem dono, apodreceram do jeito de cada um: a cinza ficou sagrada, o inverno não acabou, a forja não parou, os mortos esqueceram o próprio nome, o sonho virou pesadelo.",
	"Você acordou na beira do Mar de Cinzas, com um manto que não lembra de ter vestido. A Vigia te chama de Moksha e diz que você já esteve aqui antes. Muitas vezes.",
	"Em algum lugar, no fim de tudo, está o Trono. Quem senta nele sabe o que aconteceu com os deuses.",
]

const ENDING := [
	"O Imperador Cego caiu. Pela primeira vez em mil anos, o Trono ficou vazio.",
	"Você se senta. Por um instante, vê o que ele via: doze deuses, de mãos dadas, entrando numa porta de luz.",
	"O décimo terceiro não entrou. O que se escondia viu tudo do fundo da terra e não contou a ninguém.",
	"Não foram embora. Foram dormir. E o sonho deles é este mundo: cada domínio, um pesadelo de quem sonha.",
	"Atrás da porta, uma voz que não é de deus nenhum: \"Ainda não. Volte quando a brasa queimar mais.\"",
	"A Vigia te encontra de novo na beira do Mar de Cinzas. \"Você de novo. Ou outro igual a você.\"",
]

# Só com as quatro brasas acesas: antes da sala das cadeiras.
const TRUE_ENDING := [
	"Com todas as brasas acesas, a porta não resiste. Do outro lado não há luz nem deus dormindo.",
	"O Imperador nunca viu nada. Arrancou os olhos para preferir outra história.",
	"Só há treze cadeiras. Em quase todas, uma brasa que não consegue apagar. Na última, alguém gravou o seu nome. Faz muito tempo.",
]

# O que cada brasa revela: o guardião que você matou era o próprio deus. A das Cavernas está fria.
const SEATS := {
	"saloes": "Dentro da brasa, um uivo. Você conhece esse uivo. O Lobo não guardava a porta do dono. Era o dono, esperando.",
	"forja_rubra": "Dentro da brasa, uma marreta. O Colosso não era o que o deus esqueceu ligado. Era o deus, que não sabia parar.",
	"necropole": "O Rei Esquecido lembrava de todos os mortos, menos de si mesmo. Ele era o deus que guardava os nomes. O seu foi o último que ele perdeu.",
	"torre_babel": "O Arquiteto era mudo porque já tinha dito todas as palavras. Era o deus das línguas. Você nunca perguntou nada a ele.",
	"jardim_primordial": "A pedra avisou: não sumiu, virou raiz. Você cortou a Mãe-Raiz mesmo assim. Ela lembra. Agora pode esquecer.",
	"catedral": "Ninguém respondia às preces, então ele virou a resposta. Não veio outro. O Que Responde sempre foi ele.",
	"carcosa": "Não havia nada embaixo da máscara do Rei sem Rosto porque o deus era a máscara.",
	"observatorio": "O Último Astrônomo contou as estrelas até acabarem. Era o próprio deus contando. Você foi a última conta.",
	"ventre": "O Insaciável ficou com fome dos irmãos e comeu o próprio domínio. Você o abriu por dentro. A fome se deita.",
	"penhascos": "O Dragão foi sonhado para ninguém acordar quem sonhava. Mas só sobrou o sonho. Você matou tudo o que restava dele.",
	"bosque": "A Raposa não ia na frente do deus. A Raposa era o deus, ainda andando. Chegou.",
	"cavernas": "Esta nunca teve brasa. A Serpe guardava a porta de um buraco vazio. O deus que se escondia não desceu. Então onde ele está?",
}

# Ao sentar na cadeira do deus que ardeu: a virada.
const REVEAL := [
	"Você senta, e a cadeira te serve. Aqui ardeu um deus, e ninguém sabe qual. Foi você.",
	"Os treze apodreciam sem conseguir morrer. Você foi o primeiro a entender, e ateou fogo em si mesmo para virar cinza. A cinza esquece. Quem lembra não consegue matar os próprios irmãos.",
	"Você pediu a uma só pessoa que te refizesse, quantas vezes fosse preciso, e que nunca contasse. Ele sabia. E não contou a ninguém.",
	"Atrás de você, uma voz que você conhece. \"Você de novo.\" A Serpe guardava um buraco vazio. O deus que se escondia se escondeu onde todo mundo olhava: debaixo do capuz da Vigia.",
	"Ela encheu seus frascos. Vendeu suas armas. Guardou a essência de cada irmão que você matou, e te refez da cinza a cada morte. \"Ou outro igual a você.\" Eram todos você.",
	"Ela se senta na cadeira fria, e a brasa dela acende. \"Foi o trato. Você apaga a última. Sozinha eu não consigo.\"",
]

# Ao apagar a brasa da Vigia: o desfecho dos deuses.
const FINAL := [
	"Moksha não é o seu nome. É a palavra que você pediu para ouvir a cada volta, até entender: soltar.",
	"A última brasa se apaga na sua mão. Por baixo do capuz havia um rosto, afinal. Parecia descansado.",
	"Os doze não voltam. Ninguém mais sonha este mundo, e ele continua aqui. Fazia tempo que não precisava de deuses.",
	"Amanhece no Mar de Cinzas. O gelo pinga, as bigornas param, os mortos lembram os próprios nomes.",
	"Resta uma brasa: a sua. Não há mais ninguém para apagá-la. O manto da Vigia ficou de pé na beira do mar, e serve em você.",
]

# Novo Jogo+: os pesadelos não souberam que acabou.
const PLUS_INTRO := [
	"Os doze descansam. Os pesadelos que eles sonhavam não souberam: continuam nos domínios, sonhando sozinhos.",
	"Você veste o manto e volta. É o último deus, e ninguém mais vai fazer esse trabalho.",
]

const PLUS_ENDING := [
	"O Imperador cai de novo. Não era ele: era o pesadelo de um trono que ninguém mais quer.",
	"Em algum domínio, nesta noite, ninguém sonhou nada. Ainda há o que soltar.",
]

# Novo Jogo+: como cada domínio ficou depois que o deus dele descansou.
const AFTER := {
	"mar_de_cinzas": "A cinza já não fala. Os sacerdotes acham que é castigo. Os médicos dão alta.",
	"saloes": "Alguém tirou a mesa. Os pratos estão lavados, e o gelo pinga.",
	"forja_rubra": "As bigornas estão frias. O que ainda bate aqui é pesadelo, e não sabe fazer nada.",
	"necropole": "As lápides têm nome de novo. O que anda por aqui não é morto de ninguém.",
	"torre_babel": "Os escribas leram o original. Era uma lista de nomes. Pararam de copiar.",
	"jardim_primordial": "A raiz secou sem dor. Nasceu uma coisa pequena em cima dela, sem nome.",
	"catedral": "A água baixou até o joelho. No fundo, o que respondia ainda responde, para ninguém.",
	"carcosa": "Alguém tirou a máscara e não sumiu. Os outros ainda não acreditam.",
	"observatorio": "O caderno de bordo ganhou uma linha nova: JÁ PODE PARAR DE CONTAR.",
	"ventre": "As paredes pararam de respirar. Os parasitas ainda não perceberam.",
	"penhascos": "A nuvem se mexeu. O que corre aqui é o resto de um sonho que ninguém sonha.",
	"cavernas": "A porta do fundo está aberta. Lá embaixo nunca houve ninguém.",
	"bosque": "As placas agora apontam para um lado só. Os andarilhos estão pensando.",
}

# Depois do final verdadeiro: só o manto da Vigia ficou.
const KEEPER_AWAKE := [
	"O MANTO DELA AINDA VIGIA. NÃO TEM NINGUÉM DENTRO.",
	"NINGUÉM AQUI. SÓ O MANTO, E O HÁBITO DE VENDER.",
	"A ESSÊNCIA AGORA É SUA. O MANTO SÓ GUARDA.",
]

const BESTIARY := {
	"PENITENTE": "Peregrinos que juraram carregar a culpa do mundo. A clava é a culpa.",
	"GUARDA DA CASA": "Soldados das Casas do Mar de Cinzas. O escudo protege a frente; as costas, ninguém.",
	"PEREGRINO CINZENTO": "Vem para arder. Acredita que quem queima vira parte do deus.",
	"ASSASSINO DA DUNA": "Nada sob a cinza. O volume que se mexe no chão é ele.",
	"ATIRADOR DE VIDRO": "Atira lascas de fulgurante. A mira trava um instante antes do disparo.",
	"INQUISIDOR PROFETA": "Julga em nome de um deus que não responde mais. Salta e cai onde você está.",
	"LOBO PÁLIDO": "Guarda a porta de um dono que não volta. Abaixa antes do bote.",
	"SENTINELA DE GELO": "Foi gente. O gelo não lembra quem. Atira em leque.",
	"FERREIRO CATIVO": "Esqueceu o próprio nome; lembra só a medida certa do aço.",
	"ESCÓRIA VIVA": "O metal que não quis virar arma. Pula, queima e vira poça.",
	"GÁRGULA": "Guardas que viraram pedra esperando a ordem de parar. Mergulham em diagonal.",
	"ESCRIBA MUDO": "Copia o mesmo livro há mil anos. O glifo que escreve te persegue.",
	"FERA-MUSGO": "Não come. Só cresce por cima do que encontra. Investe em linha reta.",
	"ESPINHEIRO": "Aponta sempre para quem respira. Abre a flor antes de atirar.",
	"MASCARADO": "Em Carcosa todos usam máscara. Este some e aparece atrás de você.",
	"ARAUTO PÁLIDO": "Anuncia um rei que nunca chega. O sino chama almas que explodem.",
	"AUTÔMATO ASTRAL": "Mede o céu para ninguém. O olho acende antes do raio.",
	"ESTRELA CAÍDA": "Um nome que o deus esqueceu. Pisca antes de explodir.",
	"PEDREIRO DA TORRE": "Ainda sobe a Torre tijolo por tijolo. De longe atira o tijolo em arco; de perto, bate com ele.",
	"BROTO ESPINHENTO": "Finca as raízes perto de quem respira e incha. Bata antes que estoure.",
	"DANÇARINO AMARELO": "Gira no lugar e atravessa a sala num rodopio. Depois fica tonto.",
	"LENTE VIVA": "Um olho de vidro que mira de qualquer ângulo. Quando o fio fica vermelho, saia da linha.",
	"CAÇADOR DO INVERNO": "Elite dos Salões. Lanças de gelo e uma investida certeira.",
	"MESTRE-FERREIRO": "Elite da Forja. A martelada solta ondas pelo chão.",
	"BIBLIOTECÁRIO CEGO": "Elite da Torre. Lê os livros com os dedos e escreve glifos que perseguem.",
	"GUARDIÃ DE ESPINHOS": "Elite do Jardim. Faz o chão crescer contra você.",
	"DUELISTA AMARELO": "Elite de Carcosa. Rápido, some, aparece, corta.",
	"SENTINELA DE LATÃO": "Elite do Observatório. Raios e estrelas em volta.",
	"O LOBO DA LONGA NOITE": "Guardião dos Salões. Uiva e a matilha responde.",
	"O COLOSSO DA BIGORNA": "Guardião da Forja. O ferreiro que o deus esqueceu ligado.",
	"O ARQUITETO MUDO": "Guardião da Torre. Ergueu a torre e esqueceu a própria língua.",
	"A MÃE-RAIZ": "Guardiã do Jardim. Tudo que cresce aqui nasceu dela.",
	"O REI SEM ROSTO": "Guardião de Carcosa. A máscara caiu; não havia nada embaixo.",
	"O ÚLTIMO ASTRÔNOMO": "Guardião do Observatório. Contou as estrelas até elas acabarem.",
	"O IMPERADOR CEGO": "Arrancou os olhos para ver o futuro. Senta no Trono há mil anos.",
	"CARPIDEIRA": "Chora por todos os mortos da Necrópole. Não lembra por quem. Mergulha, e depois do mergulho vem o lamento.",
	"MORTO DESPERTO": "Dorme na própria cova até ouvir passos. Matar uma vez não basta: ele volta para a terra e levanta de novo.",
	"FOME DAS COVAS": "O gato-sombra que come as oferendas. Nunca dá um bote só.",
	"AFOGADO": "Desceu rezando e não quis subir. A pancada faz a água subir um pouco adiante.",
	"CAVALEIRO VOTIVO": "Jurou guardar a nave da Catedral. De longe, atropela de escudo. As costas continuam abertas.",
	"PRECE VIVA": "Uma prece que ficou boiando e aprendeu a mirar. Junto do choque saem duas luzes que seguem você.",
	"TENTÁCULO FAMINTO": "Raiz de carne do Ventre. De longe cospe dentes; de perto, varre os dois lados.",
	"LARVA DO VENTRE": "Pula atrás de você e queima com ácido. Cortada, vira duas e uma poça.",
	"ILUSÃO": "Uma cauda fingindo ser a Raposa. Pisca, e um golpe desfaz.",
	"PARASITA": "Uma das últimas coisas que o deus engoliu. Se o bote pega, gruda e suga. Role para soltar.",
	"PESADELO": "Corre por cima de quem dorme. Onde ele passa, o chão queima logo depois.",
	"ÍNCUBO": "Some duas vezes seguidas, e o lugar de onde saiu estoura.",
	"SONÂMBULA": "Atira dormindo, e não para de andar. Três flechas de cada vez.",
	"LAGARTO CEGO": "Nunca viu a luz. Só sabe de quem se mexe. Parado, você não existe; andando, a língua alcança longe.",
	"SERPENTE DA FENDA": "Mora na fenda do chão. Antes de voltar para lá, cospe veneno em arco.",
	"ESCAVADOR": "Cava atrás do deus escondido há tanto tempo que esqueceu por quê. Joga bomba de longe e se acende de perto.",
	"SALTEADOR": "Cobra a passagem na estrada do Bosque. O corte leva ouro e ele foge. Quem alcança pega de volta.",
	"ANDARILHO PERDIDO": "Seguiu o deus que caminhava e esqueceu a volta. Três golpes, e esquece o que estava fazendo.",
	"SAPO-HOMEM": "Anda aos saltos, e a queda bate no chão em volta. De longe, cospe pedra.",
	"CHAMADOR DE NOMES": "Elite da Necrópole. Lê o nome dos mortos em voz alta, e eles levantam.",
	"SACERDOTISA AFOGADA": "Elite da Catedral. Ainda reza a missa; a água obedece.",
	"GLUTÃO": "Elite do Ventre. O primeiro que o deus engoliu. Ficou lá dentro, comendo.",
	"LÂMINA DO DEVANEIO": "Elite dos Penhascos. Ela sonha que luta, e você está no sonho dela.",
	"EREMITA DA FENDA": "Elite das Cavernas. Desceu atrás do deus e não quis mais subir.",
	"TOURO DA ESTRADA": "Elite do Bosque. Cobra pedágio de quem passa. Ninguém tem com que pagar.",
	"O REI ESQUECIDO": "Guardião da Necrópole. Lembra de todos os mortos, menos de si mesmo. Com os mortos de pé, quase não sente.",
	"O QUE RESPONDE": "Guardião da Catedral. Alguém ouviu as preces. Não era o deus. Bata demais ou beba o frasco, e ele responde.",
	"O INSACIÁVEL": "Guardião do Ventre. O deus que devorava comeu até a própria fome. Inspira, puxa, e larva na boca vira vida.",
	"O DRAGÃO SONHADO": "Guardião dos Penhascos. O deus sonhou um guarda para não ser acordado. Some do mundo e cai do alto.",
	"A SERPE DO FUNDO": "Guardiã das Cavernas. Deixada na porta para ninguém descer mais. Cava atrás de você e sai numa coluna de pedra.",
	"A RAPOSA DE NOVE CAUDAS": "Guardiã do Bosque. Ia sempre na frente do deus que caminhava. Ainda vai.",
}


static func ending_pages(heat: int) -> PackedStringArray:
	if heat < 4:
		return PackedStringArray(ENDING)
	# com as quatro brasas a porta abre: "ainda não" e a volta à Vigia ficam de fora
	var pages := PackedStringArray(ENDING.slice(0, 4))
	pages.append_array(TRUE_ENDING)
	return pages


# Nome de um dos treze a partir do domínio: "O DEUS QUE ARDEU".
static func god_name(biome_id: String) -> String:
	return Catalog.biome(biome_id).subtitle.replace("Domínio do deus", "O deus").to_upper()
