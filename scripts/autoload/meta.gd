extends Node

# Progresso permanente (sobrevive à morte): o que foi desbloqueado e as
# estatísticas. Fica em user://legado.save (pasta de dados do Godot).
# Testes trocam o caminho com use_path() — nunca escrevem no save real.
#
# No navegador (moksha.com.br) o legado mora na conta do jogador: carrega de
# /api/save ao abrir e cada save() manda uma cópia para lá. O arquivo local vira
# só um cache. O progresso que já estava neste navegador antes das contas é
# levado para a primeira conta que entrar nele, uma vez só.

const DEFAULT_PATH := "user://legado.save"
const CLOUD_CACHE := "user://legado-conta.save"
const ACCOUNT_PAGE := "/conta.html?volta=/jogar/"

var path := DEFAULT_PATH
var data := {}
var cloud := false          # salvando na conta (só no navegador, com o save real)
var player_name := ""       # nome do personagem criado no site
var _rev := 0               # cada envio leva um número maior; o servidor ignora o que chegar atrasado
var _offline := false       # não leu a conta: não manda nada, para não sobrescrever o legado de verdade


signal account_changed     # entrou, saiu ou o legado veio da conta (o título se redesenha)


func _ready() -> void:
	_load()
	_desk_start()


func use_path(p: String, wipe := false) -> void:
	path = p
	if wipe and FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_load()


func _defaults() -> Dictionary:
	return {"unlocked": [], "runs": 0, "wins": 0, "best_kills": 0, "deaths": 0, "skin": "andarilho",
		"blueprints": [], "runes": [], "heat": 0,
		"stats": {}, "daily": {}, "weekly": {}, "best_wave": 0, "best_time": 0.0, "lore": [], "intro_seen": false,
		"hints": [], "awake": false, "plus": 0,
		"feats": [], "mutations_seen": [], "pick_mutation": "", "pick_advantage": "", "pick_heat": 0, "pick_plus": 0}


func _load() -> void:
	data = _defaults()
	cloud = OS.has_feature("web") and path == DEFAULT_PATH
	if cloud:
		_load_cloud()
		return
	_merge(_read_file(path))


func save() -> void:
	if cloud:
		_save_cloud()
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
	_desk_push()


func _read_file(p: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _merge(parsed: Variant) -> void:
	if parsed is Dictionary:
		for k in parsed:
			data[k] = parsed[k]


# --- conta (navegador) ---------------------------------------------------------------

# Pedido síncrono de propósito: o resto do jogo lê Meta.data logo no _ready, e
# o pedido é pequeno e vai para o mesmo servidor que acabou de entregar o jogo.
const _JS_GET := """(function () {
	for (var i = 0; i < 3; i++) {
		try {
			var x = new XMLHttpRequest();
			x.open('GET', '/api/save', false);
			x.send();
			if (x.status) return JSON.stringify({s: x.status, b: x.responseText});
		} catch (e) {}
	}
	return JSON.stringify({s: 0, b: ''});
})()"""


func _load_cloud() -> void:
	var reply = JSON.parse_string(str(JavaScriptBridge.eval(_JS_GET, true)))
	var status := int(reply["s"]) if reply is Dictionary else 0
	if status == 401 or status == 403:
		_to_account_page()
		return
	var body = JSON.parse_string(String(reply["b"])) if status == 200 else null
	if not body is Dictionary:
		# servidor fora do ar: joga com o cache local, sem mandar nada para a conta
		_offline = true
		push_warning("Meta: não deu para ler o legado da conta (status %d)" % status)
		var cached = _read_file(CLOUD_CACHE)
		if cached is Dictionary:
			player_name = String(cached.get("nome", ""))
			_merge(cached.get("data"))
		return
	player_name = String(body.get("nome", ""))
	_rev = int(body.get("rev", 0))
	if body.get("data") is Dictionary:
		_merge(body["data"])
		_write_cache()
		return
	# conta nova: leva o progresso que este navegador tinha antes das contas
	var old = _read_file(DEFAULT_PATH)
	if old is Dictionary:
		_merge(old)
		DirAccess.rename_absolute(ProjectSettings.globalize_path(DEFAULT_PATH),
			ProjectSettings.globalize_path("user://legado-importado.save"))
		_save_cloud()


func _save_cloud() -> void:
	if _offline:
		return
	_rev += 1
	_write_cache()
	var body := JSON.stringify({"rev": _rev, "data": data})
	# keepalive deixa o envio terminar mesmo se a aba fechar, mas só aceita até 64 KB
	var js := """fetch('/api/save', {method: 'PUT', credentials: 'same-origin', keepalive: %s,
		headers: {'Content-Type': 'application/json'}, body: %s})
		.then(function (r) { if (r.status === 401 || r.status === 403) location.replace(%s); })
		.catch(function () {});""" % ["true" if body.length() < 60000 else "false",
			JSON.stringify(body), JSON.stringify(ACCOUNT_PAGE)]
	JavaScriptBridge.eval(js, true)


func _write_cache() -> void:
	var f := FileAccess.open(CLOUD_CACHE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"nome": player_name, "rev": _rev, "data": data}))


