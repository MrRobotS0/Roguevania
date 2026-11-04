class_name Combat
extends RefCounted

const STATS := ["furia", "astucia", "vigor"]
const STAT_NAMES := {"furia": "FÚRIA", "astucia": "ASTÚCIA", "vigor": "VIGOR"}
const STAT_COLORS := {"furia": Color("e0503f"), "astucia": Color("5fa8e8"), "vigor": Color("6fc27a")}
const STAT_BONUS := 0.15


static func stat_mult(levels: Dictionary, stat: String) -> float:
	return 1.0 + STAT_BONUS * float(levels.get(stat, 0))


# Crítico situacional: a regra vem da arma, o contexto de quem bateu.
static func situational_crit(rule: String, attacker: Actor, target: Actor, traveled := 0.0) -> bool:
	match rule:
		"behind":
			return target.facing == attacker.facing
		"burning":
			return target.has_status("burn")
		"far":
			return traveled > 110.0
		"stunned":
			return target.has_status("stun")
		"airborne":
			return not attacker.is_on_floor()
		"tip":
			return traveled >= 40.0
	return false
