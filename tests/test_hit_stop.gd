# 単体テスト: HitStopController（被弾/グレイズ時の時間減速）
#
# カバーする CUJ:
#   CUJ-5  被弾（ヒットストップで衝撃を強調）
#   CUJ-6  グレイズ（軽いスローで「際」を強調）
extends GutTest

var _h: HitStopController

func before_each() -> void:
	_h = HitStopController.new()

func test_inactive_by_default() -> void:
	assert_false(_h.is_active(), "発火前は非アクティブ")
	assert_almost_eq(_h.update(0.1), 1.0, 0.0001, "発火前は時間スケール 1.0")

func test_trigger_activates_and_returns_scale() -> void:
	_h.trigger(0.2, 0.1)
	assert_true(_h.is_active(), "発火でアクティブになる")
	assert_almost_eq(_h.update(0.05), 0.1, 0.0001, "アクティブ中は指定スケールを返す")

func test_expires_after_duration() -> void:
	_h.trigger(0.1, 0.1)
	_h.update(0.05)
	var scale := _h.update(0.06) # 合計 0.11 > 0.1 で失効
	assert_almost_eq(scale, 1.0, 0.0001, "持続時間を超えると 1.0 に戻る")
	assert_false(_h.is_active(), "失効後は非アクティブ")

func test_longer_trigger_overrides_shorter() -> void:
	_h.trigger(0.1, 0.5)
	_h.trigger(0.3, 0.05) # グレイズ中に被弾 → より長い方を採用
	assert_almost_eq(_h.update(0.0), 0.05, 0.0001, "より長い発火に上書きされる")

func test_shorter_trigger_does_not_override_longer() -> void:
	_h.trigger(0.3, 0.05)
	_h.trigger(0.1, 0.5) # 既存の方が長いので無視される
	assert_almost_eq(_h.update(0.0), 0.05, 0.0001, "短い発火は既存の長い発火を上書きしない")
