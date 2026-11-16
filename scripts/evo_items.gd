extends RefCounted
# What each branching evolution uses (roadmap step 65a): when a Pokémon with several evolutions is offered its choices
# in a run, each card shows the stone or item (or the condition) that species evolves with. Icons are 16 x 16 pixel
# art drawn here, read by icons.gd as "evoitem:<id>".

# target dex -> [item id, name, note ("" = none)]. Names and notes go through L.t().
const BY_DEX := {
	# Eevee
	134: ["water", "Water Stone", ""], 135: ["thunder", "Thunder Stone", ""], 136: ["fire", "Fire Stone", ""],
	196: ["friend", "Friendship", "day"], 197: ["friend", "Friendship", "night"], 470: ["leaf", "Leaf Stone", ""],
	471: ["ice", "Ice Stone", ""], 700: ["friend_fairy", "Friendship", "knows a Fairy move"],
	# Gloom, Poliwhirl, Slowpoke, Scyther, Wooper, Sneasel
	45: ["leaf", "Leaf Stone", ""], 182: ["sun", "Sun Stone", ""],
	62: ["water", "Water Stone", ""], 186: ["kingsrock", "King's Rock", "trade"],
	80: ["level", "Level %d", ""], 199: ["kingsrock", "King's Rock", "trade"],
	212: ["metalcoat", "Metal Coat", "trade"], 900: ["augurite", "Black Augurite", ""],
	195: ["level", "Level %d", ""], 980: ["level", "Level %d", "Paldean form"],
	461: ["razorclaw", "Razor Claw", "night"], 903: ["razorclaw", "Razor Claw", "day"],
	# Meowth, Tyrogue, Wurmple, Kirlia, Nincada, Snorunt, Clamperl, Burmy, Yamask
	53: ["level", "Level %d", ""], 863: ["level", "Level %d", "Galarian form"],
	106: ["level", "Level %d", "Attack higher"], 107: ["level", "Level %d", "Defense higher"], 237: ["level", "Level %d", "Attack = Defense"],
	266: ["level", "Level %d", "random"], 268: ["level", "Level %d", "random"],
	282: ["level", "Level %d", ""], 475: ["dawn", "Dawn Stone", "male"],
	291: ["level", "Level %d", ""], 292: ["pokeball", "Level %d", "a spare Poké Ball"],
	362: ["level", "Level %d", ""], 478: ["dawn", "Dawn Stone", "female"],
	367: ["deeptooth", "Deep Sea Tooth", "trade"], 368: ["deepscale", "Deep Sea Scale", "trade"],
	413: ["level", "Level %d", "female"], 414: ["level", "Level %d", "male"],
	563: ["level", "Level %d", ""], 867: ["level", "Galarian form", "after taking damage"],
	# Cosmoem, Applin, Charcadet
	791: ["sunicon", "Level %d", "Sun"], 792: ["moonicon", "Level %d", "Moon"],
	841: ["tart", "Tart Apple", ""], 842: ["sweet", "Sweet Apple", ""], 1011: ["syrupy", "Syrupy Apple", ""],
	936: ["auspicious", "Auspicious Armor", ""], 937: ["malicious", "Malicious Armor", ""],
}
# the level the species evolves at, for "Level %d"
const LEVEL := {80: 37, 195: 20, 980: 20, 53: 28, 863: 28, 106: 20, 107: 20, 237: 20, 266: 7, 268: 7, 282: 30,
	291: 20, 292: 20, 362: 42, 413: 20, 414: 20, 563: 34, 791: 53, 792: 53}

const L = preload("res://scripts/lang.gd")


static func has(dex: int) -> bool:
	return BY_DEX.has(dex)


static func icon(dex: int) -> String:
	return "evoitem:" + String(BY_DEX[dex][0]) if BY_DEX.has(dex) else "star"


# "Fire Stone", "King's Rock (trade)", "Level 20 (Attack higher)"
static func label(dex: int) -> String:
	if not BY_DEX.has(dex):
		return ""
	var e: Array = BY_DEX[dex]
	var nm: String = L.t(String(e[1]))
	if nm.contains("%d"):
		nm = nm % int(LEVEL.get(dex, 0))
	if String(e[2]) != "":
		nm += " (" + L.t(String(e[2])) + ")"
	return nm


