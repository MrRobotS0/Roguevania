class_name PostFx
extends ColorRect

# Pós-processamento da tela (entre o mundo e o HUD), num shader só:
# - gradação de cor por domínio: sombras puxadas para a cor do céu, luzes para
#   a cor do sol, contraste e saturação um pouco acima (a pixel art "acende");
# - aberração cromática: um pulso curto nos golpes fortes e quando o herói apanha
#   (no máximo 1,4 pixel do jogo na borda; antes passava de 3 e durava a dor inteira);
# - quadro de impacto (Fx.impact_until) e a morte do herói (Player.dying);
# - ondas de choque (distorção em anel) na morte de elite/chefe e nos críticos;
# - meia-luz animada: um véu de luz quente que respira bem devagar;
# - pontilhado ordenado (Bayer 4x4) de 1/255 para não formar degraus no degradê.
# - ar quente sobre os braseiros (grupo "calor"): as linhas da tela escorregam de 1 em
#   1 pixel do jogo numa coluna acima da chama; só os dois fogos mais perto do centro;
# - filtro da loja (Cosmetics.FILTERS): gradação de cor da tela inteira.
# Opções > Tela > EFEITOS DE TELA desliga tudo, menos o filtro que o jogador escolheu.

const SHADER := preload("res://shaders/pos_processo.gdshader")

const WAVE_TIME := 0.55
const HEAT_RADIUS := 26.0     # px do jogo: meia largura da coluna de ar quente
const HEAT_FORCE := 0.9       # px do jogo de desvio no pico
const ABERRATION := 0.45      # quanto do pedido de Fx.kick vira desvio de cor
const IMPACT := 0.72          # quanto da tela o quadro de impacto toma

var _mat: ShaderMaterial
var _waves: Array = []     # [centro na tela, idade, força]
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	Fx.wave_requested.connect(_on_wave)
	use_sky({})


# Cores do domínio: a sombra vem do céu mais escuro, a luz do sol.
func use_sky(sky: Dictionary) -> void:
	var dark: Color = sky.get("sky0", Color(0.1, 0.08, 0.12))
	var sun: Color = sky.get("sun", Color(1.0, 0.95, 0.85))
	# sombra: só a cor, sem o brilho (senão o preto vira cinza)
	var d := Vector3(dark.r, dark.g, dark.b)
	var top := maxf(maxf(d.x, d.y), maxf(d.z, 0.001))
	d = d / top * 0.12
	_mat.set_shader_parameter("shadow_tint", d)
	var lt := Color(sun.r, sun.g, sun.b).lerp(Color.WHITE, 0.55)
	_mat.set_shader_parameter("light_tint", Vector3(lt.r, lt.g, lt.b))


# A curva e a saturação do domínio (Depth.TOM).
func use_tone(gamma: float, saturation: float) -> void:
	_mat.set_shader_parameter("gamma", gamma)
	_mat.set_shader_parameter("saturation", saturation)


# Os dois fogos na tela mais perto do centro viram colunas de ar quente.
func _heat(vp: Vector2) -> void:
	var fires: Array[Vector2] = []
	if Graficos.on("calor"):
		var view := get_viewport().get_canvas_transform()
		for n in get_tree().get_nodes_in_group("calor"):
			var at: Vector2 = view * ((n as Node2D).global_position + Vector2(0, -16))
			if at.x > -30.0 and at.x < vp.x + 30.0 and at.y > 0.0 and at.y < vp.y + 50.0:
				fires.append(at)
		var middle := vp * 0.5
		fires.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(middle) < b.distance_squared_to(middle))
	for i in 2:
		var h := Vector4(0.5, 0.5, 0.0, 0.0)
		if i < fires.size():
			h = Vector4(fires[i].x / vp.x, fires[i].y / vp.y, HEAT_RADIUS / vp.y, HEAT_FORCE)
		_mat.set_shader_parameter("heat%d" % i, h)


func _on_wave(world_pos: Vector2, strength: float) -> void:
	if _waves.size() >= 2:
		_waves.pop_front()
	var screen := get_viewport().get_canvas_transform() * world_pos
	_waves.append([screen, 0.0, strength])


func _process(delta: float) -> void:
	var on := bool(Options.get_value("postfx"))
	var mode := Cosmetics.filter_mode()
	_mat.set_shader_parameter("filter_mode", mode)
	visible = on or mode > 0
	if not on:
		_waves.clear()
		Fx.aberration = 0.0
		if mode > 0:
			# só o filtro: sem gradação, aberração, ondas ou respiração
			size = get_viewport_rect().size
			_mat.set_shader_parameter("grade", 0.0)
			_mat.set_shader_parameter("aberration", 0.0)
			_mat.set_shader_parameter("breathe", 0.0)
			_mat.set_shader_parameter("wave0", Vector4(0.5, 0.5, -1.0, 0.0))
			_mat.set_shader_parameter("wave1", Vector4(0.5, 0.5, -1.0, 0.0))
			_mat.set_shader_parameter("heat0", Vector4(0.5, 0.5, 0.0, 0.0))
			_mat.set_shader_parameter("heat1", Vector4(0.5, 0.5, 0.0, 0.0))
			_mat.set_shader_parameter("impact", 0.0)
			_mat.set_shader_parameter("death", 0.0)
		return
	_mat.set_shader_parameter("grade", 1.0)
	_t += delta
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	_mat.set_shader_parameter("px_size", Vector2(1.0 / maxf(vp.x, 1.0), 1.0 / maxf(vp.y, 1.0)))
	_mat.set_shader_parameter("aspect", vp.x / maxf(vp.y, 1.0))
	_mat.set_shader_parameter("time", _t)
	_mat.set_shader_parameter("breathe", 1.0)
	Fx.aberration = maxf(Fx.aberration - delta * 9.0, 0.0)
	var ab := Fx.aberration * ABERRATION
	_mat.set_shader_parameter("aberration", ab if Options.flashes() else ab * 0.3)
	_heat(vp)
	# relógio de parede: durante a parada do golpe o tempo do jogo quase não anda
	var hit := Fx.impact_until > Time.get_ticks_msec() / 1000.0 and Graficos.on("quadro_impacto")
	_mat.set_shader_parameter("impact", IMPACT if hit else 0.0)
	var dying := 0.0
	var hero := get_tree().get_first_node_in_group("player") as Player
	if hero and Graficos.on("morte"):
		dying = hero.dying()
		if dying > 0.0:
			var at: Vector2 = get_viewport().get_canvas_transform() * hero.center()
			_mat.set_shader_parameter("death_at", Vector2(at.x / vp.x, at.y / vp.y))
	_mat.set_shader_parameter("death", dying)
	for w in _waves:
		w[1] += delta
	_waves = _waves.filter(func(w: Array) -> bool: return w[1] < WAVE_TIME)
	for i in 2:
		var key := "wave%d" % i
		if i < _waves.size():
			var w: Array = _waves[i]
			var k: float = w[1] / WAVE_TIME
			var c: Vector2 = w[0]
			var radius := k * 0.45
			var force: float = w[2] * (1.0 - k) * (1.0 - k) * 0.012
			_mat.set_shader_parameter(key, Vector4(c.x / vp.x, c.y / vp.y, radius, force))
		else:
			_mat.set_shader_parameter(key, Vector4(0.5, 0.5, -1.0, 0.0))
