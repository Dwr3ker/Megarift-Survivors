extends SceneTree
# Headless check of the release preparation: version, no upstream update check, patch notes complete and translated.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # should_show() writes notes_seen: restore the real save at the end
	var UPD = load("res://scripts/updater.gd")
	var PN = load("res://scripts/patchnotes.gd")
	var L = load("res://scripts/lang.gd")
	check("in-game version is 0.1.3-alpha.1", UPD.APP_VERSION == "0.1.3-alpha.1", UPD.APP_VERSION)
	check("updater targets this project's repository", UPD.REPO == "Dwr3ker/Megarift-Survivors", UPD.REPO)
	# version comparison (pure logic, no network): a newer tag is offered, the same or older is not
	check("v0.1.1 is newer than 0.1.0", UPD.is_newer("v0.1.1", "0.1.0"))
	check("v0.2.0 is newer than 0.1.9", UPD.is_newer("v0.2.0", "0.1.9"))
	check("v0.1.0 is not newer than 0.1.0", not UPD.is_newer("v0.1.0", "0.1.0"))
	check("an alpha is older than its final release", UPD.is_newer("v0.2.0-alpha.1", "0.1.0") and not UPD.is_newer("v0.1.0-alpha.1", "0.1.0") and UPD.is_newer("v0.1.0", "0.1.0-alpha.11"))
	check("a later alpha is newer, the same or an earlier one is not", UPD.is_newer("v0.1.0-alpha.12", "0.1.0-alpha.11") and UPD.is_newer("v0.1.0-alpha.10", "0.1.0-alpha.9") and not UPD.is_newer("v0.1.0-alpha.11", "0.1.0-alpha.11") and not UPD.is_newer("v0.1.0-alpha.10", "0.1.0-alpha.11"))
	# GitHub's release list (pre-releases included, newest not always first): the highest version wins, drafts are skipped
	var rels: Array = [{"tag_name": "v0.1.0-alpha.9", "draft": false}, {"tag_name": "v0.1.3-alpha.3", "draft": true}, {"tag_name": "v0.1.3-alpha.2", "draft": false, "html_url": "page",
		"assets": [{"name": "megarift-survivors-0.1.3-alpha.2.apk", "browser_download_url": "apk"}, {"name": "megarift-survivors-0.1.3-alpha.2-windows.zip", "browser_download_url": "zip"}]}]
	var nw: Dictionary = UPD.newest(rels)
	check("the update check finds the newest published build, alphas included", String(nw.get("tag_name", "")) == "v0.1.3-alpha.2" and UPD.is_newer(String(nw["tag_name"]), UPD.APP_VERSION))
	check("older builds see this release as an update", UPD.is_newer("v" + UPD.APP_VERSION, "0.1.0-alpha.10") and UPD.is_newer("v" + UPD.APP_VERSION, "0.1.0"))
	check("it offers this platform's download", UPD.asset_url(nw, "page") == ("zip" if OS.get_name() == "Windows" else ("apk" if OS.get_name() == "Android" else "page")))
	# no outbound link may point at the original port author's repository or donation page
	var bad: Array = []
	var rx := RegEx.new()
	rx.compile("https?://[^\" )]+")
	for f in ["res://scripts/menu.gd", "res://scripts/updater.gd", "res://scripts/main.gd", "res://scripts/save_data.gd", "res://scripts/progress.gd"]:
		var txt: String = FileAccess.open(f, FileAccess.READ).get_as_text()
		for mt in rx.search_all(txt):
			var url: String = mt.get_string().to_lower()
			if "jayeldragon" in url or "ko-fi" in url or "jpter78" in url:
				bad.append(f.get_file() + " -> " + url)
	check("no link to the original authors' repos or donation page", bad.is_empty(), str(bad))
	var e: Dictionary = PN.ENTRIES[0]
	check("newest patch-notes entry is this version", String(e["ver"]) == UPD.APP_VERSION, String(e["ver"]))
	var vers: Array = []
	for en in PN.ENTRIES:
		vers.append(String(en["ver"]))
	var every := true
	for n in range(1, 11):   # the ten test builds before 0.1.0
		every = every and vers.has("0.1.0-alpha.%d" % n)
	check("What's new has this version, 0.1.0 and every alpha before it, newest first", every and vers.size() == 14 and vers[0] == UPD.APP_VERSION and vers.has("0.1.1") and vers.has("0.1.0") and vers[vers.size() - 1] == "0.1.0-alpha.1", str(vers))
	# every line of every entry has a Spanish translation, and the newest entry is translated in every language
	# (the English text is the translation key; entries up to alpha.10 were only ever translated to Spanish)
	for code in ["es", "es_419", "fr", "it", "ja", "pt_BR", "pt_PT", "ru", "vi", "zh_CN", "zh_HK"]:
		var dl = JSON.parse_string(FileAccess.open("res://data/lang_%s.json" % code, FileAccess.READ).get_as_text())
		var missing: Array = []
		for en in (PN.ENTRIES if code == "es" else [PN.ENTRIES[0]]):
			for k in [en["title"]] + en["new"] + en["changes"] + en["fixes"]:
				if not dl.has(String(k)): missing.append(String(k).substr(0, 40))
		check("all patch-notes lines translated (%s)" % code, missing.is_empty(), str(missing))
	var es = JSON.parse_string(FileAccess.open("res://data/lang_es.json", FileAccess.READ).get_as_text())
	check("version label string translated", es.has("Doofcraft-style edition"))
	# the screen shows for a player with saved runs on the first launch of the new version
	SV.d["notes_seen"] = "5.4"
	SV.d["stats"]["runs"] = maxi(1, int(SV.d["stats"]["runs"]))
	check("'What's new' opens once for existing players", PN.should_show() == true and PN.should_show() == false)
	# a save code from the old app (v5.4: none of this fork's keys) must import with all progress intact
	var old: Dictionary = JSON.parse_string(JSON.stringify(_guard))   # deep copy through JSON, like a real code
	for k in ["hyper", "notes_seen"]:
		old.erase(k)
	for k in ["hyper_best", "hyper_runs", "hyperRuns", "hyperBestMin", "hyperEternatus"]:
		old["stats"].erase(k)
	old["coins"] = 12345
	old["owned"] = {"25": {"n": 3, "shiny": true}, "6": {"n": 1, "shiny": false}}
	var code: String = Marshalls.utf8_to_base64(JSON.stringify(old))                 # what "Copy save code" produces
	var parsed = JSON.parse_string(Marshalls.base64_to_utf8(code.strip_edges()))      # what "Paste save code" reads
	check("old save code is accepted (has owned + coins)", parsed is Dictionary and parsed.has("owned") and parsed.has("coins"))
	var merged: Dictionary = SV._merge(SV.default_data(), parsed)
	check("imported progress is intact", int(merged["coins"]) == 12345 and merged["owned"].has("25") and bool(merged["owned"]["25"]["shiny"]) and int(merged["owned"]["25"]["n"]) == 3)
	check("new settings and defaults are filled in around it", merged.has("settings") and merged["stats"].has("runs"))
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	menu._show("modes")
	await process_frame
	menu._show("main")
	await process_frame
	check("the donation heart stays hidden after the menu navigates", not menu.support_top.visible and menu.support_top.focus_mode == Control.FOCUS_NONE)
	check("the settings and mute buttons are visible on the main screen (patch notes live on the stage card now)", menu.set_top.visible and menu.mute_top.visible)
	check("the donation heart is hidden in the top bar", not menu.support_top.visible and menu.support_top.focus_mode == Control.FOCUS_NONE)
	check("repository button points at this project", menu.REPO_URL == "https://github.com/Dwr3ker/Megarift-Survivors", menu.REPO_URL)
	check("no donation URL is configured", menu.SUPPORT_URL == "")
	menu._show("news")
	await process_frame
	var news_txt := ""
	for c in menu.news_box.get_children():
		if c is Label: news_txt += c.text + "
"
	check("What's new screen shows this version (no inherited 5.x history)", ("v" + UPD.APP_VERSION) in news_txt and not ("v5." in news_txt) and not ("v4." in news_txt) and not ("v2." in news_txt), news_txt.substr(0, 60).replace("
", " | "))
	check("project name is Megarift Survivors", String(ProjectSettings.get_setting("application/config/name")) == "Megarift Survivors")
	SV.d = _guard
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
