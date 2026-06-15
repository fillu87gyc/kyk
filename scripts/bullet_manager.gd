extends Node3D

const MAX_BULLETS := 2000

var _bullets: Array = []
var _rng := RandomNumberGenerator.new()
var _multimesh: MultiMesh
var _spawn_timer := 0.0
var _wave_timer := 0.0
var _wave_index := 0

signal bullet_hit_player(bullet_pos: Vector3)
signal bullet_grazed_player(bullet_pos: Vector3)

func _ready() -> void:
	_rng.seed = 12345

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.instance_count = MAX_BULLETS
	_multimesh.visible_instance_count = 0

	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.7, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.5, 1.0)
	mat.emission_energy_multiplier = 2.0
	mesh.material = mat
	_multimesh.mesh = mesh

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _multimesh
	add_child(mmi)

func _physics_process(delta: float) -> void:
	_wave_timer += delta
	_spawn_timer += delta

	if _spawn_timer >= _wave_interval():
		_spawn_timer = 0.0
		_spawn_wave()

	BulletLogic.step(_bullets, delta)
	_sync_multimesh()

func _wave_interval() -> float:
	return max(0.4, 2.0 - _wave_index * 0.1)

func _get_boss_pos() -> Vector3:
	var parent := get_parent()
	if parent and parent.has_node("BossPresenterSlot"):
		return parent.get_node("BossPresenterSlot").global_position
	return Vector3(0.0, 1.5, -4.0)

func _spawn_wave() -> void:
	var boss_pos := _get_boss_pos()
	var new_bullets: Array
	match _wave_index % 6:
		0:
			new_bullets = BulletLogic.spawn_ring(boss_pos, 16, 3.0, _rng)
		1:
			var player_pos := _get_player_pos()
			new_bullets = BulletLogic.spawn_aimed(boss_pos, player_pos, 5, 0.3, 4.0)
		2:
			new_bullets = BulletLogic.spawn_ring(boss_pos, 8, 5.0, _rng)
		3:
			new_bullets = BulletLogic.spawn_ring_3d(boss_pos, 20, 3.5, _rng)
		4:
			new_bullets = BulletLogic.spawn_helix(boss_pos, 3, 2.5, 3.5)
		5:
			new_bullets = BulletLogic.spawn_dive(boss_pos, 14, 5.0, 4.0, 5.0, _rng)
	_wave_index += 1

	for b in new_bullets:
		_bullets.append(b)

func _get_player_pos() -> Vector3:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].global_position
	return Vector3.ZERO

func _sync_multimesh() -> void:
	var active_count := 0
	for b in _bullets:
		if b.active:
			active_count += 1

	_multimesh.visible_instance_count = active_count
	var idx := 0
	for b in _bullets:
		if b.active:
			_multimesh.set_instance_transform(idx, Transform3D(Basis(), b.position))
			idx += 1

func check_collisions(player_pos: Vector3) -> void:
	for b in _bullets:
		if not b.active:
			continue
		if PlayerLogic.check_hit(player_pos, b.position):
			b.active = false
			emit_signal("bullet_hit_player", b.position)
		elif PlayerLogic.check_graze(player_pos, b.position):
			emit_signal("bullet_grazed_player", b.position)

func reset() -> void:
	_bullets.clear()
	_multimesh.visible_instance_count = 0
	_wave_index = 0
	_spawn_timer = 0.0
	_wave_timer = 0.0
