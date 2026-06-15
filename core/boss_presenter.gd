class_name BossPresenter
extends Node3D

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
