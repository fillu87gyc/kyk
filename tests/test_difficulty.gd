# 単体テスト: Difficulty（難易度プリセット・選択ロジック）
#
# カバーする CUJ:
#   CUJ-13 難易度選択
#
# 純粋ロジック（class_name のみ・extends なし）のため Node 不要で検証できる。
extends GutTest

func test_normal_preset_matches_current_defaults() -> void:
	var preset := Difficulty.get_preset(Difficulty.Level.NORMAL)
	assert_eq(preset.lives, 3, "NORMAL の残機は既存デフォルトと一致する")
	assert_almost_eq(preset.bullet_speed_mult, 1.0, 0.0001, "NORMAL の弾速倍率は1.0")
	assert_almost_eq(preset.boss_hp_mult, 1.0, 0.0001, "NORMAL のボスHP倍率は1.0")

func test_easy_is_more_forgiving_than_normal() -> void:
	var easy := Difficulty.get_preset(Difficulty.Level.EASY)
	var normal := Difficulty.get_preset(Difficulty.Level.NORMAL)
	assert_gt(easy.lives, normal.lives, "EASY は残機が多い")
	assert_lt(easy.bullet_speed_mult, normal.bullet_speed_mult, "EASY は弾が遅い")
	assert_lt(easy.boss_hp_mult, normal.boss_hp_mult, "EASY はボスHPが低い")

func test_lunatic_is_harder_than_hard() -> void:
	var hard := Difficulty.get_preset(Difficulty.Level.HARD)
	var lunatic := Difficulty.get_preset(Difficulty.Level.LUNATIC)
	assert_lt(lunatic.lives, hard.lives, "LUNATIC は残機が少ない")
	assert_gt(lunatic.bullet_speed_mult, hard.bullet_speed_mult, "LUNATIC は弾が速い")
	assert_gt(lunatic.boss_hp_mult, hard.boss_hp_mult, "LUNATIC はボスHPが高い")

func test_unknown_level_falls_back_to_normal() -> void:
	var preset := Difficulty.get_preset(999)
	assert_eq(preset.name, "NORMAL", "未知のレベルは NORMAL にフォールバックする")

func test_next_level_cycles_forward() -> void:
	assert_eq(Difficulty.next_level(Difficulty.Level.EASY), Difficulty.Level.NORMAL)
	assert_eq(Difficulty.next_level(Difficulty.Level.LUNATIC), Difficulty.Level.EASY,
		"LUNATIC の次は先頭 EASY に循環する")

func test_previous_level_cycles_backward() -> void:
	assert_eq(Difficulty.previous_level(Difficulty.Level.NORMAL), Difficulty.Level.EASY)
	assert_eq(Difficulty.previous_level(Difficulty.Level.EASY), Difficulty.Level.LUNATIC,
		"EASY の前は末尾 LUNATIC に循環する")
