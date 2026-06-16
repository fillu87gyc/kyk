# 単体テスト: SaveData（ハイスコア永続化）
#
# カバーする CUJ:
#   CUJ-14 ハイスコア記録
#
# 比較ロジックはファイルI/O不要、保存/読込は user:// 上の一時ファイルで検証し後始末する。
extends GutTest

const TEST_PATH := "user://test_savedata.cfg"

func after_each() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("test_savedata.cfg"):
		dir.remove("test_savedata.cfg")

func test_higher_score_is_new_high_score() -> void:
	assert_true(SaveData.is_new_high_score(100, 50), "現在スコアが上回れば新記録")

func test_lower_or_equal_score_is_not_new_high_score() -> void:
	assert_false(SaveData.is_new_high_score(50, 50), "同点は新記録ではない")
	assert_false(SaveData.is_new_high_score(10, 50), "下回れば新記録ではない")

func test_load_missing_file_returns_zero() -> void:
	assert_eq(SaveData.load_high_score(TEST_PATH), 0, "未保存時は0を返す")

func test_save_then_load_roundtrips() -> void:
	SaveData.save_high_score(12345, TEST_PATH)
	assert_eq(SaveData.load_high_score(TEST_PATH), 12345, "保存した値を読み込める")

func test_save_overwrites_previous_value() -> void:
	SaveData.save_high_score(100, TEST_PATH)
	SaveData.save_high_score(200, TEST_PATH)
	assert_eq(SaveData.load_high_score(TEST_PATH), 200, "再保存で値が上書きされる")
