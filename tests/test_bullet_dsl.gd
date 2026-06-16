# 単体テスト: BulletDSL（弾幕パターンのテキスト記述パーサー）
#
# カバーする CUJ:
#   CUJ-4  弾幕出現（DSLで定義したパターンが正しく弾配列に変換される）
extends GutTest

var _rng: RandomNumberGenerator

func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 1

# --- parse_pattern ----------------------------------------------------

func test_parse_pattern_name_and_params() -> void:
	var p := BulletDSL.parse_pattern("ring(count=16, speed=3.0)")
	assert_eq(p.name, "ring", "パターン名を抽出する")
	assert_eq(p.params.count, 16, "整数パラメータを int として解釈する")
	assert_almost_eq(p.params.speed, 3.0, 0.0001, "小数パラメータを float として解釈する")

func test_parse_pattern_keeps_string_value() -> void:
	var p := BulletDSL.parse_pattern("ring(count=16, color=PINK)")
	assert_eq(p.params.color, "PINK", "数値でない値は文字列として保持する")

func test_parse_pattern_no_args() -> void:
	var p := BulletDSL.parse_pattern("helix()")
	assert_eq(p.name, "helix")
	assert_eq(p.params.size(), 0, "引数なしなら params は空")

func test_parse_pattern_blank_line_is_empty() -> void:
	assert_true(BulletDSL.parse_pattern("   ").is_empty(), "空行は空 Dictionary")

func test_parse_pattern_comment_line_is_empty() -> void:
	assert_true(BulletDSL.parse_pattern("# コメント").is_empty(), "# で始まる行は空 Dictionary")

func test_parse_pattern_malformed_is_empty() -> void:
	assert_true(BulletDSL.parse_pattern("ring count=16").is_empty(),
		"括弧が無い行は空 Dictionary")

# --- parse_program ------------------------------------------------------

func test_parse_program_multiple_lines() -> void:
	var program := BulletDSL.parse_program(
		"ring(count=16, speed=3.0)\nspiral(arms=3, density=24)")
	assert_eq(program.size(), 2, "複数行をすべてパースする")
	assert_eq(program[0].name, "ring")
	assert_eq(program[1].name, "spiral")

func test_parse_program_skips_blank_and_comment_lines() -> void:
	var program := BulletDSL.parse_program(
		"# 開幕\nring(count=8, speed=2.0)\n\n# 次\naimed(count=5)")
	assert_eq(program.size(), 2, "コメント・空行は除外される")

# --- spawn_from_pattern ---------------------------------------------------

func test_spawn_from_pattern_ring_count() -> void:
	var pattern := BulletDSL.parse_pattern("ring(count=12, speed=3.0)")
	var bullets := BulletDSL.spawn_from_pattern(pattern, Vector3.ZERO, _rng)
	assert_eq(bullets.size(), 12, "ring パターンは指定 count 分の弾を生成する")

func test_spawn_from_pattern_spiral_count() -> void:
	var pattern := BulletDSL.parse_pattern("spiral(arms=3, density=24)")
	var bullets := BulletDSL.spawn_from_pattern(pattern, Vector3.ZERO, _rng)
	assert_eq(bullets.size(), 72, "spiral パターンは arms*density 分の弾を生成する")

func test_spawn_from_pattern_aimed_targets_player() -> void:
	var pattern := BulletDSL.parse_pattern("aimed(count=5, speed=4.0)")
	var bullets := BulletDSL.spawn_from_pattern(
		pattern, Vector3.ZERO, _rng, Vector3(0, 0, 10))
	assert_eq(bullets.size(), 5, "aimed パターンは指定 count 分の弾を生成する")
	assert_gt(bullets[2].velocity.z, 0.0, "中央の弾はターゲット方向(+Z)へ向かう")

func test_spawn_from_pattern_unknown_name_is_empty() -> void:
	var pattern := {"name": "unknown_pattern", "params": {}}
	var bullets := BulletDSL.spawn_from_pattern(pattern, Vector3.ZERO, _rng)
	assert_eq(bullets.size(), 0, "未知のパターン名は空配列を返す")

func test_spawn_from_pattern_uses_defaults_when_param_missing() -> void:
	var pattern := BulletDSL.parse_pattern("ring()")
	var bullets := BulletDSL.spawn_from_pattern(pattern, Vector3.ZERO, _rng)
	assert_eq(bullets.size(), 16, "count省略時はデフォルト16発")

func test_spawn_from_pattern_spiral_base_angle_rotates() -> void:
	var pattern := BulletDSL.parse_pattern("spiral(arms=1, density=1)")
	var a := BulletDSL.spawn_from_pattern(pattern, Vector3.ZERO, _rng, Vector3.ZERO, 0.0)
	var b := BulletDSL.spawn_from_pattern(pattern, Vector3.ZERO, _rng, Vector3.ZERO, PI / 2.0)
	assert_ne(a[0].velocity, b[0].velocity, "base_angle が変わると弾の向きも変わる")
