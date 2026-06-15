class_name BulletLogic

const MAX_BULLETS := 2000
const LIFETIME := 8.0

class BulletState:
	var position: Vector3
	var velocity: Vector3
	var age: float
	var active: bool

	func _init(pos: Vector3, vel: Vector3) -> void:
		position = pos
		velocity = vel
		age = 0.0
		active = true

static func step(bullets: Array, delta: float) -> void:
	for b in bullets:
		if not b.active:
			continue
		b.position += b.velocity * delta
		b.age += delta
		if b.age > LIFETIME:
			b.active = false

static func spawn_ring(
	center: Vector3,
	count: int,
	speed: float,
	rng: RandomNumberGenerator
) -> Array:
	var out: Array = []
	for i in count:
		var angle := (TAU / count) * i + rng.randf() * 0.05
		var vel := Vector3(cos(angle), 0.0, sin(angle)) * speed
		out.append(BulletState.new(center, vel))
	return out

static func spawn_aimed(
	center: Vector3,
	target: Vector3,
	spread_count: int,
	spread_angle: float,
	speed: float
) -> Array:
	var out: Array = []
	var base_dir := (target - center).normalized()
	var base_angle := atan2(base_dir.x, base_dir.z)
	for i in spread_count:
		var offset := 0.0
		if spread_count > 1:
			offset = lerp(-spread_angle * 0.5, spread_angle * 0.5,
				float(i) / float(spread_count - 1))
		var a := base_angle + offset
		var vel := Vector3(sin(a), 0.0, cos(a)) * speed
		out.append(BulletState.new(center, vel))
	return out
