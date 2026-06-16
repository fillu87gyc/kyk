extends Node3D

const MAX_BULLETS := 20000
const MAX_PLAYER_BULLETS := 2000

var _bullets: Array = []
var _player_bullets: Array = []
var _rng := RandomNumberGenerator.new()
var _multimesh: MultiMesh
var _player_multimesh: MultiMesh
var _spawn_timer := 0.0
var _wave_timer := 0.0
var _wave_index := 0
var _player_fire_timer := 0.0
var _speed_mult := 1.0

signal bullet_hit_player(bullet_pos: Vector3)
signal bullet_grazed_player(bullet_pos: Vector3)
signal bullet_hit_boss(damage: float)

func _ready() -> void:
	_rng.seed = 12345

	_multimesh = _build_multimesh(MAX_BULLETS, 0.12, 0.24, Color(0.0, 0.7, 1.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _multimesh
	add_child(mmi)

	_player_multimesh = _build_multimesh(MAX_PLAYER_BULLETS, 0.06, 0.4, Color(0.3, 1.0, 0.4))
	var player_mmi := MultiMeshInstance3D.new()
	player_mmi.multimesh = _player_multimesh
	add_child(player_mmi)

func _build_multimesh(count: int, radius: float, height: float, color: Color) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.visible_instance_count = 0

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mesh.material = mat
	mm.mesh = mesh
	return mm

func _physics_process(delta: float) -> void:
	_wave_timer += delta
	_spawn_timer += delta

	if _spawn_timer >= _wave_interval():
		_spawn_timer = 0.0
		_spawn_wave()

	BulletLogic.step(_bullets, delta)
	_sync_multimesh(_multimesh, _bullets)

	_player_fire_timer = WeaponLogic.tick_cooldown(_player_fire_timer, delta)
	if WeaponLogic.should_fire(_player_fire_timer):
		_fire_player_shots()
		_player_fire_timer = WeaponLogic.FIRE_INTERVAL
	BulletLogic.step(_player_bullets, delta)
	_sync_multimesh(_player_multimesh, _player_bullets)

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
		b.velocity *= _speed_mult
		_bullets.append(b)

func set_speed_mult(mult: float) -> void:
	_speed_mult = mult

func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null

func _get_player_pos() -> Vector3:
	var player := _get_player()
	return player.global_position if player else Vector3.ZERO

func _fire_player_shots() -> void:
	var player := _get_player()
	if player == null:
		return
	var power := WeaponLogic.power_from_graze(player.graze)
	for s in WeaponLogic.spawn_shots(player.global_position, power):
		_player_bullets.append(s)

func _sync_multimesh(mm: MultiMesh, bullets: Array) -> void:
	var active_count := 0
	for b in bullets:
		if b.active:
			active_count += 1

	mm.visible_instance_count = active_count
	var idx := 0
	for b in bullets:
		if b.active:
			mm.set_instance_transform(idx, Transform3D(Basis(), b.position))
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

func check_boss_collisions(boss_pos: Vector3, hit_radius: float) -> void:
	for b in _player_bullets:
		if not b.active:
			continue
		if WeaponLogic.check_boss_hit(b.position, boss_pos, hit_radius):
			b.active = false
			emit_signal("bullet_hit_boss", WeaponLogic.BULLET_DAMAGE)

func clear_bullets_in_radius(center: Vector3, radius: float) -> int:
	var cleared := 0
	for b in _bullets:
		if b.active and b.position.distance_to(center) < radius:
			b.active = false
			cleared += 1
	return cleared

func reset() -> void:
	_bullets.clear()
	_player_bullets.clear()
	_multimesh.visible_instance_count = 0
	_player_multimesh.visible_instance_count = 0
	_wave_index = 0
	_spawn_timer = 0.0
	_wave_timer = 0.0
	_player_fire_timer = 0.0
