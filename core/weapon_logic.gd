# 自機の攻撃（オートファイア）— 純粋ロジック。
class_name WeaponLogic

const FIRE_INTERVAL := 0.12
const BULLET_SPEED := 20.0
const BULLET_DAMAGE := 10.0
const MAX_POWER := 4
const GRAZE_PER_POWER := 5
const STARTING_BOMBS := 3
const BOMB_RADIUS := 6.0

static func should_fire(cooldown_timer: float) -> bool:
	return cooldown_timer <= 0.0

static func tick_cooldown(cooldown_timer: float, delta: float) -> float:
	return max(cooldown_timer - delta, 0.0)

# power(0..MAX_POWER) を持つほど同時発射数が増える（中央に1本、左右へ追加）。
static func spawn_shots(origin: Vector3, power: int) -> Array:
	var out: Array = []
	var count := 1 + power
	for i in count:
		var offset := (i - (count - 1) / 2.0) * 0.18
		var pos := origin + Vector3(offset, 0.0, 0.0)
		out.append(BulletLogic.BulletState.new(pos, Vector3(0.0, 0.0, -1.0) * BULLET_SPEED))
	return out

static func power_from_graze(graze: int) -> int:
	return min(graze / GRAZE_PER_POWER, MAX_POWER)

static func check_boss_hit(bullet_pos: Vector3, boss_pos: Vector3, hit_radius: float) -> bool:
	return bullet_pos.distance_to(boss_pos) < hit_radius