func _to_account_page() -> void:
	JavaScriptBridge.eval("location.replace(%s)" % JSON.stringify(ACCOUNT_PAGE), true)


func is_unlocked(id: String) -> bool:
	return data["unlocked"].has(id)


func has_gear(r: Resource) -> bool:
	return r.starter or is_unlocked(r.id)


func unlock(id: String) -> void:
	if not is_unlocked(id):
		data["unlocked"].append(id)
		save()


func record_run(won: bool, kills: int) -> void:
	data["runs"] += 1
	if won:
		data["wins"] += 1
	else:
		data["deaths"] += 1
	data["best_kills"] = maxi(int(data["best_kills"]), kills)
	save()


# --- aparências ---------------------------------------------------------------------

func feat_done(feat: String) -> bool:
	match feat:
		"boss":
			return int(data["wins"]) >= 1
		"deaths10":
			return int(data["deaths"]) >= 10
		"despertar":
			return awake()
	return false


func has_skin(s: SkinData) -> bool:
	match s.unlock:
		"essence":
			return is_unlocked(s.id)
		"feat":
			return feat_done(s.feat)
	return true


func current_skin() -> SkinData:
	var s := Catalog.skin(String(data["skin"]))
	return s if has_skin(s) else Catalog.skin("andarilho")


func wear(id: String, chroma := "") -> void:
	data["skin"] = id
	var picks: Dictionary = data.get("chroma", {})
	picks[id] = chroma
	data["chroma"] = picks
	save()


# Croma em uso de uma aparência ("" = cores originais).
func chroma_of(s: SkinData) -> String:
	var c := String(data.get("chroma", {}).get(s.id, ""))
	return c if has_chroma(s, c) else ""


func has_chroma(s: SkinData, chroma: String) -> bool:
	if chroma == "":
		return true
	var c := s.chroma_data(chroma)
	return not c.is_empty() and (int(c.get("cost", 0)) == 0 or is_unlocked(s.id + ":" + chroma))


# Cores do herói agora: aparência + croma.
func current_look() -> Dictionary:
	var s := current_skin()
	return s.colors(chroma_of(s))


# --- runas (poderes que ficam para sempre) e plantas -------------------------------

func has_rune(id: String) -> bool:
	return data["runes"].has(id)


func add_rune(id: String) -> void:
	if not has_rune(id):
		data["runes"].append(id)
		save()


func knows(id: String) -> bool:
	return data["blueprints"].has(id)


func learn(ids: Array) -> int:
	var fresh := 0
	for id in ids:
		if not knows(id):
			data["blueprints"].append(id)
			fresh += 1
	save()
	return fresh


# Vitória numa dificuldade libera a próxima.
func record_heat_win(level: int) -> void:
	if level + 1 > int(data["heat"]):
		data["heat"] = mini(level + 1, 4)
		save()


# Final verdadeiro: o herói sabe quem é. Libera o Novo Jogo+.
func awake() -> bool:
	return bool(data.get("awake", false))


func wake() -> void:
	data["awake"] = true
	data["plus"] = maxi(int(data.get("plus", 0)), 1)
	save()


