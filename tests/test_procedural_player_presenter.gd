# 単体テスト: ProceduralPlayerPresenter（デフォルトの自機表現）
#
# カバーする CUJ:
#   CUJ-3  自機操作（フォーカス時の見た目変化）
#   CUJ-5  被弾（被弾フラッシュ）
#   CUJ-6  グレイズ（かすり時のグロー演出）
#
# _ready() でメッシュ・マテリアルを生成するため SceneTree に追加してから検証する。
extends GutTest

var _p: ProceduralPlayerPresenter

func before_each() -> void:
	_p = ProceduralPlayerPresenter.new()
	add_child_autofree(_p)
	await get_tree().process_frame

func test_ready_builds_mesh_and_material() -> void:
	assert_not_null(_p._mesh_instance, "_ready でメッシュインスタンスを生成する")
	assert_not_null(_p._material, "_ready でマテリアルを生成する")
	assert_true(_p.is_valid(), "生成後は有効")

func test_ready_builds_nose_marker() -> void:
	assert_gt(_p._mesh_instance.get_child_count(), 0,
		"前方を示すノーズパーツが本体に付く")

func test_focus_changes_color() -> void:
	_p.on_focus_changed(false)
	var normal_color: Color = _p._material.albedo_color
	_p.on_focus_changed(true)
	assert_ne(_p._material.albedo_color, normal_color, "フォーカス中は機体色が変わる")

func test_unfocus_restores_color() -> void:
	_p.on_focus_changed(false)
	var normal_color: Color = _p._material.albedo_color
	_p.on_focus_changed(true)
	_p.on_focus_changed(false)
	assert_eq(_p._material.albedo_color, normal_color, "フォーカス解除で元の色に戻る")

func test_hit_flash_brightens_emission() -> void:
	_p.on_hit_flash(false)
	var base_energy: float = _p._material.emission_energy_multiplier
	_p.on_hit_flash(true)
	assert_gt(_p._material.emission_energy_multiplier, base_energy,
		"被弾フラッシュで発光が強まる")

func test_hit_flash_off_restores_emission() -> void:
	_p.on_hit_flash(true)
	_p.on_hit_flash(false)
	var base_energy: float = _p._material.emission_energy_multiplier
	_p.on_hit_flash(false)
	assert_almost_eq(_p._material.emission_energy_multiplier, base_energy, 0.0001,
		"フラッシュ終了後は通常の発光に戻る")

func test_graze_starts_glow_then_decays() -> void:
	_p.on_graze()
	_p.tick(0.1)
	assert_gt(_p._mesh_instance.scale.x, 1.0, "グレイズ直後はスケールが膨らむ")
	_p.tick(1.0)
	assert_almost_eq(_p._mesh_instance.scale.x, 1.0, 0.0001,
		"グロー減衰後はスケールが元に戻る")

func test_tick_without_graze_stays_static() -> void:
	_p.tick(0.5)
	assert_almost_eq(_p._mesh_instance.scale.x, 1.0, 0.0001,
		"グレイズ無しなら tick でスケールは動かない")
