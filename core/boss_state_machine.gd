# ボスステートマシン — 純粋ロジック。Presenterが何かを一切知らない。
# HPしきい値でフェーズが進み、フェーズごとに見た目用の signal を投げるだけ。
class_name BossStateMachine

signal state_changed(new_state: String)
signal hp_changed(ratio: float)
signal spell_declared(spell_name: String)
signal defeated

const MAX_HP := 1000.0

# フェーズはHP比率の降順で並べる。ratio がしきい値以下になった最後のフェーズが適用される。
const PHASES := [
	{"threshold": 1.0, "state": "ATTACK"},
	{"threshold": 0.66, "state": "SPELL", "spell": "紅の一閃"},
	{"threshold": 0.33, "state": "SPELL", "spell": "夜航最終譜"},
]

var hp := MAX_HP
var max_hp := MAX_HP
var state := "IDLE"
var _phase_index := 0

func start(hp_mult: float = 1.0) -> void:
	max_hp = MAX_HP * hp_mult
	hp = max_hp
	_phase_index = 0
	state = "IDLE"
	_set_state(PHASES[0].state)

func hp_ratio() -> float:
	return hp / max_hp

func take_damage(amount: float) -> void:
	if state == "DEFEATED" or amount <= 0.0:
		return
	hp = max(hp - amount, 0.0)
	emit_signal("hp_changed", hp_ratio())
	_check_phase_transition()
	if hp <= 0.0:
		_set_state("DEFEATED")
		emit_signal("defeated")

func _check_phase_transition() -> void:
	var ratio := hp_ratio()
	var next_index := _phase_index
	for i in range(_phase_index + 1, PHASES.size()):
		if ratio <= PHASES[i].threshold:
			next_index = i
		else:
			break
	if next_index == _phase_index:
		return
	_phase_index = next_index
	var phase: Dictionary = PHASES[_phase_index]
	_set_state(phase.state)
	if phase.has("spell"):
		emit_signal("spell_declared", phase.spell)

func _set_state(new_state: String) -> void:
	state = new_state
	emit_signal("state_changed", new_state)
