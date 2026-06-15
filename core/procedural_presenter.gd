class_name ProceduralPresenter
extends BossPresenter

var _mesh_instance: MeshInstance3D
var _sphere: SphereMesh
var _material: StandardMaterial3D
var _time := 0.0
var _pulse_speed := 1.0
var _bob_time := 0.0
const _BASE_Y := 1.5

func _ready() -> void:
	_sphere = SphereMesh.new()
	_sphere.radius = 1.2
	_sphere.height = 2.4

	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.8, 0.1, 0.3)
	_material.emission_enabled = true
	_material.emission = Color(0.6, 0.05, 0.2)
	_material.emission_energy_multiplier = 1.5
	_sphere.material = _material

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _sphere
	add_child(_mesh_instance)

func on_state_changed(new_state: String) -> void:
	match new_state:
		"IDLE":
			_pulse_speed = 0.5
		"ATTACK":
			_pulse_speed = 2.0
		"SPELL":
			_pulse_speed = 4.0
		"DEFEATED":
			_pulse_speed = 0.0
			_material.emission_energy_multiplier = 0.0

func on_hp_changed(ratio: float) -> void:
	_material.albedo_color = Color(0.8, 0.1 + (1.0 - ratio) * 0.5, 0.3)
	_material.emission_energy_multiplier = 1.5 + (1.0 - ratio) * 2.0

func on_spell_declared(_spell_name: String) -> void:
	_material.emission = Color(1.0, 0.8, 0.0)

func tick(delta: float) -> void:
	_time += delta * _pulse_speed
	_bob_time += delta
	var s := 1.0 + sin(_time) * 0.1
	_mesh_instance.scale = Vector3(s, s, s)
	position.y = _BASE_Y + sin(_bob_time * 0.7) * 0.5

func is_valid() -> bool:
	return true
