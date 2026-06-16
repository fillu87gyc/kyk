class_name SpatialGrid

# 一様格子によるブロードフェーズ判定。
# 「全弾 × プレイヤー」の総当たりを避け、近傍セルだけを候補として返す。
# 候補は厳密な半径より広めに返ることがある（過剰検出は許容、過小検出は禁止）。
# 最終的な当たり判定は呼び出し側が PlayerLogic 等で厳密に行う。

var _cell_size: float
var _buckets: Dictionary = {}

func _init(cell_size: float = 4.0) -> void:
	_cell_size = cell_size

func clear() -> void:
	_buckets.clear()

func insert(item, pos: Vector3) -> void:
	var key := _cell_key(pos)
	if not _buckets.has(key):
		_buckets[key] = []
	_buckets[key].append(item)

func query_near(pos: Vector3, radius: float) -> Array:
	var result: Array = []
	var center := _cell_key(pos)
	var reach := int(ceil(radius / _cell_size)) + 1
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			var key := Vector2i(center.x + dx, center.y + dz)
			if _buckets.has(key):
				result.append_array(_buckets[key])
	return result

func _cell_key(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / _cell_size), floori(pos.z / _cell_size))
