class_name BossPresenter
extends Node3D

# mod.json の hit_radius_override が指定されたとき ModLoader が上書きする。
# -1.0 のときは「上書きなし」（呼び出し側のデフォルト半径を使う）。
var hit_radius_override := -1.0

func get_hit_radius(default_radius: float) -> float:
	return hit_radius_override if hit_radius_override > 0.0 else default_radius

func on_state_changed(_new_state: String) -> void:
	pass

func on_hp_changed(_ratio: float) -> void:
	pass

func on_spell_declared(_spell_name: String) -> void:
	pass

func tick(_delta: float) -> void:
	pass

func is_valid() -> bool:
	return true
