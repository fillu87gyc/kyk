# 単体テスト: SampleHumanoidPresenter（SDK の人型 MOD サンプル）
#
# カバーする CUJ:
#   CUJ-9  MOD 差し替え（人型 Presenter の契約適合・耐障害性）
#
# AnimationPlayer 無しでも _ready / 各コールバックが安全に動くこと
# （= MOD 作者がコピペして壊れないこと）を保証する。
extends GutTest

var _p: SampleHumanoidPresenter

func before_each() -> void:
	_p = SampleHumanoidPresenter.new()
	add_child_autofree(_p)
	await get_tree().process_frame

func test_is_valid() -> void:
	assert_true(_p.is_valid(), "サンプル Presenter は有効")

func test_ready_without_animation_player_is_null() -> void:
	assert_null(_p._anim, "AnimationPlayer 子ノードが無ければ _anim は null")

func test_state_change_without_anim_is_safe() -> void:
	# _anim == null のとき on_state_changed は早期 return（クラッシュしない）
	_p.on_state_changed("ATTACK")
	_p.on_state_changed("DEFEATED")
	assert_true(true, "AnimationPlayer 無しでもステート変更は安全")

func test_spell_declared_routes_to_state_safely() -> void:
	# on_spell_declared は内部で on_state_changed("SPELL") を呼ぶ
	_p.on_spell_declared("禁忌")
	assert_true(true, "スペル宣言も安全に処理される")

func test_default_state_map_has_all_boss_keys() -> void:
	for key in ["IDLE", "ATTACK", "SPELL", "DEFEATED"]:
		assert_has(_p._state_map, key, "state_map に %s が定義されている" % key)
