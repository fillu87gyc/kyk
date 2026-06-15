# 単体テスト: ProceduralPresenter（デフォルトの幾何学ボス表現）
#
# カバーする CUJ:
#   CUJ-8  ボス表現（ステート/HP/スペル → 見た目更新）
#
# _ready() でメッシュ・マテリアルを生成するため SceneTree に追加してから検証する。
extends GutTest

var _p: ProceduralPresenter

func before_each() -> void:
	_p = ProceduralPresenter.new()
	add_child_autofree(_p)
	await get_tree().process_frame

func test_ready_builds_mesh_and_material() -> void:
	assert_not_null(_p._mesh_instance, "_ready でメッシュインスタンスを生成する")
	assert_not_null(_p._material, "_ready でマテリアルを生成する")
	assert_true(_p.is_valid(), "生成後は有効")

func test_state_attack_increases_pulse() -> void:
	_p.on_state_changed("IDLE")
	var idle_pulse: float = _p._pulse_speed
	_p.on_state_changed("ATTACK")
	assert_gt(_p._pulse_speed, idle_pulse, "ATTACK は IDLE よりパルスが速い")

func test_state_spell_is_fastest() -> void:
	_p.on_state_changed("ATTACK")
	var attack_pulse: float = _p._pulse_speed
	_p.on_state_changed("SPELL")
	assert_gt(_p._pulse_speed, attack_pulse, "SPELL は ATTACK よりさらに速い")

func test_state_defeated_stops_pulse_and_emission() -> void:
	_p.on_state_changed("DEFEATED")
	assert_almost_eq(_p._pulse_speed, 0.0, 0.0001, "撃破でパルス停止")
	assert_almost_eq(_p._material.emission_energy_multiplier, 0.0, 0.0001,
		"撃破で発光が消える")

func test_hp_change_brightens_emission() -> void:
	_p.on_hp_changed(1.0)
	var full_hp_energy: float = _p._material.emission_energy_multiplier
	_p.on_hp_changed(0.2)
	assert_gt(_p._material.emission_energy_multiplier, full_hp_energy,
		"HP が減るほど発光が強まる")

func test_hp_change_shifts_color() -> void:
	_p.on_hp_changed(1.0)
	var full := _p._material.albedo_color
	_p.on_hp_changed(0.0)
	var empty := _p._material.albedo_color
	assert_ne(full, empty, "HP に応じて色が変化する")

func test_spell_declared_changes_emission_color() -> void:
	_p.on_spell_declared("永夜返し")
	assert_almost_eq(_p._material.emission.r, 1.0, 0.01, "スペル宣言で発光色が変わる")
	assert_almost_eq(_p._material.emission.b, 0.0, 0.01, "スペル発光は青成分が落ちる")

func test_tick_animates_scale_when_pulsing() -> void:
	_p.on_state_changed("ATTACK") # _pulse_speed = 2.0
	_p.tick(0.5)                   # _time = 1.0, scale = 1 + sin(1.0)*0.1
	assert_almost_eq(_p._mesh_instance.scale.x, 1.0 + sin(1.0) * 0.1, 0.001,
		"パルス中は tick でスケールが鼓動する")

func test_tick_is_static_when_defeated() -> void:
	_p.on_state_changed("DEFEATED") # _pulse_speed = 0.0
	_p.tick(1.0)
	assert_almost_eq(_p._mesh_instance.scale.x, 1.0, 0.0001,
		"撃破後は tick でスケールが動かない")
