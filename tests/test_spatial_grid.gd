# 単体テスト: SpatialGrid（弾幕の当たり判定用ブロードフェーズ）
#
# カバーする CUJ:
#   CUJ-4  弾幕出現（数万発規模での当たり判定コスト削減）
#
# 一様格子が「近傍候補を漏れなく返す」ことを検証する。
# 過剰検出（誤って遠い物を含める）は許容、過小検出（近い物を漏らす）は不可。
extends GutTest

func test_query_near_includes_item_within_radius() -> void:
	var grid := SpatialGrid.new(4.0)
	grid.insert("a", Vector3(1, 0, 1))
	var result := grid.query_near(Vector3.ZERO, 2.0)
	assert_true(result.has("a"), "近くのアイテムが候補に入る")

func test_query_near_excludes_item_far_outside_reach() -> void:
	var grid := SpatialGrid.new(4.0)
	grid.insert("far", Vector3(200, 0, 200))
	var result := grid.query_near(Vector3.ZERO, 2.0)
	assert_false(result.has("far"), "遠いアイテムは候補に入らない")

func test_clear_removes_all_items() -> void:
	var grid := SpatialGrid.new(4.0)
	grid.insert("a", Vector3.ZERO)
	grid.clear()
	var result := grid.query_near(Vector3.ZERO, 5.0)
	assert_eq(result.size(), 0, "clear 後は何も見つからない")

func test_query_never_misses_a_true_positive() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grid := SpatialGrid.new(3.0)
	var points: Array = []
	for i in 50:
		var p := Vector3(rng.randf_range(-20.0, 20.0), 0.0, rng.randf_range(-20.0, 20.0))
		points.append(p)
		grid.insert(i, p)

	var query_pos := Vector3(2.0, 0.0, -3.0)
	var radius := 6.0
	var candidates := grid.query_near(query_pos, radius)

	for i in points.size():
		if points[i].distance_to(query_pos) < radius:
			assert_true(candidates.has(i),
				"厳密に半径内のアイテムはブロードフェーズの候補から漏れない")
