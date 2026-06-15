# MIT License — copy freely as a MOD starting point.
#
# Place this file as: mods/your_mod/presenter.gd
# and reference it from mod.json: "presenter": "presenter.gd"
#
# This sample plays AnimationPlayer clips driven by boss state.
class_name SampleHumanoidPresenter
extends BossPresenter

var _anim: AnimationPlayer
var _state_map: Dictionary = {
	"IDLE":     "idle",
	"ATTACK":   "attack",
	"SPELL":    "spell",
	"DEFEATED": "defeat",
}

func _ready() -> void:
	_anim = $AnimationPlayer if has_node("AnimationPlayer") else null

func on_state_changed(new_state: String) -> void:
	if _anim == null:
		return
	var clip: String = _state_map.get(new_state, "idle")
	if _anim.has_animation(clip):
		_anim.play(clip)

func on_hp_changed(_ratio: float) -> void:
	pass

func on_spell_declared(spell_name: String) -> void:
	on_state_changed("SPELL")

func tick(_delta: float) -> void:
	pass

func is_valid() -> bool:
	return true
