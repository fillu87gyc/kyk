class_name ProceduralPresenter
extends BossPresenter

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _cannon_material: StandardMaterial3D
var _time := 0.0
var _pulse_speed := 1.0
var _bob_time := 0.0
const _BASE_Y := 1.5

func _ready() -> void:
	# Body: elongated box so front/back are visually distinct from any angle.
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.2, 0.8, 2.2)

	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.8, 0.1, 0.3)
	_material.emission_enabled = true
	_material.emission = Color(0.6, 0.05, 0.2)
	_material.emission_energy_multiplier = 1.5
	body_mesh.material = _material

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = body_mesh
	add_child(_mesh_instance)

	# Cannon: front marker, points toward the player along local -Z.
	_cannon_material = StandardMaterial3D.new()
	_cannon_material.albedo_color = Color(1.0, 0.6, 0.1)
	_cannon_material.emission_enabled = true
	_cannon_material.emission = Color(1.0, 0.5, 0.1)
	_cannon_material.emission_energy_multiplier = 2.0

	var cannon_mesh := CylinderMesh.new()
	cannon_mesh.top_radius = 0.14
	cannon_mesh.bottom_radius = 0.14
	cannon_mesh.height = 1.0
	cannon_mesh.material = _cannon_material

	var cannon := MeshInstance3D.new()
	cannon.mesh = cannon_mesh
	cannon.rotation_degrees = Vector3(90, 0, 0)
	cannon.position = Vector3(0, 0, -1.5)
	_mesh_instance.add_child(cannon)

	# Thrusters: back marker, glow blue, sit on local +Z.
	for side in [-0.45, 0.45]:
		var thruster_mat := StandardMaterial3D.new()
		thruster_mat.albedo_color = Color(0.1, 0.5, 1.0)
		thruster_mat.emission_enabled = true
		thruster_mat.emission = Color(0.1, 0.5, 1.0)
		thruster_mat.emission_energy_multiplier = 2.5

		var thruster_mesh := CylinderMesh.new()
		thruster_mesh.top_radius = 0.22
		thruster_mesh.bottom_radius = 0.12
		thruster_mesh.height = 0.5
		thruster_mesh.material = thruster_mat

		var thruster := MeshInstance3D.new()
		thruster.mesh = thruster_mesh
		thruster.rotation_degrees = Vector3(90, 0, 0)
		thruster.position = Vector3(side, 0, 1.25)
		_mesh_instance.add_child(thruster)

	# Wings: break the silhouette so the body reads as a 3D craft, not a sphere.
	var wing_mat := StandardMaterial3D.new()
	wing_mat.albedo_color = Color(0.35, 0.05, 0.15)

	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(2.6, 0.1, 0.9)
	wing_mesh.material = wing_mat

	var wing := MeshInstance3D.new()
	wing.mesh = wing_mesh
	wing.position = Vector3(0, -0.1, 0.3)
	_mesh_instance.add_child(wing)

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
			_cannon_material.emission_energy_multiplier = 0.0

func on_hp_changed(ratio: float) -> void:
	_material.albedo_color = Color(0.8, 0.1 + (1.0 - ratio) * 0.5, 0.3)
	_material.emission_energy_multiplier = 1.5 + (1.0 - ratio) * 2.0

func on_spell_declared(_spell_name: String) -> void:
	_material.emission = Color(1.0, 0.8, 0.0)
	_cannon_material.emission = Color(1.0, 0.8, 0.0)

func tick(delta: float) -> void:
	_time += delta * _pulse_speed
	_bob_time += delta
	var s := 1.0 + sin(_time) * 0.1
	_mesh_instance.scale = Vector3(s, s, s)
	position.y = _BASE_Y + sin(_bob_time * 0.7) * 0.5
	_face_player()

func _face_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var to_player: Vector3 = players[0].global_position - global_position
	to_player.y = 0.0
	if to_player.length() > 0.1:
		look_at(global_position + to_player, Vector3.UP)

func is_valid() -> bool:
	return true
