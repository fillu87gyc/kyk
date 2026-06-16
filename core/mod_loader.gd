class_name ModLoader

static func load_boss_presenter() -> BossPresenter:
	var mod_path := "res://mods/"
	var dir := DirAccess.open(mod_path)
	if dir:
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if dir.current_is_dir() and not entry.begins_with("."):
				var meta_path := mod_path + entry + "/mod.json"
				if FileAccess.file_exists(meta_path):
					var text := FileAccess.get_file_as_string(meta_path)
					var meta = JSON.parse_string(text)
					if meta and meta.get("target") == "boss":
						var presenter_path: String = mod_path + entry + "/" + str(meta["presenter"])
						if ResourceLoader.exists(presenter_path):
							var scr = load(presenter_path)
							if scr:
								var presenter: BossPresenter = scr.new()
								if presenter.is_valid():
									presenter.hit_radius_override = float(meta.get("hit_radius_override", -1.0))
									print("[ModLoader] loaded: ", meta.get("name", entry))
									return presenter
			entry = dir.get_next()

	print("[ModLoader] no valid MOD found — using ProceduralPresenter")
	return ProceduralPresenter.new()
