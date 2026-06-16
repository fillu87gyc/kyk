# 単体テスト: ScoreLogic（スコア計算をロジック層に分離）
#
# カバーする CUJ:
#   CUJ-6  グレイズ加点
#   CUJ-11 ボス撃破加点
extends GutTest

func test_graze_score_is_positive() -> void:
	assert_gt(ScoreLogic.graze_score(), 0, "グレイズは加点される")

func test_boss_defeat_score_is_much_larger_than_graze_score() -> void:
	assert_gt(ScoreLogic.boss_defeat_score(), ScoreLogic.graze_score(),
		"ボス撃破はグレイズよりずっと高得点")
