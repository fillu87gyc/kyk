# 弾幕DSL — テキストパターン記述（例: "ring(count=16, speed=3.0)"）を
# BulletLogic の spawn_* 呼び出しへ変換する。パース自体は純粋関数（ロジック層）。
class_name BulletDSL

static func parse_pattern(line: String) -> Dictionary:
	var trimmed := line.strip_edges()
	if trimmed.is_empty() or trimmed.begins_with("#"):
		return {}
	var open := trimmed.find("(")
	var close := trimmed.rfind(")")
	if open == -1 or close == -1 or close < open:
		return {}
	var name := trimmed.substr(0, open).strip_edges()
	var body := trimmed.substr(open + 1, close - open - 1)
	var params := {}
	if not body.strip_edges().is_empty():
		for part in body.split(","):
			var kv := part.split("=")
			if kv.size() != 2:
				continue
			params[kv[0].strip_edges()] = _parse_value(kv[1].strip_edges())
	return {"name": name, "params": params}

static func parse_program(text: String) -> Array:
	var out: Array = []
	for line in text.split("\n"):
		var pattern := parse_pattern(line)
		if not pattern.is_empty():
			out.append(pattern)
	return out

static func spawn_from_pattern(
	pattern: Dictionary,
	center: Vector3,
	rng: RandomNumberGenerator,
	target: Vector3 = Vector3.ZERO,
	base_angle: float = 0.0
) -> Array:
	var p: Dictionary = pattern.get("params", {})
	match pattern.get("name", ""):
		"ring":
			return BulletLogic.spawn_ring(
				center, int(p.get("count", 16)), float(p.get("speed", 3.0)), rng)
		"ring3d":
			return BulletLogic.spawn_ring_3d(
				center, int(p.get("count", 16)), float(p.get("speed", 3.0)), rng)
		"aimed":
			return BulletLogic.spawn_aimed(
				center, target, int(p.get("count", 5)),
				float(p.get("spread", 0.3)), float(p.get("speed", 4.0)))
		"spiral":
			return BulletLogic.spawn_spiral(
				center, int(p.get("arms", 3)), int(p.get("density", 8)),
				float(p.get("speed", 3.0)), base_angle)
		"helix":
			return BulletLogic.spawn_helix(
				center, int(p.get("arms", 3)), float(p.get("speed", 2.5)),
				float(p.get("advance", 3.5)))
		"dive":
			return BulletLogic.spawn_dive(
				center, int(p.get("count", 14)), float(p.get("speed", 5.0)),
				float(p.get("height", 4.0)), float(p.get("spread", 5.0)), rng)
	return []

static func _parse_value(raw: String):
	if raw.is_valid_int():
		return raw.to_int()
	if raw.is_valid_float():
		return raw.to_float()
	return raw
