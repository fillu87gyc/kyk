# ハイスコアの永続化 — 比較・直列化は純粋ロジック、保存/読込のみ ConfigFile に依存する。
class_name SaveData

const SAVE_PATH := "user://savedata.cfg"
const SECTION := "save"
const KEY_HIGH_SCORE := "high_score"

static func is_new_high_score(current_score: int, stored_high_score: int) -> bool:
	return current_score > stored_high_score

static func load_high_score(path: String = SAVE_PATH) -> int:
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		return 0
	return int(cfg.get_value(SECTION, KEY_HIGH_SCORE, 0))

static func save_high_score(high_score: int, path: String = SAVE_PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_HIGH_SCORE, high_score)
	cfg.save(path)
