extends Node

# Qualidade gráfica em três níveis (BAIXA, MÉDIA, ALTA). A tabela diz o que cada
# efeito faz em cada nível; quem desenha pergunta aqui em vez de decidir sozinho:
#
#   if Graficos.on("mato"): ...          Graficos.num("claroes")
#
# O jogador escolhe em Opções > Tela > QUALIDADE. Em AUTO o jogo começa no nível
# mais alto e desce sozinho quando não segura os quadros (medido em janelas de
# alguns segundos, fora de pausa e de troca de fase); o nível achado fica salvo.
#
# "EFEITOS DE TELA" desligado (Options "postfx") continua mandando: apaga tudo o
# que está em POSTFX, em qualquer nível.

signal changed

const BAIXO := 0
const MEDIO := 1
const ALTO := 2
const NAMES := ["baixo", "medio", "alto"]
const LABELS := ["BAIXA", "MÉDIA", "ALTA"]
const CHOICES := ["auto", "baixo", "medio", "alto"]

const TABLE := {
	# efeito: [baixa, média, alta]
	# em quantos pixels reais cada pixel do jogo é desenhado no navegador (0 = todos os
	# da tela). É o que mais pesa em vídeo integrado: a 1080p, 2 dá um quarto dos pixels.
	"escala": [1, 2, 0],
	"brilho": [false, true, true],           # bloom do que emite luz
	"claroes": [2, 5, 8],                    # luzes de impacto acesas ao mesmo tempo
	"luz_moedas": [false, false, true],      # essência e moeda acendem o chão (senão, só o halo)
	"luz_contorno": [false, true, true],     # segunda luz direcional, do lado oposto à do domínio
	"contorno_luz": [false, true, true],     # linha de luz de 1 pixel na borda dos personagens
	"parede": [true, true, true],            # parede de fundo perto da pedra
	"parede_luz": [false, true, true],       # a parede recebe luz e relevo (senão, só a penumbra)
	"oclusao": [false, true, true],          # a parede escurece no encontro com os blocos
	"aderecos": [true, true, true],          # enfeites do cenário com arte (senão, o traço antigo)
	"vento": [false, true, true],            # o que está pendurado balança
	"halos": [false, true, true],            # halo nas velas, lanternas e fornalhas do cenário
	"primeiro_plano": [true, true, true],    # silhuetas da frente feitas da pedra do domínio (senão, blocos chapados)
	"poeira_frente": [0, 8, 14],             # discos de poeira fora de foco na frente da câmera
	"especular": [false, true, true],        # reflexo da luz no gelo, na pedra molhada, no metal e na carne
	"nuvens": [false, true, true],           # sombra de nuvens no chão
	"sombra_tochas": [false, true, true],
	"reflexo": [false, true, true],          # chão molhado
	"pocas": [false, true, true],
	"mato": [1, 2, 2],                       # 0 = sem; 1 = só a camada de trás; 2 = as duas
	"ar": [30, 70, 70],                      # partículas do ar de cada domínio
}
# o que "efeitos de tela" desligado apaga, seja qual for o nível
const POSTFX := ["brilho", "claroes", "luz_moedas", "nuvens", "sombra_tochas", "reflexo", "pocas", "mato", "poeira_frente", "halos"]

const WINDOW := 4.0          # s de jogo por medição
const SLOW_FPS := 50.0       # abaixo disso a janela conta como lenta
const SLOW_WINDOWS := 2      # janelas lentas seguidas para descer um nível
const GRACE := 3.0           # s sem medir depois de trocar de fase ou de nível

var choice := "auto"
var _level := ALTO
var _acc := 0.0
var _frames := 0
var _slow := 0
var _grace := GRACE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Options.changed.connect(_read)
	_read()


func level() -> int:
	return _level


func value(key: String) -> Variant:
	return TABLE[key][_level]


func on(key: String) -> bool:
	if POSTFX.has(key) and not Options.get_value("postfx"):
		return false
	var v: Variant = TABLE[key][_level]
	if v is bool:
		return v
	return float(v) > 0.0


func num(key: String) -> float:
	if POSTFX.has(key) and not Options.get_value("postfx"):
		return 0.0
	return float(TABLE[key][_level])


# O que aparece na linha QUALIDADE das opções.
func label() -> String:
	return "AUTO (%s)" % LABELS[_level] if choice == "auto" else LABELS[_level]


func choose(next: String) -> void:
	Options.set_value("quality", next if CHOICES.has(next) else "auto")


# Troca de fase: os primeiros segundos têm carga e compilação de shader.
func hold(seconds := GRACE) -> void:
	_grace = maxf(_grace, seconds)
	_acc = 0.0
	_frames = 0


func _read() -> void:
	var want := String(Options.get_value("quality"))
	if not CHOICES.has(want):
		want = "auto"
	var lv := NAMES.find(want)
	if lv < 0:
		# auto: recomeça do nível que esta máquina aguentou da última vez
		lv = NAMES.find(String(Options.get_value("quality_auto")))
		if lv < 0:
			lv = ALTO
	var same := want == choice and lv == _level
	choice = want
	_level = lv
	_slow = 0
	hold()
	_apply()
	if not same:
		changed.emit()


func _apply() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.mokshaRenderScale && window.mokshaRenderScale(%d)" % int(value("escala")), true)


func _process(delta: float) -> void:
	if choice != "auto" or _level == BAIXO or get_tree().paused:
		return
	# aba em segundo plano ou engasgo de carga não é falta de fôlego
	if delta > 0.25:
		hold(1.0)
		return
	if _grace > 0.0:
		_grace -= delta
		return
	_acc += delta
	_frames += 1
	if _acc < WINDOW:
		return
	var fps := _frames / _acc
	_acc = 0.0
	_frames = 0
	_slow = _slow + 1 if fps < SLOW_FPS else 0
	if _slow >= SLOW_WINDOWS:
		_step_down()


func _step_down() -> void:
	_level = maxi(_level - 1, BAIXO)
	_slow = 0
	hold()
	# guarda sem passar por Options.set_value: ele reaplicaria tudo e chamaria _read de novo
	Options.data["quality_auto"] = NAMES[_level]
	Meta.data["options"] = Options.data.duplicate(true)
	Meta.save()
	_apply()
	changed.emit()
