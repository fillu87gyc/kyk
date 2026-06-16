# 単体テスト: DashController（緊急ダッシュ回避の純粋ロジック）
#
# カバーする CUJ:
#   CUJ-17 緊急ダッシュ回避
extends GutTest

var _d: DashController

func before_each() -> void:
	_d = DashController.new()

func test_initial_state_can_dash() -> void:
	assert_true(_d.can_dash(), "開始直後はダッシュ可能")
	assert_false(_d.is_active(), "開始直後は発動していない")

func test_trigger_activates_dash() -> void:
	var triggered := _d.trigger()
	assert_true(triggered, "発動できる状態ならtrueを返す")
	assert_true(_d.is_active(), "発動後はactiveになる")

func test_trigger_fails_while_already_active() -> void:
	_d.trigger()
	var second := _d.trigger()
	assert_false(second, "発動中の再トリガーは失敗する")

func test_trigger_fails_during_cooldown() -> void:
	_d.trigger()
	_d.update(DashController.DASH_DURATION + 0.01) # 発動終了、クールダウン中
	assert_false(_d.can_dash(), "クールダウン中はダッシュ不可")
	assert_false(_d.trigger(), "クールダウン中の発動は失敗する")

func test_update_ends_dash_after_duration() -> void:
	_d.trigger()
	_d.update(DashController.DASH_DURATION + 0.001)
	assert_false(_d.is_active(), "持続時間を過ぎると非アクティブになる")

func test_can_dash_again_after_cooldown_elapses() -> void:
	_d.trigger()
	_d.update(DashController.DASH_DURATION + DashController.DASH_COOLDOWN + 0.01)
	assert_true(_d.can_dash(), "クールダウンが経過すれば再発動できる")

func test_cooldown_ratio_starts_at_one_and_reaches_zero() -> void:
	_d.trigger()
	assert_almost_eq(_d.cooldown_ratio(), 1.0, 0.0001, "発動直後はクールダウン比率1.0")
	_d.update(DashController.DASH_COOLDOWN)
	assert_almost_eq(_d.cooldown_ratio(), 0.0, 0.0001, "クールダウン経過後は比率0.0")