# Vencer um ciclo libera o próximo.
func record_plus_win(level: int) -> void:
	data["plus"] = mini(maxi(int(data.get("plus", 0)), level + 1), Run.MAX_PLUS)
	save()


# --- o que se escolhe na Beira -------------------------------------------------------

# O poço lembra do que o herói já bebeu: três de graça, o resto depois de tomar num altar.
func start_mutations() -> Array:
	var out: Array = Catalog.STARTER_MUTATIONS.duplicate()
	for id: String in data["mutations_seen"]:
		if not out.has(id):
			out.append(id)
	return out


# sinergias que o jogador já viu acontecer (aparecem nas estatísticas)
func note_synergy(id: String) -> void:
	if not data.has("synergies"):
		data["synergies"] = []
	if not data["synergies"].has(id):
		data["synergies"].append(id)
		save()


func note_mutation(id: String) -> void:
	if not data["mutations_seen"].has(id):
		data["mutations_seen"].append(id)
		save()


func has_advantage(id: String) -> bool:
	var a := Catalog.advantage(id)
	if a.is_empty():
		return false
	return not a.has("needs") or feat_achieved(Catalog.feat(a["needs"]))


func pick(key: String, value: Variant) -> void:
	data[key] = value
	save()


# --- conquistas ----------------------------------------------------------------------
# Vêm do que o jogo já guarda: quem jogou antes de elas existirem não perde nada.

func feat_value(what: String) -> float:
	var st: Dictionary = data["stats"]
	match what:
		"deaths", "wins", "runs":
			return float(data[what])
		"embers":
			return float(data["heat"])
		"kills":
			var total := 0
			for v in st.get("kills_by", {}).values():
				total += int(v)
			return float(total)
		"guardians":
			var seen: Dictionary = st.get("kills_by", {})
			return float(Catalog.GUARDIANS.filter(func(t: String) -> bool: return seen.has(t)).size())
		"deepest":
			return float(st.get("deepest", 0))
		"lore":
			return float(data["lore"].size())
		"creatures":
			return float(known_creatures().size())
		"blueprints":
			return float(data["blueprints"].size())
		"runes":
			return float(data["runes"].size())
		"mutations":
			return float(data["mutations_seen"].size())
		"skins":
			return float(Catalog.skins().filter(func(s: SkinData) -> bool: return has_skin(s)).size())
		"awake":
			return 1.0 if awake() else 0.0
		"plus":
			return float(data.get("plus", 0))
		"quick":
			var best := float(data["best_time"])
			return 1.0 if best > 0.0 and best < 1800.0 else 0.0
	return 0.0


func feat_achieved(f: Dictionary) -> bool:
	return not f.is_empty() and feat_value(f["what"]) >= float(f["n"])


# A conquista que está mais perto de sair (a maior fração já feita), para o
# título e a Beira mostrarem "quase lá". Secretas ficam de fora.
func closest_feat() -> Dictionary:
	var best := {}
	var best_ratio := -1.0
	for f: Dictionary in Catalog.FEATS:
		if f.get("secret", false) or feat_achieved(f) or data["feats"].has(f["id"]):
			continue
		var ratio := feat_value(f["what"]) / maxf(float(f["n"]), 1.0)
		if ratio > best_ratio:
			best_ratio = ratio
			best = f
	return best


func closest_feat_text() -> String:
	var f := closest_feat()
	if f.is_empty():
		return ""
	var have := mini(int(feat_value(f["what"])), int(f["n"]))
	if int(f["n"]) <= 1:
		return "PRÓXIMA CONQUISTA: %s · %s" % [String(f["title"]).to_upper(), f["detail"]]
	return "PRÓXIMA CONQUISTA: %s · %d DE %d" % [String(f["title"]).to_upper(), have, int(f["n"])]


func feats_done() -> int:
	return Catalog.FEATS.filter(func(f: Dictionary) -> bool: return feat_achieved(f)).size()


# As que ficaram prontas desde a última olhada. Cada uma é contada uma vez só.
func check_feats() -> Array[Dictionary]:
	var fresh: Array[Dictionary] = []
	for f: Dictionary in Catalog.FEATS:
		if feat_achieved(f) and not data["feats"].has(f["id"]):
			data["feats"].append(f["id"])
			fresh.append(f)
	if not fresh.is_empty():
		save()
	return fresh


