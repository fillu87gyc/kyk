# 単体テスト: PlayerPresenter（自機表現インターフェース基底）
#
# カバーする CUJ:
#   CUJ-3  自機操作（被弾/グレイズ/フォーカスの見た目フックは Presenter に委譲）
#
# BossPresenter と同じ契約パターン: 基底は「壊れない no-op」かつ is_valid()==true。
extends GutTest

func test_base_is_node3d() -> void:
	var p := PlayerPresenter.new()
	assert_is(p, Node3D, "PlayerPresenter は Node3D を継承する")
	p.free()

func test_base_is_valid_true_by_default() -> void:
	var p := PlayerPresenter.new()
	assert_true(p.is_valid(), "既定の Presenter は有効")
	p.free()

func test_base_callbacks_are_safe_noops() -> void:
	var p := PlayerPresenter.new()
	p.on_focus_changed(true)
	p.on_hit_flash(true)
	p.on_graze()
	p.tick(0.016)
	assert_true(true, "基底コールバックは安全に呼び出せる")
	p.free()

func test_procedural_is_a_player_presenter() -> void:
	var p := ProceduralPlayerPresenter.new()
	assert_is(p, PlayerPresenter, "ProceduralPlayerPresenter は PlayerPresenter の派生")
	p.free()
