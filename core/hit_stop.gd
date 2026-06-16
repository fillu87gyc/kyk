class_name HitStopController

var _timer := 0.0
var _scale := 1.0

func trigger(duration: float, scale: float) -> void:
	if duration > _timer:
		_timer = duration
		_scale = scale

func update(delta: float) -> float:
	if _timer <= 0.0:
		return 1.0
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.0
		return 1.0
	return _scale

func is_active() -> bool:
	return _timer > 0.0
