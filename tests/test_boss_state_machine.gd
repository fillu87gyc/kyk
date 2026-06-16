# 単体テスト: BossStateMachine（HPしきい値によるフェーズ遷移）
#
# カバーする CUJ:
#   CUJ-8  ボス表現（ステートマシンはPresenterを知らない純粋ロジック）
#   CUJ-11 ボス撃破（HPがフェーズしきい値を跨ぐとSPELL宣言、0でDEFEATED）
extends GutTest

var _b: BossStateMachine

func before_each() -> void:
	_b = BossStateMachine.new()
	_b.start()

func test_start_initializes_full_hp_and_attack_state() -> void:
	assert_almost_eq(_b.hp_ratio(), 1.0, 0.0001, "開始時はHP満タン")
	assert_eq(_b.state, "ATTACK", "開始時は ATTACK ステート")

func test_take_damage_reduces_hp() -> void:
	_b.take_damage(100.0)
	assert_almost_eq(_b.hp_ratio(), 0.9, 0.0001, "ダメージ分だけHP比率が下がる")

func test_hp_cannot_go_negative() -> void:
	_b.take_damage(99999.0)
	assert_almost_eq(_b.hp_ratio(), 0.0, 0.0001, "HPは0未満にならない")

func test_zero_or_negative_damage_is_ignored() -> void:
	_b.take_damage(0.0)
	_b.take_damage(-10.0)
	assert_almost_eq(_b.hp_ratio(), 1.0, 0.0001, "0以下のダメージは無視される")

func test_crossing_first_threshold_declares_spell() -> void:
	watch_signals(_b)
	_b.take_damage(BossStateMachine.MAX_HP * 0.35) # ratio 0.65 ≦ 0.66
	assert_signal_emitted(_b, "spell_declared", "しきい値を跨ぐとスペル宣言される")
	assert_eq(_b.state, "SPELL", "フェーズ移行でSPELLステートになる")

func test_not_crossing_threshold_does_not_change_state() -> void:
	watch_signals(_b)
	_b.take_damage(BossStateMachine.MAX_HP * 0.1) # ratio 0.9 > 0.66
	assert_signal_not_emitted(_b, "spell_declared", "しきい値を跨がなければスペル宣言なし")
	assert_eq(_b.state, "ATTACK", "ステートは変わらない")

func test_large_damage_skips_directly_to_final_phase() -> void:
	_b.take_damage(BossStateMachine.MAX_HP * 0.9) # ratio 0.1 ≦ 0.33 を一気に跨ぐ
	assert_eq(_b.state, "SPELL", "一気に最終フェーズへ進む")

func test_damage_to_zero_emits_defeated() -> void:
	watch_signals(_b)
	_b.take_damage(BossStateMachine.MAX_HP)
	assert_signal_emitted(_b, "defeated", "HP0でdefeatedが発火する")
	assert_eq(_b.state, "DEFEATED", "HP0でDEFEATEDステートになる")

func test_damage_after_defeated_is_ignored() -> void:
	_b.take_damage(BossStateMachine.MAX_HP)
	watch_signals(_b)
	_b.take_damage(100.0)
	assert_signal_not_emitted(_b, "hp_changed", "撃破後のダメージは無視される")

func test_hp_changed_emits_current_ratio() -> void:
	watch_signals(_b)
	_b.take_damage(250.0)
	assert_signal_emitted_with_parameters(_b, "hp_changed", [0.75],
		"hp_changed は現在のHP比率を伝える")

func test_hp_mult_scales_max_hp_but_ratio_starts_full() -> void:
	_b.start(1.3) # HARD/LUNATIC 相当の倍率
	assert_almost_eq(_b.max_hp, BossStateMachine.MAX_HP * 1.3, 0.0001,
		"倍率付きで開始するとHP総量がスケールする")
	assert_almost_eq(_b.hp_ratio(), 1.0, 0.0001, "倍率に関わらず開始時の比率は満タン")
