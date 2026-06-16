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

# 3D ring: XZ ring with per-bullet vertical spread
static func spawn_ring_3d(
	center: Vector3,
	count: int,
	speed: float,
	rng: RandomNumberGenerator
) -> Array:
	var out: Array = []
	for i in count:
		var angle := (TAU / count) * i + rng.randf() * 0.05
		var y_angle := rng.randf_range(-PI / 4.0, PI / 4.0)
		var xz_r := cos(y_angle)
		var vel := Vector3(cos(angle) * xz_r, sin(y_angle), sin(angle) * xz_r) * speed
		out.append(BulletState.new(center, vel))
	return out

# Helix: spiral arms advancing in +Z toward the player
static func spawn_helix(
	center: Vector3,
	arm_count: int,
	speed: float,
	z_advance: float
) -> Array:
	var out: Array = []
	var bullets_per_arm := 8
	for arm in arm_count:
		var arm_offset := (TAU / arm_count) * arm
		for i in bullets_per_arm:
			var t := float(i) / float(bullets_per_arm)
			var angle := arm_offset + t * TAU
			var vel := Vector3(cos(angle) * speed, sin(angle) * speed, z_advance)
			out.append(BulletState.new(center, vel))
	return out

# Spiral: `arms` evenly-spaced blades, each subdivided into `density` bullets.
# Advancing base_angle across successive calls makes the blades appear to rotate.
static func spawn_spiral(
	center: Vector3,
	arms: int,
	density: int,
	speed: float,
	base_angle: float
) -> Array:
	var out: Array = []
	var arm_span := TAU / arms
	for arm in arms:
		var arm_angle := base_angle + arm_span * arm
		for i in density:
			var t := float(i) / float(density)
			var angle := arm_angle + t * arm_span
			var vel := Vector3(cos(angle), 0.0, sin(angle)) * speed
			out.append(BulletState.new(center, vel))
	return out

# Dive: spawn above the playfield and fall toward Y=0
static func spawn_dive(
	center: Vector3,
	count: int,
	speed: float,
	spawn_height: float,
	spread: float,
	rng: RandomNumberGenerator
) -> Array:
	var out: Array = []
	for i in count:
		var x := center.x + rng.randf_range(-spread, spread)
		var z := center.z + rng.randf_range(1.0, 8.0)
		var spawn_pos := Vector3(x, center.y + spawn_height, z)
		var target := Vector3(x + rng.randf_range(-0.5, 0.5), 0.0, z)
		var vel := (target - spawn_pos).normalized() * speed
		out.append(BulletState.new(spawn_pos, vel))
	return out
