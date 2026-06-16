class_name DashController

# 仮値。Layer B（Steam Deck実機）での操作感確認を経て調整する前提の暫定パラメータ。
const DASH_DURATION := 0.18 # 突進＋無敵が続く時間
const DASH_SPEED := 22.0 # 突進速度（BOOST_SPEEDより速い瞬間移動寄りの速度）
const DASH_COOLDOWN := 1.2 # 次のダッシュが撃てるまでの待機時間

var _active := false
var _timer := 0.0
var _cooldown_timer := 0.0

func can_dash() -> bool:
	return not _active and _cooldown_timer <= 0.0

# 発動できればタイマーをセットして true を返す。クールダウン中/発動中は false。
func trigger() -> bool:
	if not can_dash():
		return false
	_active = true
	_timer = DASH_DURATION
	_cooldown_timer = DASH_COOLDOWN
	return true

func update(delta: float) -> void:
	if _active:
		_timer -= delta
		if _timer <= 0.0:
			_active = false
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func is_active() -> bool:
	return _active

func cooldown_ratio() -> float:
	if DASH_COOLDOWN <= 0.0:
		return 0.0
	return clamp(_cooldown_timer / DASH_COOLDOWN, 0.0, 1.0)
