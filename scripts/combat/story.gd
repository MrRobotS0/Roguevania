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

# Só com as quatro brasas acesas.
const TRUE_ENDING := [
	"Com todas as brasas acesas, a porta não resiste. Do outro lado, treze cadeiras vazias.",
	"E uma décima quarta, menor, de frente para as outras. Na madeira, alguém gravou o seu nome. Faz muito tempo.",
	"Você entende, enfim, por que a Vigia sempre te reconhece. Você não chegou depois dos deuses. Você é o que eles deixaram para trás.",
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
	var pages := PackedStringArray(ENDING)
	if heat >= 4:
		pages.append_array(TRUE_ENDING)
	return pages
