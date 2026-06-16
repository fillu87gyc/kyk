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
#   E2E-14 Player は player グループに属する … CUJ-3, CUJ-8
#   E2E-15 ゲームループでボスがプレイヤーを向く … CUJ-8
#   E2E-16 自機 Presenter が被弾でフラッシュする … CUJ-5, CUJ-8
#   E2E-17 デバッグトグルで喰らい/グレイズ判定が見える … CUJ-5, CUJ-6
#   E2E-18 ブーストでカメラが引きFOVが開く        … CUJ-3
#   E2E-19 自機弾がボスに当たりHPが減る            … CUJ-11
#   E2E-20 ボス撃破でステージクリア信号が出る       … CUJ-11
#   E2E-21 被弾でヒットストップが発生する          … CUJ-5
#   E2E-22 グレイズでパワー表示が増える            … CUJ-12
#   E2E-25 ボムで周囲の弾が消え残機は減らない       … CUJ-16
#   E2E-26 被弾・グレイズ・ボス撃破でパーティクルが発生する … CUJ-15
#   E2E-27 緊急ダッシュで無敵になり連続発動できない        … CUJ-17
#   E2E-28 ダッシュ表示がHUDに反映される                  … CUJ-17
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

# E2E-14 ---------------------------------------------------------------
# プレイヤーが "player" グループに属していることを検証する。
# このグループはエイム弾の標的取得（BulletManager._get_player_pos）と
# ボスの向き直り（ProceduralPresenter._face_player）の両方が依存する。
func test_player_is_in_player_group() -> void:
	assert_true(_player().is_in_group("player"),
		"Player ノードは player グループに属する")

# E2E-15 ---------------------------------------------------------------
func test_boss_faces_player_during_game_loop() -> void:
	_game.start(777)
	_player().global_position = Vector3(8.0, 0.0, 6.0)
	_game._physics_process(0.1)
	var presenter = _game.get_node("BossPresenterSlot")
	var forward: Vector3 = -presenter.global_transform.basis.z
	assert_gt(forward.x, 0.0, "プレイヤーがX+方向にいればボスもX+方向を向く")

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

# E2E-16 ---------------------------------------------------------------
func test_player_presenter_flashes_on_hit() -> void:
	_game.start(777)
	var p = _player()
	var presenter = p.get_node("PlayerPresenterSlot")
	var base_energy: float = presenter._material.emission_energy_multiplier
	p.take_hit()
	assert_gt(presenter._material.emission_energy_multiplier, base_energy,
		"被弾で自機 Presenter が発光フラッシュする")

# E2E-17 ---------------------------------------------------------------
func test_debug_toggle_reveals_hit_and_graze_radius() -> void:
	var p = _player()
	var hitbox = p.get_node("HitboxVisual")
	var grazebox = p.get_node("GrazeVisual")
	assert_false(hitbox.visible, "通常時は喰らい判定が非表示")
	assert_false(grazebox.visible, "通常時はグレイズ判定が非表示")
	p.toggle_debug_hitbox()
	assert_true(hitbox.visible, "トグルで喰らい判定が見える")
	assert_true(grazebox.visible, "トグルでグレイズ判定が見える")
	p.toggle_debug_hitbox()
	assert_false(hitbox.visible, "再トグルで非表示に戻る")
	assert_false(grazebox.visible, "再トグルで非表示に戻る")

# E2E-18 ---------------------------------------------------------------
func test_boost_widens_fov_and_pulls_camera_back() -> void:
	_game.start(777)
	var p = _player()
	var camera = _game.get_node("Camera3D")
	var normal_fov: float = camera.fov
	p.is_boosting = true
	_game._physics_process(0.5)
	assert_gt(camera.fov, normal_fov, "ブースト中はFOVが広がる")

# E2E-19 ---------------------------------------------------------------
func test_player_bullet_hits_boss_and_reduces_hp() -> void:
	_game.start(777)
	var bm = _bullets()
	var presenter = _game.get_node("BossPresenterSlot")
	var hp_before: float = _game._boss_state.hp
	bm._player_bullets = [BulletLogic.BulletState.new(presenter.global_position, Vector3.ZERO)]
	watch_signals(bm)
	bm.check_boss_collisions(presenter.global_position, _presenter_hit_radius(presenter))
	assert_signal_emitted(bm, "bullet_hit_boss", "自機弾がボスに当たるとヒット信号が出る")
	assert_lt(_game._boss_state.hp, hp_before, "ボスHPが減る")

func _presenter_hit_radius(presenter):
	return presenter.get_hit_radius(_game.BOSS_HIT_RADIUS)