# ---------------------------------------------------------------- icons
const STONE := [
	"................",
	"......kkkk......",
	"....kkHHLLkk....",
	"...kHHLLLLLLk...",
	"..kHLLLLLLLLMk..",
	"..kHLLLLLLLLMk..",
	".kHLLLLLLLLLLMk.",
	".kLLLLLLLLLLLMk.",
	".kLLLLLLLLLLMMk.",
	".kLLLLLLLLLLMMk.",
	"..kLLLLLLLLMMk..",
	"..kMLLLLLLMMDk..",
	"...kMMMMMMMDk...",
	"....kkDDDDkk....",
	"......kkkk......",
	"................",
]
# 8 x 8 motifs pressed into the stone (top-left at 4, 4)
const MOTIF := {
	"fire": ["....F...", "...FF...", "..FFGF..", "..FGGF..", ".FFGGFF.", ".FGGGGF.", "..FGGF..", "...FF..."],
	"water": ["...G....", "...GG...", "..GGGG..", "..GGGGG.", ".GGGGGG.", ".GGFGGG.", "..GGGG..", "...GG..."],
	"thunder": [".....FF.", "....FF..", "...FF...", "..FFFFF.", "....FF..", "...FF...", "..FF....", ".F......"],
	"leaf": ["......F.", "....FFF.", "...FGFF.", "..FGFF..", "..GFF...", ".GFF....", ".G......", "........"],
	"ice": ["...G....", ".G.G.G..", "..GGG...", "GGGGGGG.", "..GGG...", ".G.G.G..", "...G....", "........"],
	"sun": ["...F....", ".F.F.F..", "..FGF...", "FFGGGFF.", "..FGF...", ".F.F.F..", "...F....", "........"],
	"dawn": ["........", "..G.....", ".GGG....", "..G...G.", ".....GGG", "......G.", "...G....", "........"],
	"augurite": ["........", "......G.", ".....G..", "....G...", "...G....", "........", "........", "........"],
}
const STONE_PAL := {
	"fire": {"L": "#ff7a2a", "H": "#ffc48a", "M": "#d9461a", "D": "#8a2410", "F": "#ffd23f", "G": "#fff6c8"},
	"water": {"L": "#3a8ee8", "H": "#9fd0ff", "M": "#2a62b8", "D": "#173a7a", "F": "#9fd0ff", "G": "#e8f6ff"},
	"thunder": {"L": "#6ac84a", "H": "#b8f08a", "M": "#3e9a34", "D": "#1f5a1e", "F": "#ffe23a", "G": "#fff6c8"},
	"leaf": {"L": "#c9b06a", "H": "#efe2a8", "M": "#9a7f3e", "D": "#5e4a20", "F": "#3e9a34", "G": "#7fd65a"},
	"ice": {"L": "#9fe6ff", "H": "#e8fbff", "M": "#5fb4e8", "D": "#2a6fa8", "F": "#ffffff", "G": "#ffffff"},
	"sun": {"L": "#ff6a3d", "H": "#ffb08a", "M": "#d9401f", "D": "#8a2410", "F": "#ffd23f", "G": "#fff6c8"},
	"dawn": {"L": "#3ad6c0", "H": "#a8f5e8", "M": "#1f9a8a", "D": "#0f5a52", "F": "#ffffff", "G": "#ffffff"},
	"augurite": {"L": "#3a3346", "H": "#8a7ab0", "M": "#262033", "D": "#120e1a", "F": "#c9b8ff", "G": "#c9b8ff"},
}
const ROWS := {
	"friend": {"pal": {"P": "#ff7ab0", "p": "#d9407a", "W": "#ffe0ee"}, "rows": [
		"................", "................", "..kkk....kkk....", ".kPPPk..kPPPk...", "kPWWPPkkPPPPPk..", "kPWPPPPPPPPPpk..",
		"kPPPPPPPPPPPpk..", "kPPPPPPPPPPPpk..", ".kPPPPPPPPPpk...", "..kPPPPPPPpk....", "...kPPPPPpk.....", "....kPPPpk......",
		".....kPpk.......", "......kk........", "................", "................"]},
	"friend_fairy": {"pal": {"P": "#ff7ab0", "p": "#d9407a", "W": "#ffe0ee", "Y": "#fff3a8"}, "rows": [
		"............k...", "...........kYk..", "..kkk....kkkYk..", ".kPPPk..kPPPkk..", "kPWWPPkkPPPPPk..", "kPWPPPPPPPPPpk..",
		"kPPPPPPPPPPPpk..", "kPPPPPPPPPPPpk..", ".kPPPPPPPPPpk...", "..kPPPPPPPpk....", "...kPPPPPpk.....", "....kPPPpk......",
		".....kPpk.......", "......kk........", "................", "................"]},
	"kingsrock": {"pal": {"Y": "#ffd23f", "y": "#fff3a8", "o": "#b8860b", "R": "#e0434f", "B": "#4fa8ff"}, "rows": [
		"................", "................", "..k....k....k...", ".kyk..kyk..kyk..", ".kYk.kYYYk.kYk..", ".kYYkYYYYYkYYk..",
		".kYYYYRYYYYYYk..", ".kYYYYYYYBYYYk..", ".kYyYYYYYYYYYk..", ".kooooooooooook.", ".kYYYYYYYYYYYk..", ".kooooooooooook.",
		"..kkkkkkkkkkkk..", "................", "................", "................"]},
	"metalcoat": {"pal": {"S": "#9aa3b2", "L": "#d4dae6", "W": "#ffffff", "d": "#5d6674"}, "rows": [
		"................", "...kk......kk...", "..kSSk....kSSk..", ".kSLLSkkkkSLLSk.", ".kSLWLSSSSLLSSk.", ".kSLLLSSSSSSSdk.",
		"..kSLLSSSSSSdk..", "..kSLSSSSSSSdk..", "..kSLSSSSSSSdk..", "..kSSSSSSSSSdk..", "..kSSSSSSSSddk..", "...kSSSSSSddk...",
		"....kddddddk....", ".....kkkkkk.....", "................", "................"]},
	"razorclaw": {"pal": {"W": "#ffffff", "L": "#d4dae6", "g": "#8a93a6", "R": "#e0434f"}, "rows": [
		"................", "..k.............", ".kWk....k.......", ".kWLk..kWk...k..", "..kWLk.kWLk.kWk.", "..kWLLkkWLLkkWLk",
		"...kWLLkkWLLkWLk", "...kWLLLkWLLLLk.", "....kgLLLLLLLgk.", "....kgggggggggk.", ".....kRRRRRRRk..", ".....kRRRRRRRk..",
		"......kkkkkkk...", "................", "................", "................"]},
	"deeptooth": {"pal": {"W": "#fbf7ea", "L": "#d9d2bb", "d": "#9a9278"}, "rows": [
		"................", "................", "...kkkkkkkk.....", "..kWWWWWWWLk....", "..kWWWWWWLLk....", "...kWWWWWLLk....",
		"...kWWWWWLk.....", "....kWWWLLk.....", "....kWWWLk......", ".....kWWLk......", ".....kWLdk......", "......kWdk......",
		"......kLk.......", ".......k........", "................", "................"]},
	"deepscale": {"pal": {"P": "#ff9ac8", "p": "#d9608f", "W": "#ffe8f2"}, "rows": [
		"................", ".......kk.......", "......kWWk......", ".....kWPPPk.....", "....kWPPPPPk....", "...kWPPPPPPPk...",
		"...kPPPPPPPpk...", "..kPPPpkkPPPpk..", "..kPPpk..kPPpk..", "..kPpk....kPpk..", "..kpk......kpk..", "...k........k...",
		"................", "................", "................", "................"]},
	"level": {"pal": {"G": "#5fe08a", "g": "#2f9a52", "W": "#e8ffe8"}, "rows": [
		"................", ".......kk.......", "......kGGk......", ".....kGWGGk.....", "....kGWGGGGk....", "...kGWGGGGGGk...",
		"..kGGGGGGGGGgk..", "..kkkkGGGGkkkk..", ".....kGGgk......", ".....kGGgk......", ".....kGGgk......", ".....kGGgk......",
		".....kGggk......", ".....kkkkk......", "................", "................"]},
	"pokeball": {"pal": {"R": "#e0434f", "r": "#a82a35", "W": "#f4f6fb", "g": "#c9cfdc", "H": "#ff9aa2"}, "rows": [
		"................", ".....kkkkkk.....", "...kkRRRRRRkk...", "..kRHHRRRRRRrk..", "..kRHRRRRRRRrk..", ".kRRRRRRRRRRRrk.",
		".kRRRRRkkRRRRrk.", ".kkkkkkWWkkkkkk.", ".kWWWWWkkWWWWgk.", ".kWWWWWWWWWWWgk.", "..kWWWWWWWWWgk..", "..kWWWWWWWWggk..",
		"...kkggggggkk...", ".....kkkkkk.....", "................", "................"]},
	"sunicon": {"pal": {"Y": "#ffd23f", "O": "#ff8a3d", "W": "#fff6c8"}, "rows": [
		"................", ".......kk.......", "..k....kk....k..", "...k..kkkk..k...", "......kYYk......", "....kYYYYYYk....",
		"...kYYWWYYYYk...", ".kkkYWWYYYYYkkk.", ".kkkYYYYYYYOkkk.", "...kYYYYYYOOk...", "....kYYYYOOk....", "......kOOk......",
		"...k..kkkk..k...", "..k....kk....k..", ".......kk.......", "................"]},
	"moonicon": {"pal": {"B": "#c9b8ff", "b": "#8a6ad0", "W": "#f4f0ff"}, "rows": [
		"................", "......kkkk......", "....kkBBBBk.....", "...kWBBBkk......", "..kWBBBk........", "..kBBBk.........",
		".kWBBk..........", ".kBBBk......k...", ".kBBBk.....kWk..", ".kBBBBk.....k...", "..kBBBBk.....k..", "..kbBBBBkk..kbk.",
		"...kbbBBBBkkkk..", "....kkbbbbbk....", "......kkkkk.....", "................"]},
	"tart": {"pal": {"A": "#8ad04a", "a": "#4f9a2a", "W": "#e8ffd0", "S": "#6b4a2b", "L": "#3e9a34", "R": "#e0434f"}, "rows": [
		"................", "........kk......", ".......kSk.kk...", ".......kSkkLLk..", "....kkkkSkLLk...", "...kAAAAkAAkk...",
		"..kAWWAAAAAAAk..", "..kAWAAAAAAAak..", ".kAAAAAAARAAAak.", ".kAAAAAAARRAAak.", ".kAAAAAAAAAAaak.", "..kAAAAAAAAaak..",
		"..kaAAAAAAaaak..", "...kkaaaaaakk...", ".....kkkkkk.....", "................"]},
	"sweet": {"pal": {"A": "#ffb03d", "a": "#d9701a", "W": "#fff0c8", "S": "#6b4a2b", "L": "#3e9a34", "G": "#8ad04a"}, "rows": [
		"................", "........kk......", ".......kSk.kk...", ".......kSkkLLk..", "....kkkkSkLLk...", "...kAAAAkAAkk...",
		"..kAWWAAAAAAAk..", "..kAWAAAGAAAak..", ".kAAAAAGGGAAAak.", ".kAAAAAAGAAAaak.", ".kAAAAAAAAAAaak.", "..kAAAAAAAAaak..",
		"..kaAAAAAAaaak..", "...kkaaaaaakk...", ".....kkkkkk.....", "................"]},
	"syrupy": {"pal": {"A": "#e0434f", "a": "#a82a35", "W": "#ffc0c8", "S": "#6b4a2b", "L": "#3e9a34", "Y": "#ffd23f"}, "rows": [
		"................", "........kk......", ".......kSk.kk...", ".......kSkkLLk..", "....kkkkSkLLk...", "...kYYYYkYYkk...",
		"..kAWWYYYYYYAk..", "..kAWAAYAAYAak..", ".kAAAAAYAAYAAak.", ".kAAAAAYAAAAaak.", ".kAAAAAAAAAAaak.", "..kAAAAAAAAaak..",
		"..kaAAAAAAaaak..", "...kkaaaaaakk...", ".....kkkkkk.....", "................"]},
	"auspicious": {"pal": {"Y": "#ffd23f", "y": "#fff3a8", "o": "#b8860b", "R": "#e0434f", "r": "#a82a35"}, "rows": [
		"................", "...kkk....kkk...", "..kyYYk..kYYok..", ".kyYYYYkkYYYYok.", ".kYYRRYYYYRRYok.", ".kYYRRRYYRRRYok.",
		"..kYYRRRRRRYok..", "..kYYYRRRRYYok..", "..kYyYYRRYYYok..", "..kYYYYYYYYYok..", "...kYYYooYYok...", "...kYYYYYYYok...",
		"....kooooook....", ".....kkkkkk.....", "................", "................"]},
	"malicious": {"pal": {"P": "#7a4fd0", "p": "#4a2a96", "d": "#241446", "B": "#7fd8ff", "C": "#3a8ee8"}, "rows": [
		"................", "...kkk....kkk...", "..kPPPk..kPPpk..", ".kPPPPPkkPPPPpk.", ".kPPBBPPPPBBPpk.", ".kPPCBBPPBBCPpk.",
		"..kPPCBBBBCPpk..", "..kPPPCBBCPPpk..", "..kPPPPCCPPPpk..", "..kPPPPPPPPPpk..", "...kPPPddPPpk...", "...kpPPPPPPpk...",
		"....kdddddddk...", ".....kkkkkk.....", "................", "................"]},
}


static func image_def(id: String) -> Dictionary:
	if ROWS.has(id):
		return ROWS[id]
	if not STONE_PAL.has(id):
		return {}
	var rows: Array = []
	for r in STONE:
		rows.append(String(r))
	var mo: Array = MOTIF.get(id, [])
	for y in range(mo.size()):
		var row: String = rows[4 + y]
		var mr: String = String(mo[y])
		for x in range(mr.length()):
			var ch: String = mr.substr(x, 1)
			if ch != ".":
				row = row.substr(0, 4 + x) + ch + row.substr(5 + x)
		rows[4 + y] = row
	return {"pal": STONE_PAL[id], "rows": rows}


static func all_ids() -> Array:
	var out: Array = []
	for k in BY_DEX:
		var id: String = String(BY_DEX[k][0])
		if not out.has(id):
			out.append(id)
	return out