# --- estatísticas, recorde e desafio do dia -------------------------------------------

func _add(table: String, key: String, n: int) -> void:
	var st: Dictionary = data["stats"]
	if not st.has(table):
		st[table] = {}
	st[table][key] = int(st[table].get(key, 0)) + n


# Chamado no fim de toda partida (morte, vitória ou desistência).
func record_stats(won: bool) -> bool:
	for k in Run.kills_by:
		_add("kills_by", k, Run.kills_by[k])
	for k in Run.weapon_kills:
		_add("weapon_kills", k, Run.weapon_kills[k])
	if not won and Run.killer != "":
		_add("deaths_by", Run.killer, 1)
	_add("reached", Run.stage_id, 1)
	var st: Dictionary = data["stats"]
	st["deepest"] = maxi(int(st.get("deepest", 0)), Run.path.size())
	st["time"] = float(st.get("time", 0.0)) + Run.time
	var record := false
	if won and (float(data["best_time"]) <= 0.0 or Run.time < float(data["best_time"])):
		data["best_time"] = Run.time
		record = true
	if Run.daily != "":
		var day: Dictionary = data["daily"].get(Run.daily, {"tries": 0, "best_depth": 0, "best_time": 0.0})
		if int(day["tries"]) == 0:
			_reward_daily(Run.daily)
		day["tries"] = int(day["tries"]) + 1
		day["best_depth"] = maxi(int(day["best_depth"]), Run.path.size())
		if won and (float(day["best_time"]) <= 0.0 or Run.time < float(day["best_time"])):
			day["best_time"] = Run.time
		data["daily"][Run.daily] = day
	if Run.week != "":
		var w: Dictionary = data["weekly"].get(Run.week, {"tries": 0, "best_depth": 0, "best_time": 0.0})
		w["tries"] = int(w["tries"]) + 1
		w["best_depth"] = maxi(int(w["best_depth"]), Run.path.size())
		if won and (float(w["best_time"]) <= 0.0 or Run.time < float(w["best_time"])):
			w["best_time"] = Run.time
		data["weekly"][Run.week] = w
	if Run.mode == Run.WAVES:
		data["best_wave"] = maxi(int(data["best_wave"]), Run.wave)
	claim_codex()
	save()
	_report_run(won)
	return record


# No navegador: um resumo da partida vai para o servidor, para saber onde as
# pessoas morrem e desistem (não muda nada no jogo).
func _report_run(won: bool) -> void:
	if not cloud or _offline:
		return
	var kills := 0
	for v in Run.kills_by.values():
		kills += int(v)
	var mode := "ondas" if Run.mode == Run.WAVES else ("semana" if Run.week != "" else ("dia" if Run.daily != "" else "normal"))
	var run := {"modo": mode, "venceu": won, "andares": Run.path.size(), "onde": Run.stage_id,
		"tempo": snappedf(Run.time, 0.1), "morto_por": Run.killer, "abates": kills, "brasas": Run.heat,
		"wave": Run.wave, "caminho": Run.path, "armas": Run.weapon_kills.keys(), "versao": Updater.version}
	var js := """fetch('/api/partida', {method: 'POST', credentials: 'same-origin', keepalive: true,
		headers: {'Content-Type': 'application/json'}, body: %s}).catch(function () {});""" % JSON.stringify(JSON.stringify(run))
	JavaScriptBridge.eval(js, true)


# --- recompensa do Desafio do Dia ------------------------------------------------------
# A primeira tentativa de cada dia guarda Essência para a próxima partida normal.
# Dias seguidos aumentam a recompensa (até 7 dias).

const DAILY_BASE := 10
const DAILY_PER_DAY := 5
const DAILY_MAX_STREAK := 7


