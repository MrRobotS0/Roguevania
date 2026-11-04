class_name Story
extends RefCounted

# Textos da história: abertura, final e o bestiário do Códice.

const INTRO := [
	"Houve um tempo em que sete deuses dividiam o mundo. Cada um tinha um domínio, e cada domínio tinha a cara do seu deus.",
	"Numa noite sem nome, todos sumiram. Ao mesmo tempo. Ninguém viu para onde foram.",
	"Os domínios ficaram. Sem dono, apodreceram do jeito de cada um: a cinza ficou sagrada, o inverno não acabou, a forja não parou.",
	"Você acordou na beira do Mar de Cinzas, com um manto que não lembra de ter vestido. A Vigia te chama de Moksha e diz que você já esteve aqui antes. Muitas vezes.",
	"Em algum lugar, no fim de tudo, está o Trono. Quem senta nele sabe o que aconteceu com os deuses.",
]

const ENDING := [
	"O Imperador Cego caiu. Pela primeira vez em mil anos, o Trono ficou vazio.",
	"Você se senta. Por um instante, vê o que ele via: sete deuses, de mãos dadas, entrando numa porta de luz.",
	"Não foram embora. Foram dormir. E o sonho deles é este mundo: cada domínio, um pesadelo de quem sonha.",
	"Atrás da porta, uma voz que não é de deus nenhum: \"Ainda não. Volte quando a brasa queimar mais.\"",
	"A Vigia te encontra de novo na beira do Mar de Cinzas. \"Você de novo. Ou outro igual a você.\"",
]

# Só com as quatro brasas acesas.
const TRUE_ENDING := [
	"Com todas as brasas acesas, a porta não resiste. Do outro lado, sete cadeiras vazias.",
	"E uma oitava, menor, de frente para as outras. Na madeira, alguém gravou o seu nome. Faz muito tempo.",
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
}


static func ending_pages(heat: int) -> PackedStringArray:
	var pages := PackedStringArray(ENDING)
	if heat >= 4:
		pages.append_array(TRUE_ENDING)
	return pages
