extends RefCounted
# Language: the game's source text is English. Every other language is a Translation whose key is
# that English text. Chosen in Settings and saved with the profile.
# "en" = English: no translation file. Every other code loads data/lang_<code>.json (includes Pokemon
# and move names). data/lang_legacy.json maps the old Spanish source text to the English one, so
# saves that stored Spanish text still resolve.

# [code, name in its own language]
const LANGS := [
	["en", "English"],
	["es_419", "Español (Latinoamérica)"],
	["es", "Español (España)"],
	["fr", "Français"],
	["it", "Italiano"],
	["pt_BR", "Português (Brasil)"],
	["pt_PT", "Português (Portugal)"],
	["ru", "Русский"],
	["ja", "日本語"],
	["zh_CN", "中文（普通话）"],
	["zh_HK", "廣東話（粵語）"],
	["vi", "Tiếng Việt"],
]
const DEFAULT := "en"

static var tr: Translation = null
static var added := false
static var loaded_code := ""


static func codes() -> Array:
	var a: Array = []
	for l in LANGS:
		a.append(l[0])
	return a


static func lang() -> String:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var c := String(SV.d["settings"].get("lang", DEFAULT))
	return c if c in codes() else DEFAULT


static func lang_name(code: String) -> String:
	for l in LANGS:
		if l[0] == code:
			return l[1]
	return code


static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var dct = JSON.parse_string(f.get_as_text())
	return dct if dct is Dictionary else {}


static func apply() -> void:
	var code := lang()
	if added and tr != null:
		TranslationServer.remove_translation(tr)
		added = false
	if code == "en":  # source text is already English
		tr = null
		loaded_code = code
	elif tr == null or loaded_code != code:
		tr = Translation.new()
		tr.locale = "en"
		var dct := _load_json("res://data/lang_%s.json" % code)
		for k in dct:
			tr.add_message(StringName(k), StringName(String(dct[k])))
		loaded_code = code
	if tr != null:
		TranslationServer.add_translation(tr)
		added = true
	TranslationServer.set_locale("en")
	var PX = load("res://scripts/pxfont.gd")
	PX.set_lang(code)


static var log := {}
static var logging := false


static var legacy: Dictionary = {}
static var legacy_loaded := false


static func t(s: String) -> String:
	var r: String = TranslationServer.translate(s)
	if r == s:
		# text saved by an older version (Spanish source): map it to the English key first
		if not legacy_loaded:
			legacy = _load_json("res://data/lang_legacy.json")
			legacy_loaded = true
		if legacy.has(s):
			r = TranslationServer.translate(String(legacy[s]))
	if logging:
		log[s] = r
	return r


# Species name (key = English pokedex name).
static func sp(name: String) -> String:
	return t(name)


static func is_en() -> bool:
	return lang() == "en"