func _reward_daily(date: String) -> void:
	var last := String(data.get("daily_last", ""))
	var streak := int(data.get("daily_streak", 0))
	var gap := (Time.get_unix_time_from_datetime_string(date + "T00:00:00") -
		Time.get_unix_time_from_datetime_string(last + "T00:00:00")) if last != "" else 0
	streak = streak + 1 if last != "" and gap == 86400 else 1
	data["daily_streak"] = streak
	data["daily_last"] = date
	var gain := DAILY_BASE + DAILY_PER_DAY * (mini(streak, DAILY_MAX_STREAK) - 1)
	data["daily_bonus"] = int(data.get("daily_bonus", 0)) + gain
	Fx.toast.call_deferred("DESAFIO DO DIA: +%d ESSÊNCIA NA PRÓXIMA PARTIDA · SEQUÊNCIA: %d" % [gain, streak])


func take_daily_bonus() -> int:
	var b := int(data.get("daily_bonus", 0))
	if b > 0:
		data["daily_bonus"] = 0
		save()
	return b


func stats_text() -> String:
	var st: Dictionary = data["stats"]
	var lines := PackedStringArray()
	var clock := func(t: float) -> String: return "%d:%02d" % [int(t) / 60, int(t) % 60]
	lines.append("PARTIDAS %d · VITÓRIAS %d · MORTES %d" % [data["runs"], data["wins"], data["deaths"]])
	lines.append("ANDAR MAIS FUNDO: %d DE 8 · TEMPO JOGADO: %s" % [int(st.get("deepest", 0)), clock.call(float(st.get("time", 0.0)))])
	if float(data["best_time"]) > 0.0:
		lines.append("MELHOR VITÓRIA: %s" % clock.call(float(data["best_time"])))
	var syn: Array = data.get("synergies", [])
	if not syn.is_empty():
		lines.append("SINERGIAS DESCOBERTAS: %d DE %d" % [syn.size(), Player.SYNERGIES.size()])
	lines.append("")
	for pair in [["deaths_by", "QUEM MAIS TE MATOU"], ["kills_by", "QUEM VOCÊ MAIS MATOU"], ["weapon_kills", "SUAS ARMAS FAVORITAS"]]:
		var table: Dictionary = st.get(pair[0], {})
		if table.is_empty():
			continue
		var keys := table.keys()
		keys.sort_custom(func(a, b) -> bool: return int(table[a]) > int(table[b]))
		var top := PackedStringArray()
		for k in keys.slice(0, 3):
			var name := String(k)
			if pair[0] == "weapon_kills":
				var r := Catalog.find(name)
				name = r.title if r else name
			top.append("%s (%d)" % [name.to_upper(), int(table[k])])
		lines.append("%s: %s" % [pair[1], ", ".join(top)])
	var today: Dictionary = data["daily"].get(Run.today(), {})
	if not today.is_empty():
		lines.append("")
		lines.append("DESAFIO DE HOJE: %d TENTATIVAS · MAIS FUNDO %d%s" % [today["tries"], today["best_depth"],
			(" · VENCEU EM " + clock.call(float(today["best_time"]))) if float(today["best_time"]) > 0.0 else ""])
	var week: Dictionary = data["weekly"].get(Run.this_week(), {})
	if not week.is_empty():
		lines.append("DESAFIO DA SEMANA: %d TENTATIVAS · MAIS FUNDO %d%s" % [week["tries"], week["best_depth"],
			(" · VENCEU EM " + clock.call(float(week["best_time"]))) if float(week["best_time"]) > 0.0 else ""])
	if int(data["best_wave"]) > 0:
		lines.append("MODO WAVES: CHEGOU À WAVE %d" % int(data["best_wave"]))
	return "\n".join(lines)


# --- Códice -----------------------------------------------------------------------

func note_lore(text: String) -> bool:
	if text == "" or data["lore"].has(text):
		return false
	data["lore"].append(text)
	claim_codex()
	save()
	return true


# Recompensas do Códice: marcos de criaturas derrotadas e de inscrições lidas.
# Cada uma vale uma vez e guarda Essência para a próxima partida normal.
# n = -1: o bestiário inteiro.
const CODEX_REWARDS := [
	{"id": "bestiario_10", "what": "creatures", "n": 10, "essence": 25},
	{"id": "bestiario_20", "what": "creatures", "n": 20, "essence": 40},
	{"id": "bestiario_30", "what": "creatures", "n": 30, "essence": 60},
	{"id": "bestiario_todo", "what": "creatures", "n": -1, "essence": 150},
	{"id": "pedras_5", "what": "lore", "n": 5, "essence": 20},
	{"id": "pedras_15", "what": "lore", "n": 15, "essence": 35},
	{"id": "pedras_30", "what": "lore", "n": 30, "essence": 60},
	{"id": "pedras_50", "what": "lore", "n": 50, "essence": 100},
]


