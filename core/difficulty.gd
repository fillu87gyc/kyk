class_name Difficulty

enum Level { EASY, NORMAL, HARD, LUNATIC }

const PRESETS := {
	Level.EASY: {
		"name": "EASY", "bullet_speed_mult": 0.7, "boss_hp_mult": 0.7, "lives": 5,
	},
	Level.NORMAL: {
		"name": "NORMAL", "bullet_speed_mult": 1.0, "boss_hp_mult": 1.0, "lives": 3,
	},
	Level.HARD: {
		"name": "HARD", "bullet_speed_mult": 1.3, "boss_hp_mult": 1.3, "lives": 2,
	},
	Level.LUNATIC: {
		"name": "LUNATIC", "bullet_speed_mult": 1.6, "boss_hp_mult": 1.6, "lives": 1,
	},
}

const ORDER := [Level.EASY, Level.NORMAL, Level.HARD, Level.LUNATIC]

static func get_preset(level: int) -> Dictionary:
	return PRESETS.get(level, PRESETS[Level.NORMAL])

static func next_level(level: int) -> int:
	var idx := ORDER.find(level)
	if idx == -1:
		return Level.NORMAL
	return ORDER[(idx + 1) % ORDER.size()]

static func previous_level(level: int) -> int:
	var idx := ORDER.find(level)
	if idx == -1:
		return Level.NORMAL
	return ORDER[(idx - 1 + ORDER.size()) % ORDER.size()]
