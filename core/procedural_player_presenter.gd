class_name ProceduralPlayerPresenter
extends PlayerPresenter

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _glow_time := 0.0
const _BASE_COLOR := Color(0.2, 0.6, 1.0)
const _FOCUS_COLOR := Color(1.0, 0.9, 0.3)
const _HIT_COLOR := Color(1.0, 0.1, 0.1)
const _GRAZE_GLOW_DURATION := 0.3

func _ready() -> void:
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.6, 0.2, 1.0)

	_material = StandardMaterial3D.new()
	_material.albedo_color = _BASE_COLOR
	_material.emission_enabled = true
	_material.emission = _BASE_COLOR
	_material.emission_energy_multiplier = 0.6
	body_mesh.material = _material

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = body_mesh
	add_child(_mesh_instance)

	# Nose: front marker on local -Z, the direction the ship moves toward the boss.
	var nose_mat := StandardMaterial3D.new()
	nose_mat.albedo_color = Color(1.0, 1.0, 1.0)
	nose_mat.emission_enabled = true
	nose_mat.emission = Color(1.0, 1.0, 1.0)
	nose_mat.emission_energy_multiplier = 1.0

	var nose_mesh := CylinderMesh.new()
	nose_mesh.top_radius = 0.0
	nose_mesh.bottom_radius = 0.12
	nose_mesh.height = 0.4
	nose_mesh.material = nose_mat

	var nose := MeshInstance3D.new()
	nose.mesh = nose_mesh
	nose.rotation_degrees = Vector3(90, 0, 0)
	nose.position = Vector3(0, 0, -0.65)
	_mesh_instance.add_child(nose)

func on_focus_changed(is_focused: bool) -> void:
	_material.albedo_color = _FOCUS_COLOR if is_focused else _BASE_COLOR

func on_hit_flash(active: bool) -> void:
	_material.emission = _HIT_COLOR if active else _BASE_COLOR
	_material.emission_energy_multiplier = 2.5 if active else 0.6

func on_graze() -> void:
	_glow_time = _GRAZE_GLOW_DURATION

func tick(delta: float) -> void:
	if _glow_time > 0.0:
		_glow_time = max(_glow_time - delta, 0.0)
		var s := 1.0 + _glow_time * 0.5
		_mesh_instance.scale = Vector3(s, s, s)
	else:
		_mesh_instance.scale = Vector3.ONE

func is_valid() -> bool:
	return true
