# E2E: ゲーム内ループ（scenes/game.tscn を headless でインスタンス化）
#
# ノード層（game.gd / player.gd / bullet_manager.gd / procedural_presenter.gd）と
# ロジック層（PlayerLogic / BulletLogic）の結線を、プレイヤー体験のシナリオで検証する。
#
# カバーする E2E シナリオ:
#   E2E-1  ゲーム起動（スモーク）            … CUJ-1
#   E2E-2  ゲーム開始の初期化               … CUJ-2
#   E2E-3  被弾で残機が減る                 … CUJ-5
#   E2E-4  無敵中の連続被弾は無効           … CUJ-5
#   E2E-5  グレイズでスコア加算             … CUJ-6
#   E2E-6  残機 0 でゲームオーバー          … CUJ-7
#   E2E-7  ウェーブで弾幕が湧く             … CUJ-4
#   E2E-8  開始でボス Presenter が ATTACK へ … CUJ-8
#   E2E-12 ゲームループがボス表現を駆動する   … CUJ-8
#   E2E-13 停止中はボス表現を駆動しない       … CUJ-8
#
# ノードは独自スクリプトのメンバーへ動的アクセスするため、型注釈を付けず Variant で扱う。
extends GutTest

const GAME_SCENE := "res://scenes/game.tscn"

var _game

func before_each() -> void:
	_game = load(GAME_SCENE).instantiate()
	add_child_autofree(_game)
	await wait_frames(2)

func _player():
	return _game.get_node("Player")

func _bullets():
	return _game.get_node("BulletManager")

# E2E-1 ----------------------------------------------------------------
func test_game_boots_and_wires_nodes() -> void:
	assert_not_null(_game, "ゲームシーンが生成される")
	assert_not_null(_player(), "Player ノードが存在する")
	assert_not_null(_bullets(), "BulletManager ノードが存在する")
	assert_not_null(_game.get_node("BossPresenterSlot"), "BossPresenter スロットが存在する")
	assert_false(_game._running, "開始前は running=false")

# E2E-2 ----------------------------------------------------------------
func test_start_initializes_state() -> void:
	_game.start(777)
	assert_true(_game._running, "開始後は running=true")
	assert_eq(_game.score, 0, "スコアは 0 で開始")
	assert_eq(_player().lives, 3, "残機は 3 で開始")
	assert_eq(_player().graze, 0, "グレイズは 0 で開始")

# E2E-3 ----------------------------------------------------------------
func test_bullet_hit_reduces_life() -> void:
	_game.start(777)
	var bm = _bullets()
	var p = _player()
	p.global_position = Vector3.ZERO
	# プレイヤー位置に静止弾を 1 発置く
	bm._bullets = [BulletLogic.BulletState.new(Vector3.ZERO, Vector3.ZERO)]
	watch_signals(bm)
	bm.check_collisions(p.global_position)
	assert_signal_emitted(bm, "bullet_hit_player", "喰らい判定内の弾でヒット信号が出る")
	assert_eq(p.lives, 2, "被弾で残機が 1 減る")

# E2E-4 ----------------------------------------------------------------
func test_invincibility_blocks_second_hit() -> void:
	_game.start(777)
	var p = _player()
	p.take_hit() # 残機 2、無敵突入
	p.take_hit() # 無敵中なので無視
	assert_eq(p.lives, 2, "無敵中の連続被弾は残機を減らさない")

# E2E-5 ----------------------------------------------------------------
func test_graze_awards_score() -> void:
	_game.start(777)
	var bm = _bullets()
	var p = _player()
	p.global_position = Vector3.ZERO
	# 喰らい判定の外・グレイズ外周の内側に静止弾を置く
	var graze_d := (PlayerLogic.HIT_RADIUS + PlayerLogic.GRAZE_RADIUS) * 0.5
	bm._bullets = [BulletLogic.BulletState.new(Vector3(0, 0, graze_d), Vector3.ZERO)]
	var score_before: int = _game.score
	watch_signals(bm)
	bm.check_collisions(p.global_position)
	assert_signal_emitted(bm, "bullet_grazed_player", "グレイズ信号が出る")
	assert_gt(_game.score, score_before, "グレイズでスコアが加算される")
	assert_eq(p.graze, 1, "グレイズ回数が増える")

# E2E-6 ----------------------------------------------------------------
func test_game_over_on_last_life() -> void:
	_game.start(777)
	var p = _player()
	watch_signals(_game)
	p.lives = 1
	p.take_hit() # 残機 0 → died → game_over
	assert_eq(p.lives, 0, "残機が 0 になる")
	assert_signal_emitted(_game, "game_over", "残機 0 でゲームオーバー信号が出る")
	assert_false(_game._running, "ゲームオーバーで running=false")

# E2E-7 ----------------------------------------------------------------
func test_wave_spawns_bullets() -> void:
	var bm = _bullets()
	bm.reset()
	assert_eq(bm._bullets.size(), 0, "リセット直後は弾なし")
	bm._spawn_wave() # wave 0 → リング 16 発
	assert_eq(bm._bullets.size(), 16, "最初のウェーブでリング 16 発が湧く")
	bm._spawn_wave() # wave 1 → エイム 5 発
	assert_eq(bm._bullets.size(), 21, "次のウェーブでエイム 5 発が加わる")

# E2E-8 ----------------------------------------------------------------
func test_start_drives_boss_presenter_to_attack() -> void:
	var presenter = _game.get_node("BossPresenterSlot")
	_game.start(777)
	# ProceduralPresenter は ATTACK で _pulse_speed を上げる
	assert_gt(presenter._pulse_speed, 0.5, "開始でボスが ATTACK 表現に入る")

# E2E-12 ---------------------------------------------------------------
# game.gd の _physics_process が presenter.tick() を呼ぶ「配線」を検証する。
# 単体テスト（test_procedural_presenter）は tick() 単体の正しさを見るが、
# ゲームループから実際に駆動されるかは E2E でしか捕まえられない。
func test_running_game_drives_boss_animation() -> void:
	var presenter = _game.get_node("BossPresenterSlot")
	_game.start(777) # ATTACK 表現に入る（_pulse_speed > 0）
	# 開始直後・tick 前はスケール静止（既定値 1.0）
	assert_almost_eq(presenter._mesh_instance.scale.x, 1.0, 0.0001,
		"tick 前はボスのスケールが鼓動していない")
	_game._physics_process(0.1) # ゲームループ 1 フレーム分
	assert_ne(presenter._mesh_instance.scale.x, 1.0,
		"running 中はゲームループがボスの鼓動アニメを進める")

# E2E-13 ---------------------------------------------------------------
func test_stopped_game_does_not_drive_boss_animation() -> void:
	var presenter = _game.get_node("BossPresenterSlot")
	_game.start(777)
	_game._running = false # 停止状態
	_game._physics_process(0.1)
	assert_almost_eq(presenter._mesh_instance.scale.x, 1.0, 0.0001,
		"停止中はゲームループがボス表現を進めない")