# E2E-20 ---------------------------------------------------------------
func test_boss_defeat_emits_stage_clear() -> void:
	_game.start(777)
	watch_signals(_game)
	_game._boss_state.take_damage(BossStateMachine.MAX_HP)
	assert_signal_emitted(_game, "stage_clear", "ボスのHPが0になるとステージクリア信号が出る")
	assert_false(_game._running, "ステージクリアで running=false")

# E2E-21 ---------------------------------------------------------------
func test_bullet_hit_triggers_hit_stop() -> void:
	_game.start(777)
	var bm = _bullets()
	var p = _player()
	p.global_position = Vector3.ZERO
	bm._bullets = [BulletLogic.BulletState.new(Vector3.ZERO, Vector3.ZERO)]
	bm.check_collisions(p.global_position)
	assert_true(_game._hit_stop.is_active(), "被弾でヒットストップが有効になる")
	_game._physics_process(0.001)
	assert_lt(Engine.time_scale, 1.0, "ヒットストップ中は time_scale が下がる")
	Engine.time_scale = 1.0

# E2E-22 ---------------------------------------------------------------
func test_graze_increases_power_label() -> void:
	_game.start(777)
	var bm = _bullets()
	var p = _player()
	p.global_position = Vector3.ZERO
	var graze_d := (PlayerLogic.HIT_RADIUS + PlayerLogic.GRAZE_RADIUS) * 0.5
	for i in WeaponLogic.GRAZE_PER_POWER:
		bm._bullets = [BulletLogic.BulletState.new(Vector3(0, 0, graze_d), Vector3.ZERO)]
		bm.check_collisions(p.global_position)
	var power_label = _game.get_node("HUD/PowerLabel")
	assert_eq(power_label.text, "POWER: 1", "グレイズが貯まるとパワー表示が増える")

# E2E-25 ---------------------------------------------------------------
func test_bomb_clears_nearby_bullets_without_losing_life() -> void:
	_game.start(777)
	var bm = _bullets()
	var p = _player()
	p.global_position = Vector3.ZERO
	bm._bullets = [BulletLogic.BulletState.new(Vector3(1, 0, 1), Vector3.ZERO)]
	var bombs_before: int = p.bombs
	var lives_before: int = p.lives
	_game._try_use_bomb()
	assert_eq(p.bombs, bombs_before - 1, "ボム使用でボム数が1減る")
	assert_eq(p.lives, lives_before, "ボム使用で残機は減らない")
	assert_false(bm._bullets[0].active, "ボムの範囲内の弾が消える")

# E2E-26 ---------------------------------------------------------------
func test_hit_and_graze_and_defeat_trigger_particles() -> void:
	_game.start(777)
	_game._on_bullet_hit(Vector3(1, 0, 2))
	assert_true(_game._hit_particles.emitting, "被弾でヒットパーティクルが発生する")
	assert_eq(_game._hit_particles.global_position, Vector3(1, 0, 2),
		"パーティクルが被弾位置に出る")

	_game._on_bullet_graze(Vector3(3, 0, 4))
	assert_true(_game._graze_particles.emitting, "グレイズでグレイズパーティクルが発生する")

	_game._boss_state.take_damage(BossStateMachine.MAX_HP)
	assert_true(_game._defeat_particles.emitting, "ボス撃破で撃破パーティクルが発生する")

# E2E-27 ---------------------------------------------------------------
func test_dash_grants_invincibility_and_blocks_immediate_retrigger() -> void:
	_game.start(777)
	var p = _player()
	assert_false(p.is_dashing(), "開始直後はダッシュ中ではない")
	var triggered: bool = p.trigger_dash(Vector2(1, 0))
	assert_true(triggered, "通常状態からはダッシュが発動できる")
	assert_true(p.is_dashing(), "発動直後はダッシュ中になる")
	var hit_before: int = p.lives
	p.take_hit() # ダッシュの無敵中なので無視されるはず
	assert_eq(p.lives, hit_before, "ダッシュ中の無敵で被弾が無効になる")
	var retriggered: bool = p.trigger_dash(Vector2(1, 0))
	assert_false(retriggered, "発動中・クールダウン中の再発動は失敗する")

# E2E-28 ---------------------------------------------------------------
func test_dash_label_reflects_dash_state() -> void:
	_game.start(777)
	var p = _player()
	var dash_label = _game.get_node("HUD/DashLabel")
	_game._update_dash_hud()
	assert_eq(dash_label.text, "DASH: READY", "開始直後はダッシュ可能表示")
	p.trigger_dash(Vector2(1, 0))
	_game._update_dash_hud()
	assert_eq(dash_label.text, "DASH: ACTIVE", "発動中はACTIVE表示")
	p._physics_process(DashController.DASH_DURATION + 0.01) # 発動終了、クールダウン中
	_game._update_dash_hud()
	assert_eq(dash_label.text, "DASH: COOLDOWN", "発動終了直後はCOOLDOWN表示")
