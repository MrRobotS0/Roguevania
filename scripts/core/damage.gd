class_name Damage
extends RefCounted

# Tudo que machuca passa por aqui: golpe, flecha, explosão, fogo, chefe.
# Quem bate monta o pacote; quem apanha decide o que fazer com ele.

var amount := 0.0
var dir := 0                 # para onde o golpe empurra (-1, 0, 1)
var knock := 0.0
var lift := 0.0
var crit := false
var stop := 0.0              # congelamento no impacto (hitstop)
var shake := 0.0
var status := {}             # {"burn": 3.0} = queima por 3 s
var source: Node
var over_time := false       # dano de status: não atordoa nem empurra
var unblockable := false
var parried := false         # preenchido por quem defendeu com aparo
var blocked := false


static func make(value: float, push_dir := 0, push := 0.0) -> Damage:
	var d := Damage.new()
	d.amount = value
	d.dir = push_dir
	d.knock = push
	return d


func copy() -> Damage:
	var d := Damage.new()
	d.amount = amount
	d.dir = dir
	d.knock = knock
	d.lift = lift
	d.crit = crit
	d.stop = stop
	d.shake = shake
	d.status = status.duplicate()
	d.source = source if is_instance_valid(source) else null
	d.over_time = over_time
	d.unblockable = unblockable
	return d


func value() -> int:
	return maxi(1, roundi(amount))