# Criaturas: só as que estão no bestiário (o Ladrão e afins não contam).
func codex_value(what: String) -> int:
	if what == "creatures":
		var known := known_creatures()
		return Story.BESTIARY.keys().filter(func(t: String) -> bool: return known.has(t)).size()
	return int(feat_value(what))


func codex_target(r: Dictionary) -> int:
	return Story.BESTIARY.size() if int(r["n"]) < 0 else int(r["n"])


func claim_codex() -> int:
	var claimed: Array = data.get("codex_claimed", [])
	var gain := 0
	for r: Dictionary in CODEX_REWARDS:
		if claimed.has(r["id"]) or codex_value(r["what"]) < codex_target(r):
			continue
		claimed.append(r["id"])
		gain += int(r["essence"])
		var what := "CRIATURAS" if r["what"] == "creatures" else "INSCRIÇÕES"
		Fx.toast.call_deferred("CÓDICE: %d %s · +%d ESSÊNCIA NA PRÓXIMA PARTIDA" % [codex_target(r), what, int(r["essence"])])
	data["codex_claimed"] = claimed
	if gain > 0:
		data["codex_bonus"] = int(data.get("codex_bonus", 0)) + gain
	return gain


func take_codex_bonus() -> int:
	var b := int(data.get("codex_bonus", 0))
	if b > 0:
		data["codex_bonus"] = 0
		save()
	return b


# A próxima recompensa de um tipo ("creatures" ou "lore"), para o Códice mostrar.
func next_codex_text(what: String) -> String:
	var claimed: Array = data.get("codex_claimed", [])
	for r: Dictionary in CODEX_REWARDS:
		if r["what"] == what and not claimed.has(r["id"]):
			return "PRÓXIMA RECOMPENSA: %d DE %d · +%d ESSÊNCIA" % [mini(codex_value(what), codex_target(r)), codex_target(r), int(r["essence"])]
	return "TODAS AS RECOMPENSAS RECEBIDAS"


func known_creatures() -> Array:
	return data["stats"].get("kills_by", {}).keys()


# --- conta no Windows (moksha.com.br) --------------------------------------------------
# Opcional: em EXTRAS > CONTA o jogador entra com usuário (ou e-mail) e senha.
# Daí o legado é o mesmo da conta do site: ao abrir, o mais novo vence (conta
# ou este PC) e cada save() manda uma cópia. Sem conta, nada muda: tudo local.

const SITE := "https://moksha.com.br"
const ACCOUNT_FILE := "user://conta.json"

var desk_token := ""        # sessão da conta (o mesmo cookie do site)
var desk_user := ""         # usuário ou e-mail usado para entrar
var _desk_rev := 0          # número do último envio deste PC
var _desk_ready := false    # já comparou com a conta nesta abertura
var _desk_fresh := false    # acabou de entrar: na 1ª comparação vence quem jogou mais


func desktop_account_enabled() -> bool:
	return not OS.has_feature("web") and path == DEFAULT_PATH


func desk_logged_in() -> bool:
	return desk_token != ""


func _desk_start() -> void:
	if not desktop_account_enabled():
		return
	var saved = _read_file(ACCOUNT_FILE)
	if not saved is Dictionary or String(saved.get("token", "")) == "":
		return
	desk_token = String(saved["token"])
	desk_user = String(saved.get("usuario", ""))
	player_name = String(saved.get("nome", ""))
	_desk_rev = int(saved.get("rev", 0))
	_desk_pull.call_deferred()


func _desk_write() -> void:
	if desk_token == "":
		if FileAccess.file_exists(ACCOUNT_FILE):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ACCOUNT_FILE))
		return
	var f := FileAccess.open(ACCOUNT_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"token": desk_token, "usuario": desk_user, "nome": player_name, "rev": _desk_rev}))


