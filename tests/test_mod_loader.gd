# 単体テスト: ModLoader（MOD スキャン → Presenter 選択 → フォールバック）
#
# カバーする CUJ:
#   CUJ-9  MOD 差し替え（有効 MOD が無ければプロシージャルへフォールバック）
#
# リポジトリには有効な MOD（mod.json + presenter.gd）が同梱されないため、
# ローダーは必ず ProceduralPresenter にフォールバックする。
# この「MOD 無しでも必ず起動できる」契約が起動 CUJ の生命線。
extends GutTest

func test_falls_back_to_procedural_when_no_mod() -> void:
	var p := ModLoader.load_boss_presenter()
	assert_not_null(p, "ローダーは必ず Presenter を返す（null を返さない）")
	assert_is(p, ProceduralPresenter, "有効 MOD が無ければプロシージャルにフォールバック")
	p.free()

func test_returned_presenter_is_valid() -> void:
	var p := ModLoader.load_boss_presenter()
	assert_true(p.is_valid(), "フォールバック Presenter は有効")
	p.free()

func test_returned_presenter_satisfies_interface() -> void:
	var p := ModLoader.load_boss_presenter()
	assert_is(p, BossPresenter, "返り値は BossPresenter 契約を満たす")
	p.free()

func test_loader_is_deterministic() -> void:
	# 同じ環境では毎回同じ型を返す（起動の再現性）
	var a := ModLoader.load_boss_presenter()
	var b := ModLoader.load_boss_presenter()
	assert_eq(a.get_class(), b.get_class(), "ローダーの返す型は安定している")
	a.free()
	b.free()
