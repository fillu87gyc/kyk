# 単体テスト: StageDressing（外部アセット無しの背景演出生成）
#
# カバーする CUJ:
#   CUJ-15 ステージ背景・速度感演出
#
# GUT は Godot を headless で起動するため、Node/Mesh の生成自体はここで検証できる。
# 実際の見た目（色味・遠近感）は Layer B（Steam Deck 実機）でのみ確認可能。
extends GutTest

func test_grid_floor_has_shader_material() -> void:
	var floor_mesh := add_child_autofree(StageDressing.build_grid_floor(Vector2(60.0, 60.0)))
	assert_eq(floor_mesh.name, "GridFloor", "床メッシュにグリッド用の名前が付く")
	var mat := floor_mesh.mesh.material
	assert_is(mat, ShaderMaterial, "床にはシェーダーマテリアルが使われる")
	assert_string_contains(mat.shader.code, "shader_type spatial", "外部アセット無しの手続きシェーダーである")

func test_moon_has_emissive_material() -> void:
	var moon := add_child_autofree(StageDressing.build_moon())
	assert_eq(moon.name, "Moon", "月ノードという名前が付く")
	assert_true(moon.mesh.material.emission_enabled, "月は発光する")

func test_silhouette_builds_requested_peak_count() -> void:
	var silhouette := add_child_autofree(StageDressing.build_silhouette(9, 99))
	assert_eq(silhouette.name, "Silhouette", "稜線ノードという名前が付く")
	assert_eq(silhouette.get_child_count(), 9, "指定した数の山が生成される")

func test_silhouette_is_deterministic_for_same_seed() -> void:
	var a := add_child_autofree(StageDressing.build_silhouette(5, 42))
	var b := add_child_autofree(StageDressing.build_silhouette(5, 42))
	assert_almost_eq(a.get_child(2).position.x, b.get_child(2).position.x, 0.0001,
		"同じシードなら同じ配置になる（再現性）")

func test_burst_particles_start_inactive() -> void:
	var particles := add_child_autofree(StageDressing.build_burst_particles(Color.RED, 16))
	assert_false(particles.emitting, "生成直後は発光していない")
	assert_eq(particles.amount, 16, "指定した粒子数が設定される")
	assert_true(particles.one_shot, "ワンショットの burst として設定される")