func _desk_request(method: int, api: String, body: Variant = null) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json", "User-Agent: MOKSHA-GAME"])
	if desk_token != "":
		headers.append("Cookie: moksha_sess=" + desk_token)
	var err := http.request(SITE + api, headers, method, "" if body == null else JSON.stringify(body))
	if err != OK:
		http.queue_free()
		return {"status": 0}
	var r: Array = await http.request_completed
	http.queue_free()
	var out := {"status": int(r[1]) if int(r[0]) == HTTPRequest.RESULT_SUCCESS else 0, "headers": r[2]}
	var parsed = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	out["body"] = parsed if parsed is Dictionary else {}
	return out


# Entra na conta. Devolve "" se deu certo ou o código do erro (para a tela de conta).
func desktop_login(login: String, senha: String) -> String:
	var r := await _desk_request(HTTPClient.METHOD_POST, "/api/entrar", {"login": login, "senha": senha})
	if int(r["status"]) == 0:
		return "rede"
	if int(r["status"]) != 200:
		return String(r["body"].get("erro", "login_invalido"))
	var token := ""
	for h: String in r["headers"]:
		if h.to_lower().begins_with("set-cookie:") and h.contains("moksha_sess="):
			token = h.get_slice("moksha_sess=", 1).get_slice(";", 0).strip_edges()
	if token == "":
		return "outro"
	if r["body"].get("nome") == null:
		desk_token = token
		await _desk_request(HTTPClient.METHOD_POST, "/api/sair", {})
		desk_token = ""
		return "sem_personagem"
	desk_token = token
	desk_user = login
	player_name = String(r["body"]["nome"])
	_desk_rev = 0
	_desk_ready = false
	_desk_fresh = true
	_desk_write()
	await _desk_pull()
	return ""


func desktop_logout() -> void:
	if desk_token != "":
		_desk_request(HTTPClient.METHOD_POST, "/api/sair", {})
	desk_token = ""
	desk_user = ""
	player_name = ""
	_desk_rev = 0
	_desk_ready = false
	_desk_write()
	account_changed.emit()


# Compara este PC com a conta: o lado com o número maior vence. Conta vazia
# recebe o legado deste PC.
func _desk_pull() -> void:
	var r := await _desk_request(HTTPClient.METHOD_GET, "/api/save")
	var st := int(r["status"])
	if st == 401 or st == 403:
		desk_token = ""
		player_name = ""
		_desk_write()
		Fx.toast("A SESSÃO DA CONTA ACABOU: ENTRE DE NOVO EM EXTRAS")
		account_changed.emit()
		return
	if st != 200:
		return   # sem internet: segue local e tenta de novo na próxima abertura
	var body: Dictionary = r["body"]
	player_name = String(body.get("nome", player_name))
	var cloud_rev := int(body.get("rev", 0))
	# primeiro login neste PC: se aqui há mais partidas que na conta, fica o daqui
	var keep_local := _desk_fresh and body.get("data") is Dictionary 		and int(data.get("runs", 0)) > int((body["data"] as Dictionary).get("runs", 0))
	_desk_fresh = false
	if keep_local:
		_desk_rev = cloud_rev + 1
		Fx.toast("ESTE PC TINHA MAIS PROGRESSO: ELE FOI PARA A CONTA")
	if body.get("data") is Dictionary and cloud_rev >= _desk_rev:
		data = _defaults()
		_merge(body["data"])
		_desk_rev = cloud_rev
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(data, "  "))
		Options.reload()
		Fx.toast("PROGRESSO DA CONTA CARREGADO")
	_desk_ready = true
	if cloud_rev < _desk_rev or not body.get("data") is Dictionary:
		_desk_rev = cloud_rev
		_desk_push()
	_desk_write()
	account_changed.emit()


func _desk_push() -> void:
	if desk_token == "" or not _desk_ready or not desktop_account_enabled():
		return
	_desk_rev += 1
	_desk_write()
	var r := await _desk_request(HTTPClient.METHOD_PUT, "/api/save", {"rev": _desk_rev, "data": data})
	if int(r["status"]) == 401 or int(r["status"]) == 403:
		desk_token = ""
		_desk_write()
		account_changed.emit()
