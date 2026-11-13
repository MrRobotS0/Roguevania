class_name PostFx
extends ColorRect

# Pós-processamento da tela (entre o mundo e o HUD), num shader só:
# - gradação de cor por domínio: sombras puxadas para a cor do céu, luzes para
#   a cor do sol, contraste e saturação um pouco acima (a pixel art "acende");
# - aberração cromática que pulsa nos golpes fortes e quando o herói apanha;
# - ondas de choque (distorção em anel) na morte de elite/chefe e nos críticos;
# - meia-luz animada: um véu de luz quente que respira bem devagar;
# - pontilhado ordenado (Bayer 4x4) de 1/255 para não formar degraus no degradê.
# Opções > Tela > EFEITOS DE TELA desliga tudo.

const SHADER := """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 shadow_tint = vec3(0.10, 0.08, 0.12);
uniform vec3 light_tint = vec3(1.0, 0.95, 0.85);
uniform float grade = 1.0;
uniform float contrast = 1.12;
uniform float saturation = 1.16;
uniform float aberration = 0.0;      // em pixels da tela do jogo
uniform vec2 px_size = vec2(0.00208, 0.0037);
uniform vec4 wave0 = vec4(0.5, 0.5, -1.0, 0.0);   // centro (uv), raio (uv no eixo y), força
uniform vec4 wave1 = vec4(0.5, 0.5, -1.0, 0.0);
uniform float aspect = 1.7778;
uniform float time = 0.0;
uniform float breathe = 0.0;

vec2 wave_offset(vec2 uv, vec4 w) {
	if (w.z < 0.0 || w.w <= 0.0) {
		return vec2(0.0);
	}
	vec2 d = uv - w.xy;
	d.x *= aspect;
	float dist = length(d);
	float ring = 1.0 - smoothstep(0.0, 0.045, abs(dist - w.z));
	if (dist < 0.0001) {
		return vec2(0.0);
	}
	vec2 dir = d / dist;
	dir.x /= aspect;
	return dir * ring * w.w;
}

float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[i]) / 16.0 - 0.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	uv -= wave_offset(uv, wave0);
	uv -= wave_offset(uv, wave1);
	vec3 c;
	if (aberration > 0.01) {
		vec2 from_center = uv - vec2(0.5);
		vec2 shift = from_center * aberration * px_size * 2.0;
		c.r = texture(screen_tex, uv + shift).r;
		c.g = texture(screen_tex, uv).g;
		c.b = texture(screen_tex, uv - shift).b;
	} else {
		c = texture(screen_tex, uv).rgb;
	}
	vec3 base = c;
	// contraste em torno do meio-tom, saturação pela luminância
	c = (c - 0.5) * contrast + 0.5;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	// tons divididos: sombra puxa para o céu, luz para o sol
	float k = smoothstep(0.0, 1.0, l);
	c += shadow_tint * (1.0 - k) * 0.32;
	c *= mix(vec3(1.0), light_tint, k * 0.45);
	// respiração: luz quente bem lenta vinda de cima
	float glow = (1.0 - SCREEN_UV.y) * (0.5 + 0.5 * sin(time * 0.35)) * breathe;
	c += light_tint * glow * 0.035;
	c = mix(base, c, grade);
	c += bayer(FRAGCOORD.xy) / 255.0;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""

const WAVE_TIME := 0.55

var _mat: ShaderMaterial
var _waves: Array = []     # [centro na tela, idade, força]
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := Shader.new()
	s.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = s
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


func _on_wave(world_pos: Vector2, strength: float) -> void:
	if _waves.size() >= 2:
		_waves.pop_front()
	var screen := get_viewport().get_canvas_transform() * world_pos
	_waves.append([screen, 0.0, strength])


func _process(delta: float) -> void:
	var on := bool(Options.get_value("postfx"))
	visible = on
	if not on:
		_waves.clear()
		Fx.aberration = 0.0
		return
	_t += delta
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	_mat.set_shader_parameter("px_size", Vector2(1.0 / maxf(vp.x, 1.0), 1.0 / maxf(vp.y, 1.0)))
	_mat.set_shader_parameter("aspect", vp.x / maxf(vp.y, 1.0))
	_mat.set_shader_parameter("time", _t)
	_mat.set_shader_parameter("breathe", 1.0)
	Fx.aberration = maxf(Fx.aberration - delta * 9.0, 0.0)
	var ab := Fx.aberration + Fx.pain * 1.5
	_mat.set_shader_parameter("aberration", ab if Options.flashes() else ab * 0.3)
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
